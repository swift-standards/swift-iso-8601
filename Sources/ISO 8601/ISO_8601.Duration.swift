//
//  ISO_8601.Duration.swift
//  swift-iso-8601
//
//  ISO 8601 Duration representation (P format)
//

extension ISO_8601 {
    /// ISO 8601 Duration representation
    ///
    /// Represents a duration of time using the P format: `P[n]Y[n]M[n]DT[n]H[n]M[n]S`
    ///
    /// ## Format
    /// - `P` prefix indicates period/duration
    /// - `T` separates date components from time components
    /// - Components can be omitted if zero
    ///
    /// ## Examples
    /// - `P3Y6M4DT12H30M5S` - 3 years, 6 months, 4 days, 12 hours, 30 minutes, 5 seconds
    /// - `P1Y` - 1 year
    /// - `PT5M` - 5 minutes
    /// - `P3D` - 3 days
    /// - `PT0.5S` - half a second
    ///
    /// ```swift
    /// let duration = try ISO_8601.Duration(years: 1, months: 6, days: 15)
    /// let formatted = duration.description  // "P1Y6M15D"
    /// let parsed = try ISO_8601.Duration.parse("PT2H30M")
    /// ```
    public struct Duration: Sendable, Equatable, Hashable {
        /// Years component
        public let years: Int

        /// Months component (note: month length varies)
        public let months: Int

        /// Days component (note: day length can vary with DST)
        public let days: Int

        /// Hours component
        public let hours: Int

        /// Minutes component
        public let minutes: Int

        /// Seconds component (integer part)
        public let seconds: Int

        /// Nanoseconds component (fractional seconds)
        public let nanoseconds: Int

        /// Create a duration with specified components
        ///
        /// - Parameters:
        ///   - years: Number of years (default: 0)
        ///   - months: Number of months (default: 0)
        ///   - days: Number of days (default: 0)
        ///   - hours: Number of hours (default: 0)
        ///   - minutes: Number of minutes (default: 0)
        ///   - seconds: Number of seconds (default: 0)
        ///   - nanoseconds: Number of nanoseconds (default: 0, range: 0-999999999)
        /// - Throws: `ISO_8601.Date.Error` if nanoseconds is out of range
        public init(
            years: Int = 0,
            months: Int = 0,
            days: Int = 0,
            hours: Int = 0,
            minutes: Int = 0,
            seconds: Int = 0,
            nanoseconds: Int = 0
        ) throws {
            guard (0..<1_000_000_000).contains(nanoseconds) else {
                throw ISO_8601.Date.Error.invalidFractionalSecond(String(nanoseconds))
            }

            self.years = years
            self.months = months
            self.days = days
            self.hours = hours
            self.minutes = minutes
            self.seconds = seconds
            self.nanoseconds = nanoseconds
        }

        /// Check if this duration represents zero time
        public var isZero: Bool {
            years == 0 && months == 0 && days == 0 && hours == 0 && minutes == 0 && seconds == 0
                && nanoseconds == 0
        }
    }
}

// MARK: - Formatting

extension ISO_8601.Duration: CustomStringConvertible {
    public var description: String {
        Formatter.format(self)
    }
}

extension ISO_8601.Duration {
    /// Formatter for ISO 8601 duration strings
    public enum Formatter {
        /// Format a duration as an ISO 8601 P-format string
        ///
        /// - Parameter value: The duration to format
        /// - Returns: ISO 8601 duration string (e.g., "P1Y2M3DT4H5M6.789S")
        public static func format(_ value: ISO_8601.Duration) -> String {
            // Handle zero duration
            if value.isZero {
                return "PT0S"
            }

            var result = "P"

            // Date components
            if value.years != 0 {
                result += "\(value.years)Y"
            }
            if value.months != 0 {
                result += "\(value.months)M"
            }
            if value.days != 0 {
                result += "\(value.days)D"
            }

            // Time components
            let hasTimeComponents =
                value.hours != 0 || value.minutes != 0 || value.seconds != 0
                || value.nanoseconds != 0

            if hasTimeComponents {
                result += "T"

                if value.hours != 0 {
                    result += "\(value.hours)H"
                }
                if value.minutes != 0 {
                    result += "\(value.minutes)M"
                }
                if value.seconds != 0 || value.nanoseconds != 0 {
                    if value.nanoseconds == 0 {
                        result += "\(value.seconds)S"
                    } else {
                        // Format fractional seconds
                        let fractional = formatFractionalSeconds(
                            seconds: value.seconds,
                            nanoseconds: value.nanoseconds
                        )
                        result += "\(fractional)S"
                    }
                }
            }

            return result
        }

        private static func formatFractionalSeconds(seconds: Int, nanoseconds: Int) -> String {
            // Remove trailing zeros from nanoseconds
            var nano = nanoseconds
            var divisor = 1
            while nano > 0 && nano % 10 == 0 {
                nano /= 10
                divisor *= 10
            }

            if nano == 0 {
                return "\(seconds)"
            }

            return "\(seconds).\(nano)"
        }
    }
}

// MARK: - Parsing

extension ISO_8601.Duration {
    /// Parser for ISO 8601 duration strings
    public enum Parser {
        /// Parse an ISO 8601 duration string
        ///
        /// - Parameter value: The P-format duration string (e.g., "P1Y2M3DT4H5M6.789S")
        /// - Returns: Duration instance
        /// - Throws: `ISO_8601.Date.Error` if parsing fails
        public static func parse(_ value: String) throws -> ISO_8601.Duration {
            guard value.hasPrefix("P") else {
                throw ISO_8601.Date.Error.invalidFormat("Duration must start with 'P'")
            }

            let remaining = String(value.dropFirst())

            guard !remaining.isEmpty else {
                throw ISO_8601.Date.Error.invalidFormat("Duration cannot be just 'P'")
            }

            // Validate that remaining contains at least one valid component marker
            let validMarkers: Set<Character> = ["Y", "M", "D", "T", "H", "S"]
            guard remaining.contains(where: { validMarkers.contains($0) }) else {
                throw ISO_8601.Date.Error.invalidFormat(
                    "Duration must have at least one valid component"
                )
            }

            var years = 0
            var months = 0
            var days = 0
            var hours = 0
            var minutes = 0
            var seconds = 0
            var nanoseconds = 0

            // Check for T separator
            if let tIndex = remaining.firstIndex(of: "T") {
                // Has both date and time parts
                let datePart = String(remaining[..<tIndex])
                let timePart = String(remaining[remaining.index(after: tIndex)...])

                // Parse date part if not empty
                if !datePart.isEmpty {
                    (years, months, days) = try parseDateComponents(datePart)
                }

                // Parse time part if not empty
                if !timePart.isEmpty {
                    (hours, minutes, seconds, nanoseconds) = try parseTimeComponents(timePart)
                }
            } else {
                // No T, only date components
                (years, months, days) = try parseDateComponents(remaining)
            }

            return try ISO_8601.Duration(
                years: years,
                months: months,
                days: days,
                hours: hours,
                minutes: minutes,
                seconds: seconds,
                nanoseconds: nanoseconds
            )
        }

        private static func parseDateComponents(
            _ datePart: String
        ) throws -> (years: Int, months: Int, days: Int) {
            var years = 0
            var months = 0
            var days = 0
            var scanner = datePart[...]

            // Years
            if let yIndex = scanner.firstIndex(of: "Y") {
                let numStr = String(scanner[..<yIndex])
                guard !numStr.isEmpty, let num = Int(numStr) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid year component")
                }
                years = num
                scanner = scanner[scanner.index(after: yIndex)...]
            }

            // Months
            if let mIndex = scanner.firstIndex(of: "M") {
                let numStr = String(scanner[..<mIndex])
                guard !numStr.isEmpty, let num = Int(numStr) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid month component")
                }
                months = num
                scanner = scanner[scanner.index(after: mIndex)...]
            }

            // Days
            if let dIndex = scanner.firstIndex(of: "D") {
                let numStr = String(scanner[..<dIndex])
                guard !numStr.isEmpty, let num = Int(numStr) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid day component")
                }
                days = num
            }

            return (years, months, days)
        }

        private static func parseTimeComponents(
            _ timePart: String
        ) throws -> (hours: Int, minutes: Int, seconds: Int, nanoseconds: Int) {
            var hours = 0
            var minutes = 0
            var seconds = 0
            var nanoseconds = 0
            var scanner = timePart[...]

            // Hours
            if let hIndex = scanner.firstIndex(of: "H") {
                let numStr = String(scanner[..<hIndex])
                guard !numStr.isEmpty, let num = Int(numStr) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid hour component")
                }
                hours = num
                scanner = scanner[scanner.index(after: hIndex)...]
            }

            // Minutes
            if let mIndex = scanner.firstIndex(of: "M") {
                let numStr = String(scanner[..<mIndex])
                guard !numStr.isEmpty, let num = Int(numStr) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid minute component")
                }
                minutes = num
                scanner = scanner[scanner.index(after: mIndex)...]
            }

            // Seconds (may include fractional)
            if let sIndex = scanner.firstIndex(of: "S") {
                let numStr = String(scanner[..<sIndex])

                guard !numStr.isEmpty else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid second component")
                }

                // Check for decimal point or comma
                if numStr.contains(".") || numStr.contains(",") {
                    let separator = numStr.contains(".") ? "." : ","
                    let comps = numStr.split(separator: Character(separator)).map(String.init)
                    guard comps.count == 2 else {
                        throw ISO_8601.Date.Error.invalidFormat("Invalid fractional seconds")
                    }

                    guard let sec = Int(comps[0]) else {
                        throw ISO_8601.Date.Error.invalidSecond(comps[0])
                    }
                    seconds = sec

                    // Parse fractional part
                    let fracStr = comps[1]
                    // Pad or truncate to 9 digits (nanoseconds)
                    var paddedFrac = fracStr
                    if fracStr.count < 9 {
                        paddedFrac = fracStr + String(repeating: "0", count: 9 - fracStr.count)
                    } else if fracStr.count > 9 {
                        paddedFrac = String(fracStr.prefix(9))
                    }
                    guard let nano = Int(paddedFrac) else {
                        throw ISO_8601.Date.Error.invalidFractionalSecond(fracStr)
                    }
                    nanoseconds = nano
                } else {
                    guard let sec = Int(numStr) else {
                        throw ISO_8601.Date.Error.invalidSecond(numStr)
                    }
                    seconds = sec
                }
            }

            return (hours, minutes, seconds, nanoseconds)
        }
    }
}

// MARK: - Codable

extension ISO_8601.Duration: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = try Parser.parse(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
