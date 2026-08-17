import Foundation

enum VolumeDisplayFormatter {
    static func string(
        milliliters: Double,
        unit: VolumeUnit,
        includesUnit: Bool = true
    ) -> String {
        let value = VolumeConverter.displayValue(fromMilliliters: milliliters, unit: unit)
        let roundedValue = value.rounded()
        let number: String

        if abs(value - roundedValue) < 0.05 {
            number = roundedValue.formatted(.number.precision(.fractionLength(0)))
        } else {
            number = value.formatted(.number.precision(.fractionLength(1)))
        }

        return includesUnit ? "\(number) \(unit.symbol)" : number
    }
}
