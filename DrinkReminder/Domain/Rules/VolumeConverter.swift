import Foundation

enum VolumeConverter {
    static let millilitersPerUSFluidOunce = 29.5735295625

    static func milliliters(from value: Double, unit: VolumeUnit) -> Double {
        switch unit {
        case .milliliters:
            return value
        case .ounces:
            return value * millilitersPerUSFluidOunce
        }
    }

    static func displayValue(fromMilliliters value: Double, unit: VolumeUnit) -> Double {
        switch unit {
        case .milliliters:
            return value
        case .ounces:
            return value / millilitersPerUSFluidOunce
        }
    }
}
