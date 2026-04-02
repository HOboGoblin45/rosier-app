import Foundation

/// Generic URLSession-based networking layer with JWT authentication.
final class NetworkService {
    // MARK: - Singleton

    static let shared = NetworkService()

    // MARK: - Properties

    private let session: URLSession
    private let baseURL: URL
    private weak var authService: AuthService?

    // MARK: - Initializers

    /// Initializes the network service.
    /// - Parameters:
    ///   - baseURL: Base URL for API requests
    ///   - configuration: URL session configuration
    init(
        baseURL: URL = URL(string: "https://api.rosier.app/v1")!,
        configuration: URLSessionConfiguration = .default
    ) {
        self.baseURL = baseURL
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public Methods

    /// Sets the auth service reference for token injection.
    func setAuthService(_ authService: AuthService) {
        self.authService = authService
    }

    /// Performs a generic network request with Codable response.
    /// - Parameters:
    ///   - endpoint: API endpoint path (relative to base URL)
    ///   - method: HTTP method
    ///   - body: Optional request body (will be JSON encoded)
    ///   - headers: Additional headers to include
    /// - Returns: Decoded response of type T
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        // Set default content type
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add authorization token
        if let token = try await authService?.getValidToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add custom headers
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body if provided
        if let body = body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            // Handle 401 unauthorized (token refresh)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                try await authService?.refreshToken()
                return try await request(endpoint, method: method, body: body, headers: headers)
            }

            try validateResponse(response)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as NetworkError {
            throw error
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(decodingError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    /// Performs a network request that returns no content (e.g., DELETE, POST with 204 response).
    func requestEmpty(
        _ endpoint: String,
        method: HTTPMethod = .post,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws {
        let url = baseURL.appendingPathComponent(endpoint)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        // Set default content type
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authorization token
        if let token = try await authService?.getValidToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add custom headers
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body if provided
        if let body = body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (_, response) = try await session.data(for: urlRequest)
            try validateResponse(response)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    // MARK: - Private Methods

    /// Validates the HTTP response.
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - HTTP Method Enum

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
}

// MARK: - Network Error Enum

enum NetworkError: LocalizedError {
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(Int)
    case httpError(Int)
    case decodingError(DecodingError)
    case encodingError(EncodingError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest:
            return "Bad request (400)"
        case .unauthorized:
            return "Unauthorized (401)"
        case .forbidden:
            return "Forbidden (403)"
        case .notFound:
            return "Not found (404)"
        case .rateLimited:
            return "Too many requests (429)"
        case .serverError(let code):
            return "Server error (\(code))"
        case .httpError(let code):
            return "HTTP error (\(code))"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .unknown:
            return "Unknown error"
        }
    }
}
