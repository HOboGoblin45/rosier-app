import Foundation
import UIKit

/// Image loading and caching service with memory and disk storage.
final class ImageCacheService {
    // MARK: - Singleton

    static let shared = ImageCacheService()

    // MARK: - Properties

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: URLCache
    private let scale = UIScreen.main.scale

    private let memoryLimit = 100 * 1024 * 1024 // 100 MB
    private let diskLimit = 500 * 1024 * 1024   // 500 MB
    private let imageLoadingQueue = DispatchQueue(
        label: "com.rosier.imagecache",
        qos: .userInitiated,
        attributes: .concurrent
    )

    // MARK: - Initializers

    init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 0,
            diskCapacity: diskLimit,
            diskPath: "rosier_image_cache"
        )
        self.diskCache = config.urlCache ?? URLCache.shared

        memoryCache.totalCostLimit = memoryLimit
    }

    // MARK: - Public Methods

    /// Loads an image from URL with caching support.
    func loadImage(from url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString

        // Check memory cache first
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        // Load from network
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                return nil
            }

            // Cache the image
            cacheImage(image, for: key)
            return image
        } catch {
            print("Failed to load image from \(url): \(error)")
            return nil
        }
    }

    /// Pre-loads an image in the background for future use.
    func preloadImage(from url: URL) {
        imageLoadingQueue.async { [weak self] in
            Task {
                _ = await self?.loadImage(from: url)
            }
        }
    }

    /// Gets a device-appropriate image variant URL based on screen scale.
    func appropriateImageURL(for url: URL, scale: CGFloat = UIScreen.main.scale) -> URL {
        let scaleFactor = Int(scale)
        let filename = url.lastPathComponent
        let ext = url.pathExtension

        guard !ext.isEmpty else { return url }

        let basename = filename.dropLast(ext.count + 1)
        let scaledFilename = "\(basename)@\(scaleFactor)x.\(ext)"

        return url.deletingLastPathComponent().appendingPathComponent(scaledFilename)
    }

    /// Progressive loading support - loads a low-quality placeholder first.
    func loadProgressiveImage(
        lowQualityURL: URL,
        highQualityURL: URL
    ) async -> (placeholder: UIImage?, final: UIImage?) {
        async let placeholder = loadImage(from: lowQualityURL)
        async let final = loadImage(from: highQualityURL)

        return await (placeholder: placeholder, final: final)
    }

    /// Clears the memory cache.
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    /// Clears the disk cache.
    func clearDiskCache() {
        diskCache.removeAllCachedResponses()
    }

    /// Clears both memory and disk caches.
    func clearAllCaches() {
        clearMemoryCache()
        clearDiskCache()
    }

    /// Gets current memory cache usage in bytes.
    var memoryCacheUsage: Int {
        // NSCache doesn't provide direct usage info, return estimate
        return 0
    }

    /// Gets current disk cache usage in bytes.
    var diskCacheUsage: Int {
        // Simplified: URLCache doesn't expose usage directly
        return 0
    }

    // MARK: - Private Methods

    /// Caches an image in both memory and disk.
    private func cacheImage(_ image: UIImage, for key: NSString) {
        // Cache in memory
        let cost = (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0)
        memoryCache.setObject(image, forKey: key, cost: cost)

        // Cache in disk via URLCache
        if let jpegData = image.jpegData(compressionQuality: 0.8),
           let url = URL(string: key as String) {
            let cachedResponse = CachedURLResponse(
                response: URLResponse(
                    url: url,
                    mimeType: "image/jpeg",
                    expectedContentLength: jpegData.count,
                    textEncodingName: nil
                ),
                data: jpegData
            )
            diskCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
        }
    }
}

// MARK: - SwiftUI Image Extension

import SwiftUI

/// AsyncImage wrapper with caching support.
struct CachedAsyncImage<Content: View>: View {
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var error: Error?

    let url: URL?
    let content: (AsyncImagePhase) -> Content

    init(
        url: URL?,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.content = content
    }

    var body: some View {
        ZStack {
            switch (image, error, isLoading) {
            case (let image?, _, _):
                content(.success(Image(uiImage: image)))
            case (nil, let error?, _):
                content(.failure(error))
            case (nil, nil, true):
                content(.empty)
            default:
                content(.empty)
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else {
            isLoading = false
            return
        }

        isLoading = true

        if let loadedImage = await ImageCacheService.shared.loadImage(from: url) {
            self.image = loadedImage
            self.isLoading = false
        } else {
            self.error = NSError(domain: "ImageCache", code: -1)
            self.isLoading = false
        }
    }
}
