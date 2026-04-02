// WallpaperPatterns.swift
// Rosier Design System - Wallpaper Pattern Configuration
//
// This file defines the four luxury wallpaper houses and their curated patterns
// that are revealed beneath swiped product cards. Each pattern includes color
// definitions optimized for both light and dark mode, archetype mappings,
// and rendering specifications.
//
// Design Philosophy: Patterns render at 5-8% opacity as subtle background
// textures that enhance the luxury reveal mechanic without overwhelming
// the interface. Patterns are associated with Rosier user archetypes.

import UIKit

// MARK: - Wallpaper House Enum

/// Represents the four luxury wallpaper houses curated for Rosier
public enum WallpaperHouse: String, CaseIterable {
    /// de Gournay - Hand-painted chinoiserie, scenic murals
    case deGournay = "de_gournay"

    /// Phillip Jeffries - Natural textural wallcoverings, grasscloth, raffia
    case phillipJeffries = "phillip_jeffries"

    /// Schumacher - Historic prints, bold maximalist patterns
    case schumacher = "schumacher"

    /// Scalamandré - Iconic zoological prints, animal silhouettes
    case scalamandre = "scalamandre"

    /// Human-readable name for UI display
    var displayName: String {
        switch self {
        case .deGournay:
            return "de Gournay"
        case .phillipJeffries:
            return "Phillip Jeffries"
        case .schumacher:
            return "Schumacher"
        case .scalamandre:
            return "Scalamandré"
        }
    }

    /// Brief description of the wallpaper house aesthetic
    var description: String {
        switch self {
        case .deGournay:
            return "Hand-painted chinoiserie with scenic gardens and birds"
        case .phillipJeffries:
            return "Artisanal natural fiber textures - grasscloth and raffia"
        case .schumacher:
            return "Bold, exuberant botanical and floral prints"
        case .scalamandre:
            return "Iconic zoological patterns with animal silhouettes"
        }
    }
}

// MARK: - Wallpaper Pattern Enum

/// All 16 curated wallpaper patterns across four houses
public enum WallpaperPattern: String, CaseIterable {
    // de Gournay - Classical Elegance & Chinoiserie
    case earlham = "earlham"
    case portobello = "portobello"
    case chatsworth = "chatsworth"
    case stLaurent = "st_laurent"

    // Phillip Jeffries - Artisanal Naturalism
    case heritageHemp = "heritage_hemp"
    case gracefulGrass = "graceful_grass"
    case refinedRaffia = "refined_raffia"
    case naturalJute = "natural_jute"

    // Schumacher - Exuberant Maximalism
    case chiangMaiDragon = "chiang_mai_dragon"
    case citrusGarden = "citrus_garden"
    case josefFrankBotanical = "josef_frank_botanical"
    case grandFloralHeritage = "grand_floral_heritage"

    // Scalamandré - Zoological Drama
    case iconicZebras = "iconic_zebras"
    case leapingCheetah = "leaping_cheetah"
    case tigre = "tigre"
    case tigressTigerEye = "tigress_tiger_eye"

    /// The wallpaper house this pattern belongs to
    var house: WallpaperHouse {
        switch self {
        case .earlham, .portobello, .chatsworth, .stLaurent:
            return .deGournay
        case .heritageHemp, .gracefulGrass, .refinedRaffia, .naturalJute:
            return .phillipJeffries
        case .chiangMaiDragon, .citrusGarden, .josefFrankBotanical, .grandFloralHeritage:
            return .schumacher
        case .iconicZebras, .leapingCheetah, .tigre, .tigressTigerEye:
            return .scalamandre
        }
    }

    /// Human-readable pattern name
    var displayName: String {
        switch self {
        case .earlham: return "Earlham"
        case .portobello: return "Portobello"
        case .chatsworth: return "Chatsworth"
        case .stLaurent: return "St. Laurent"
        case .heritageHemp: return "Heritage Hemp"
        case .gracefulGrass: return "Graceful Grass"
        case .refinedRaffia: return "Refined Raffia"
        case .naturalJute: return "Natural Jute"
        case .chiangMaiDragon: return "Chiang Mai Dragon"
        case .citrusGarden: return "Citrus Garden"
        case .josefFrankBotanical: return "Josef Frank Botanical"
        case .grandFloralHeritage: return "Grand Floral Heritage"
        case .iconicZebras: return "The Iconic Zebras"
        case .leapingCheetah: return "Leaping Cheetah"
        case .tigre: return "Tigre"
        case .tigressTigerEye: return "Tigress Tiger Eye"
        }
    }

    /// Pattern type for designer reference
    var patternType: String {
        switch self {
        case .earlham: return "Scenic with ornithological detail"
        case .portobello: return "Botanical with scenic composition"
        case .chatsworth: return "Scenic landscape with architecture"
        case .stLaurent: return "Abstract botanical"
        case .heritageHemp: return "Textural, woven fiber"
        case .gracefulGrass: return "Textural, linear fiber"
        case .refinedRaffia: return "Textural, woven fiber"
        case .naturalJute: return "Textural, woven fiber"
        case .chiangMaiDragon: return "Botanical with zoological element"
        case .citrusGarden: return "Botanical"
        case .josefFrankBotanical: return "Botanical, maximalist"
        case .grandFloralHeritage: return "Floral"
        case .iconicZebras: return "Zoological"
        case .leapingCheetah: return "Zoological"
        case .tigre: return "Abstract zoological, woven texture"
        case .tigressTigerEye: return "Abstract zoological, symbolic"
        }
    }
}

// MARK: - Style Archetype Enum

/// Rosier user style archetypes that map to wallpaper patterns
public enum StyleArchetype: String, CaseIterable {
    /// Users who appreciate timeless sophistication and heritage craftsmanship
    case classicRefined = "classic_refined"

    /// Users who celebrate color, pattern layering, and artistic expression
    case eclecticCreative = "eclectic_creative"

    /// Users who favor understated elegance and organic materials
    case minimalistModern = "minimalist_modern"

    /// Users who make fearless design statements and embrace bold patterns
    case boldAvantGarde = "bold_avant_garde"

    /// Users who seek refuge in texture-driven, natural design
    case relaxedNatural = "relaxed_natural"

    var displayName: String {
        switch self {
        case .classicRefined: return "Classic Refined"
        case .eclecticCreative: return "Eclectic Creative"
        case .minimalistModern: return "Minimalist Modern"
        case .boldAvantGarde: return "Bold Avant-Garde"
        case .relaxedNatural: return "Relaxed Natural"
        }
    }
}

// MARK: - Color Configuration

/// Lightweight color container for light/dark mode support
public struct ColorPair {
    let light: UIColor
    let dark: UIColor

    /// Get appropriate color for current trait environment
    func color(for traitCollection: UITraitCollection) -> UIColor {
        if #available(iOS 13.0, *) {
            return traitCollection.userInterfaceStyle == .dark ? dark : light
        }
        return light
    }

    /// Get appropriate color for current app theme
    func color(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? dark : light
    }
}

// MARK: - Wallpaper Configuration Structure

/// Complete configuration for a wallpaper pattern including colors,
/// rendering hints, and archetype association
public struct WallpaperConfig {
    /// Pattern identifier
    let pattern: WallpaperPattern

    /// Wallpaper house
    let house: WallpaperHouse

    /// Human-readable pattern name
    let patternName: String

    /// SVG asset filename (without extension)
    let assetName: String

    /// Primary color palette (light/dark mode)
    let primaryColor: ColorPair

    /// Secondary color palette (light/dark mode)
    let secondaryColor: ColorPair

    /// Optional tertiary accent color
    let tertiaryColor: ColorPair?

    /// Optional accent color for special details
    let accentColor: ColorPair?

    /// Recommended opacity for background rendering (0.05-0.08)
    let baseOpacity: CGFloat

    /// Scale factor for pattern rendering (0.8-1.5 recommended)
    let scaleFactor: CGFloat

    /// Associated style archetype
    let archetypeAssociation: StyleArchetype

    /// Mood/aesthetic keywords for UI display
    let moodKeywords: [String]

    /// Pattern type for designer reference
    let patternType: String

    /// Blending mode for pattern rendering
    let blendingMode: CGBlendMode
}

// MARK: - Wallpaper Configuration Factory

/// Factory for creating wallpaper configurations with validated color palettes
public class WallpaperConfigFactory {

    // MARK: - de Gournay Configurations

    static func earlham() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .earlham,
            house: .deGournay,
            patternName: "Earlham",
            assetName: "earlham",
            primaryColor: ColorPair(
                light: UIColor(hex: "#1B3B4D"),
                dark: UIColor(hex: "#0F1F2E")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#D4AF37"),
                dark: UIColor(hex: "#F4D89F")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#E8D4B8"),
                dark: UIColor(hex: "#3A4C56")
            ),
            accentColor: nil,
            baseOpacity: 0.07,
            scaleFactor: 1.2,
            archetypeAssociation: .classicRefined,
            moodKeywords: ["Meditative", "Heritage", "Intricate", "Ethereal", "Timeless"],
            patternType: "Scenic with ornithological detail",
            blendingMode: .screen
        )
    }

    static func portobello() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .portobello,
            house: .deGournay,
            patternName: "Portobello",
            assetName: "portobello",
            primaryColor: ColorPair(
                light: UIColor(hex: "#4A7C8C"),
                dark: UIColor(hex: "#2C4D57")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#C9A961"),
                dark: UIColor(hex: "#E5C494")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#F5F1E8"),
                dark: UIColor(hex: "#5A7C88")
            ),
            accentColor: nil,
            baseOpacity: 0.07,
            scaleFactor: 1.15,
            archetypeAssociation: .classicRefined,
            moodKeywords: ["Romantic", "Whimsical", "Garden", "Nostalgic", "Refined"],
            patternType: "Botanical with scenic composition",
            blendingMode: .screen
        )
    }

    static func chatsworth() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .chatsworth,
            house: .deGournay,
            patternName: "Chatsworth",
            assetName: "chatsworth",
            primaryColor: ColorPair(
                light: UIColor(hex: "#2C5F7C"),
                dark: UIColor(hex: "#1A3A4D")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#D9A649"),
                dark: UIColor(hex: "#E8C494")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#F9F6F0"),
                dark: UIColor(hex: "#5A7A8C")
            ),
            accentColor: nil,
            baseOpacity: 0.075,
            scaleFactor: 1.0,
            archetypeAssociation: .classicRefined,
            moodKeywords: ["Majestic", "Escapist", "Architectural", "Exotic", "Opulent"],
            patternType: "Scenic landscape with architecture",
            blendingMode: .screen
        )
    }

    static func stLaurent() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .stLaurent,
            house: .deGournay,
            patternName: "St. Laurent",
            assetName: "st_laurent",
            primaryColor: ColorPair(
                light: UIColor(hex: "#3D6A7D"),
                dark: UIColor(hex: "#25404F")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#B8956A"),
                dark: UIColor(hex: "#D4B896")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#F7F3EE"),
                dark: UIColor(hex: "#6A8A9D")
            ),
            accentColor: nil,
            baseOpacity: 0.065,
            scaleFactor: 1.1,
            archetypeAssociation: .classicRefined,
            moodKeywords: ["Contemporary", "Understated", "Sophisticated", "Flowing", "Poetic"],
            patternType: "Abstract botanical",
            blendingMode: .screen
        )
    }

    // MARK: - Phillip Jeffries Configurations

    static func heritageHemp() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .heritageHemp,
            house: .phillipJeffries,
            patternName: "Heritage Hemp",
            assetName: "heritage_hemp",
            primaryColor: ColorPair(
                light: UIColor(hex: "#D4C5B9"),
                dark: UIColor(hex: "#8B7E6F")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#E8DCC8"),
                dark: UIColor(hex: "#A89680")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#C2B0A0"),
                dark: UIColor(hex: "#5E564C")
            ),
            accentColor: nil,
            baseOpacity: 0.06,
            scaleFactor: 1.3,
            archetypeAssociation: .minimalistModern,
            moodKeywords: ["Artisanal", "Organic", "Honest", "Grounded", "Naturalist"],
            patternType: "Textural, woven fiber",
            blendingMode: .screen
        )
    }

    static func gracefulGrass() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .gracefulGrass,
            house: .phillipJeffries,
            patternName: "Graceful Grass",
            assetName: "graceful_grass",
            primaryColor: ColorPair(
                light: UIColor(hex: "#D9CFC7"),
                dark: UIColor(hex: "#7A7366")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#E5D9CB"),
                dark: UIColor(hex: "#9D938B")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#C7B8A8"),
                dark: UIColor(hex: "#5A5047")
            ),
            accentColor: nil,
            baseOpacity: 0.055,
            scaleFactor: 1.25,
            archetypeAssociation: .relaxedNatural,
            moodKeywords: ["Serene", "Organic", "Calming", "Restrained", "Meditative"],
            patternType: "Textural, linear fiber",
            blendingMode: .screen
        )
    }

    static func refinedRaffia() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .refinedRaffia,
            house: .phillipJeffries,
            patternName: "Refined Raffia",
            assetName: "refined_raffia",
            primaryColor: ColorPair(
                light: UIColor(hex: "#D8C8B8"),
                dark: UIColor(hex: "#9B8B7B")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#E8DCC8"),
                dark: UIColor(hex: "#A89680")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#BFA892"),
                dark: UIColor(hex: "#6B5F52")
            ),
            accentColor: nil,
            baseOpacity: 0.065,
            scaleFactor: 1.2,
            archetypeAssociation: .minimalistModern,
            moodKeywords: ["Sophisticated", "Handcrafted", "Warm", "Inviting", "Luxe-minimal"],
            patternType: "Textural, woven fiber",
            blendingMode: .screen
        )
    }

    static func naturalJute() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .naturalJute,
            house: .phillipJeffries,
            patternName: "Natural Jute",
            assetName: "natural_jute",
            primaryColor: ColorPair(
                light: UIColor(hex: "#C9BAA8"),
                dark: UIColor(hex: "#8B7D70")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#DDD4C8"),
                dark: UIColor(hex: "#A0957F")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#B8A896"),
                dark: UIColor(hex: "#5F564A")
            ),
            accentColor: nil,
            baseOpacity: 0.06,
            scaleFactor: 1.15,
            archetypeAssociation: .relaxedNatural,
            moodKeywords: ["Durable", "Honest", "Elemental", "Understated", "Grounded"],
            patternType: "Textural, woven fiber",
            blendingMode: .screen
        )
    }

    // MARK: - Schumacher Configurations

    static func chiangMaiDragon() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .chiangMaiDragon,
            house: .schumacher,
            patternName: "Chiang Mai Dragon",
            assetName: "chiang_mai_dragon",
            primaryColor: ColorPair(
                light: UIColor(hex: "#2A5C7C"),
                dark: UIColor(hex: "#1A3C5C")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#E8B23D"),
                dark: UIColor(hex: "#F0C860")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#F0E8D8"),
                dark: UIColor(hex: "#5A7A8C")
            ),
            accentColor: ColorPair(
                light: UIColor(hex: "#4A3C2A"),
                dark: UIColor(hex: "#D4C494")
            ),
            baseOpacity: 0.08,
            scaleFactor: 0.9,
            archetypeAssociation: .eclecticCreative,
            moodKeywords: ["Exuberant", "Artistic", "Theatrical", "Bold", "Heritage-inspired"],
            patternType: "Botanical with zoological element",
            blendingMode: .screen
        )
    }

    static func citrusGarden() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .citrusGarden,
            house: .schumacher,
            patternName: "Citrus Garden",
            assetName: "citrus_garden",
            primaryColor: ColorPair(
                light: UIColor(hex: "#3D6B4C"),
                dark: UIColor(hex: "#2A4A38")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#F5A623"),
                dark: UIColor(hex: "#F5C66D")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#FDD835"),
                dark: UIColor(hex: "#FFEB3B")
            ),
            accentColor: ColorPair(
                light: UIColor(hex: "#FFF8DC"),
                dark: UIColor(hex: "#7A8C6B")
            ),
            baseOpacity: 0.075,
            scaleFactor: 0.95,
            archetypeAssociation: .eclecticCreative,
            moodKeywords: ["Vibrant", "Lush", "Joyful", "Mediterranean", "Artistic"],
            patternType: "Botanical",
            blendingMode: .screen
        )
    }

    static func josefFrankBotanical() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .josefFrankBotanical,
            house: .schumacher,
            patternName: "Josef Frank Botanical",
            assetName: "josef_frank_botanical",
            primaryColor: ColorPair(
                light: UIColor(hex: "#4A6F5C"),
                dark: UIColor(hex: "#2A4A3C")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#D94C4C"),
                dark: UIColor(hex: "#E87070")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#E8B23D"),
                dark: UIColor(hex: "#F0C860")
            ),
            accentColor: ColorPair(
                light: UIColor(hex: "#F5E6D3"),
                dark: UIColor(hex: "#7A8C7B")
            ),
            baseOpacity: 0.08,
            scaleFactor: 0.85,
            archetypeAssociation: .eclecticCreative,
            moodKeywords: ["Playful", "Artistic", "Lush", "Eclectic", "Imaginative"],
            patternType: "Botanical, maximalist",
            blendingMode: .screen
        )
    }

    static func grandFloralHeritage() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .grandFloralHeritage,
            house: .schumacher,
            patternName: "Grand Floral Heritage",
            assetName: "grand_floral_heritage",
            primaryColor: ColorPair(
                light: UIColor(hex: "#6B2C4C"),
                dark: UIColor(hex: "#4A1C3C")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#E8B8C8"),
                dark: UIColor(hex: "#F0D4D8")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#FFF8F0"),
                dark: UIColor(hex: "#8A9C8B")
            ),
            accentColor: ColorPair(
                light: UIColor(hex: "#4A7C3C"),
                dark: UIColor(hex: "#C8D894")
            ),
            baseOpacity: 0.075,
            scaleFactor: 1.0,
            archetypeAssociation: .eclecticCreative,
            moodKeywords: ["Romantic", "Heritage", "Bold", "Sophisticated", "Timeless"],
            patternType: "Floral",
            blendingMode: .screen
        )
    }

    // MARK: - Scalamandré Configurations

    static func iconicZebras() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .iconicZebras,
            house: .scalamandre,
            patternName: "The Iconic Zebras",
            assetName: "iconic_zebras",
            primaryColor: ColorPair(
                light: UIColor(hex: "#1A1A1A"),
                dark: UIColor(hex: "#F5F5F0")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#F5F5F0"),
                dark: UIColor(hex: "#2A2A2A")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#4A7C3C"),
                dark: UIColor(hex: "#7AA85A")
            ),
            accentColor: ColorPair(
                light: UIColor(hex: "#D4AF37"),
                dark: UIColor(hex: "#F0C860")
            ),
            baseOpacity: 0.07,
            scaleFactor: 1.0,
            archetypeAssociation: .boldAvantGarde,
            moodKeywords: ["Iconic", "Bold", "Historic", "Energetic", "Luxurious"],
            patternType: "Zoological",
            blendingMode: .screen
        )
    }

    static func leapingCheetah() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .leapingCheetah,
            house: .scalamandre,
            patternName: "Leaping Cheetah",
            assetName: "leaping_cheetah",
            primaryColor: ColorPair(
                light: UIColor(hex: "#3D5C4C"),
                dark: UIColor(hex: "#2A3C2C")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#F5E8D4"),
                dark: UIColor(hex: "#E8D4B8")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#D4A459"),
                dark: UIColor(hex: "#F0C494")
            ),
            accentColor: ColorPair(
                light: UIColor(hex: "#8B4513"),
                dark: UIColor(hex: "#C9956A")
            ),
            baseOpacity: 0.07,
            scaleFactor: 1.05,
            archetypeAssociation: .boldAvantGarde,
            moodKeywords: ["Playful", "Athletic", "Dynamic", "Sophisticated", "Joyful"],
            patternType: "Zoological",
            blendingMode: .screen
        )
    }

    static func tigre() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .tigre,
            house: .scalamandre,
            patternName: "Tigre",
            assetName: "tigre",
            primaryColor: ColorPair(
                light: UIColor(hex: "#8B6F47"),
                dark: UIColor(hex: "#5A4A3C")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#D4B896"),
                dark: UIColor(hex: "#C8A882")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#5A4C3C"),
                dark: UIColor(hex: "#3A3A3A")
            ),
            accentColor: ColorPair(
                light: UIColor(hex: "#2A2A2A"),
                dark: UIColor(hex: "#F5E8D4")
            ),
            baseOpacity: 0.065,
            scaleFactor: 1.1,
            archetypeAssociation: .boldAvantGarde,
            moodKeywords: ["Opulent", "Sophisticated", "Abstract", "Majestic", "Timeless"],
            patternType: "Abstract zoological, woven texture",
            blendingMode: .screen
        )
    }

    static func tigressTigerEye() -> WallpaperConfig {
        return WallpaperConfig(
            pattern: .tigressTigerEye,
            house: .scalamandre,
            patternName: "Tigress Tiger Eye",
            assetName: "tigress_tiger_eye",
            primaryColor: ColorPair(
                light: UIColor(hex: "#6B5C4C"),
                dark: UIColor(hex: "#4A3C2C")
            ),
            secondaryColor: ColorPair(
                light: UIColor(hex: "#E8D4B8"),
                dark: UIColor(hex: "#D4B896")
            ),
            tertiaryColor: ColorPair(
                light: UIColor(hex: "#4A3C2C"),
                dark: UIColor(hex: "#2A2A2A")
            ),
            accentColor: ColorPair(
                light: UIColor(hex: "#8B7A3C"),
                dark: UIColor(hex: "#F0D89F")
            ),
            baseOpacity: 0.07,
            scaleFactor: 0.95,
            archetypeAssociation: .boldAvantGarde,
            moodKeywords: ["Mysterious", "Symbolic", "Bold", "Predatory", "Luxe"],
            patternType: "Abstract zoological, symbolic",
            blendingMode: .screen
        )
    }

    // MARK: - Configuration Lookup

    /// Get configuration for a specific pattern
    static func config(for pattern: WallpaperPattern) -> WallpaperConfig {
        switch pattern {
        case .earlham: return earlham()
        case .portobello: return portobello()
        case .chatsworth: return chatsworth()
        case .stLaurent: return stLaurent()
        case .heritageHemp: return heritageHemp()
        case .gracefulGrass: return gracefulGrass()
        case .refinedRaffia: return refinedRaffia()
        case .naturalJute: return naturalJute()
        case .chiangMaiDragon: return chiangMaiDragon()
        case .citrusGarden: return citrusGarden()
        case .josefFrankBotanical: return josefFrankBotanical()
        case .grandFloralHeritage: return grandFloralHeritage()
        case .iconicZebras: return iconicZebras()
        case .leapingCheetah: return leapingCheetah()
        case .tigre: return tigre()
        case .tigressTigerEye: return tigressTigerEye()
        }
    }

    /// Get all configurations for a specific house
    static func configs(for house: WallpaperHouse) -> [WallpaperConfig] {
        return WallpaperPattern.allCases
            .filter { $0.house == house }
            .map { config(for: $0) }
    }
}

// MARK: - Archetype Pattern Mapping

/// Maps user style archetypes to their recommended wallpaper patterns
public class ArchetypePatternMapper {

    /// Get primary pattern recommendations for an archetype
    static func primaryPatterns(for archetype: StyleArchetype) -> [WallpaperPattern] {
        switch archetype {
        case .classicRefined:
            // de Gournay patterns
            return [.earlham, .portobello, .chatsworth, .stLaurent]

        case .eclecticCreative:
            // Schumacher bold prints
            return [.chiangMaiDragon, .citrusGarden, .josefFrankBotanical, .grandFloralHeritage]

        case .minimalistModern:
            // Phillip Jeffries textures
            return [.heritageHemp, .refinedRaffia, .gracefulGrass, .naturalJute]

        case .boldAvantGarde:
            // Scalamandré zoological
            return [.iconicZebras, .leapingCheetah, .tigre, .tigressTigerEye]

        case .relaxedNatural:
            // Phillip Jeffries natural fibers
            return [.gracefulGrass, .naturalJute, .refinedRaffia, .heritageHemp]
        }
    }

    /// Get a single recommended pattern for an archetype
    static func recommendedPattern(for archetype: StyleArchetype) -> WallpaperPattern {
        let patterns = primaryPatterns(for: archetype)
        // Return first pattern as primary recommendation
        return patterns.first ?? .earlham
    }

    /// Get wallpaper configuration for an archetype
    static func recommendedConfig(for archetype: StyleArchetype) -> WallpaperConfig {
        let pattern = recommendedPattern(for: archetype)
        return WallpaperConfigFactory.config(for: pattern)
    }
}

// MARK: - UIColor Extension for Hex Support

extension UIColor {
    /// Initialize UIColor from hex string
    /// - Parameter hex: Hex color string (e.g., "#1B3B4D" or "1B3B4D")
    convenience init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hexString)
        var rgbValue: UInt64 = 0

        scanner.scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
