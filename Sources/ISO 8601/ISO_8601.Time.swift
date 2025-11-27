//
//  ISO_8601.Time.swift
//  swift-iso-8601
//
//  ISO 8601 Time-only representation
//

import StandardTime

extension ISO_8601 {
    /// ISO 8601 Time-only representation
    ///
    /// Represents a time of day without a date component per ISO 8601:2019.
    ///
    /// ## Format
    /// - Extended: `HH:MM:SS` or `HH:MM` or `HH`
    /// - Basic: `HHMMSS` or `HHMM` or `HH`
    /// - With timezone: `HH:MM:SSZ` or `HH:MM:SS+05:30`
    /// - With fractional seconds: `HH:MM:SS.sss`
    ///
    /// ## Examples
    /// - `12:30:45` - 12 hours, 30 minutes, 45 seconds
    /// - `12:30` - 12 hours, 30 minutes
    /// - `12` - 12 hours
    /// - `123045` - basic format
    /// - `12:30:45.123Z` - with fractional seconds and UTC
    /// - `12:30:45+05:30` - with timezone offset
    ///
    /// ```swift
    /// let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45)
    /// let formatted = time.description  // "12:30:45"
    /// let parsed = try ISO_8601.Time.Parser.parse("12:30:45Z")
    /// ```
    public struct Time: Sendable, Equatable, Hashable {
        /// Hour component (0-24, where 24 is only valid with minute=0, second=0, nanoseconds=0)
        public let hour: Int

        /// Minute component (0-59), nil for reduced precision
        public let minute: Int?

        /// Second component (0-60, allowing leap second), nil for reduced precision
        public let second: Int?

        /// Nanoseconds component (0-999,999,999)
        public let nanoseconds: Int

        /// Timezone offset in seconds from UTC, nil if not specified
        /// Positive values are east of UTC, negative values are west
        public let timezoneOffsetSeconds: Int?

        /// Create a time with specified components
        ///
        /// - Parameters:
        ///   - hour: Hour (0-24)
        ///   - minute: Minute (0-59, default: nil for reduced precision)
        ///   - second: Second (0-60, default: nil for reduced precision)
        ///   - nanoseconds: Nanoseconds (0-999,999,999, default: 0)
        ///   - timezoneOffsetSeconds: Timezone offset in seconds (default: nil)
        /// - Throws: `ISO_8601.Date.Error` if any component is out of valid range
        public init(
            hour: Int,
            minute: Int? = nil,
            second: Int? = nil,
            nanoseconds: Int = 0,
            timezoneOffsetSeconds: Int? = nil
        ) throws {
            // Validate hour (0-24)
            guard (0...24).contains(hour) else {
                throw ISO_8601.Date.Error.hourOutOfRange(hour)
            }

            // If hour is 24, only 24:00:00.0 is valid
            if hour == 24 {
                guard minute == nil || minute == 0,
                      second == nil || second == 0,
                      nanoseconds == 0 else {
                    throw ISO_8601.Date.Error.invalidTime("24:xx:xx is not valid, only 24:00:00 is allowed")
                }
            }

            // Validate minute if present
            if let min = minute {
                guard (0...59).contains(min) else {
                    throw ISO_8601.Date.Error.minuteOutOfRange(min)
                }
            }

            // Validate second if present (allowing 60 for leap second)
            if let sec = second {
                guard (0...60).contains(sec) else {
                    throw ISO_8601.Date.Error.secondOutOfRange(sec)
                }
            }

            // Validate nanoseconds
            guard (0..<1_000_000_000).contains(nanoseconds) else {
                throw ISO_8601.Date.Error.invalidFractionalSecond(String(nanoseconds))
            }

            self.hour = hour
            self.minute = minute
            self.second = second
            self.nanoseconds = nanoseconds
            self.timezoneOffsetSeconds = timezoneOffsetSeconds
        }
    }
}

// MARK: - Formatting

extension ISO_8601.Time: CustomStringConvertible {
    public var description: String {
        Formatter.format(self)
    }
}

extension ISO_8601.Time {
    /// Formatter for ISO 8601 time strings
    public enum Formatter {
        /// Format a time as an ISO 8601 string
        ///
        /// - Parameters:
        ///   - value: The time to format
        ///   - extended: Use extended format with colons (default: true)
        /// - Returns: ISO 8601 time string (e.g., "12:30:45" or "123045")
        public static func format(_ value: ISO_8601.Time, extended: Bool = true) -> String {
            var result = ""

            // Hour (always present)
            let hourStr = value.hour < 10 ? "0\(value.hour)" : "\(value.hour)"

            if let minute = value.minute {
                let minStr = minute < 10 ? "0\(minute)" : "\(minute)"

                if let second = value.second {
                    let secStr = second < 10 ? "0\(second)" : "\(second)"

                    if extended {
                        result = "\(hourStr):\(minStr):\(secStr)"
                    } else {
                        result = "\(hourStr)\(minStr)\(secStr)"
                    }

                    // Add fractional seconds if present
                    if value.nanoseconds > 0 {
                        result += formatFractionalSeconds(value.nanoseconds)
                    }
                } else {
                    // Hour and minute only
                    if extended {
                        result = "\(hourStr):\(minStr)"
                    } else {
                        result = "\(hourStr)\(minStr)"
                    }
                }
            } else {
                // Hour only
                result = hourStr
            }

            // Add timezone if present
            if let offset = value.timezoneOffsetSeconds {
                if offset == 0 {
                    result += "Z"
                } else {
                    result += formatTimezoneOffset(offset, extended: extended)
                }
            }

            return result
        }

        private static func formatFractionalSeconds(_ nanoseconds: Int) -> String {
            // Remove trailing zeros
            var nano = nanoseconds
            while nano > 0 && nano % 10 == 0 {
                nano /= 10
            }

            if nano == 0 {
                return ""
            }

            return ".\(nano)"
        }

        private static func formatTimezoneOffset(_ offsetSeconds: Int, extended: Bool) -> String {
            let sign = offsetSeconds >= 0 ? "+" : "-"
            let absOffset = abs(offsetSeconds)
            let hours = absOffset / StandardTime.Time.Calendar.Gregorian.TimeConstants.secondsPerHour
            let minutes = (absOffset % StandardTime.Time.Calendar.Gregorian.TimeConstants.secondsPerHour) / StandardTime.Time.Calendar.Gregorian.TimeConstants.secondsPerMinute

            let hoursStr = hours < 10 ? "0\(hours)" : "\(hours)"
            let minutesStr = minutes < 10 ? "0\(minutes)" : "\(minutes)"

            if extended {
                return "\(sign)\(hoursStr):\(minutesStr)"
            } else {
                return "\(sign)\(hoursStr)\(minutesStr)"
            }
        }
    }
}

// MARK: - Parsing

extension ISO_8601.Time {
    /// Parser for ISO 8601 time strings
    public enum Parser {
        /// Parse an ISO 8601 time string
        ///
        /// - Parameter value: The time string (e.g., "12:30:45", "123045Z", "12:30")
        /// - Returns: Time instance
        /// - Throws: `ISO_8601.Date.Error` if parsing fails
        public static func parse(_ value: String) throws -> ISO_8601.Time {
            // Extract timezone portion (Z, +HH:MM, -HH:MM, etc.)
            var timePart = value
            var timezoneOffset: Int? = nil

            if value.hasSuffix("Z") {
                timePart = String(value.dropLast())
                timezoneOffset = 0
            } else if let plusIndex = value.lastIndex(of: "+") {
                timePart = String(value[..<plusIndex])
                let tzPart = String(value[value.index(after: plusIndex)...])
                timezoneOffset = try parseTimezoneOffset(tzPart, positive: true)
            } else if let minusIndex = value.lastIndex(of: "-"), minusIndex != value.startIndex {
                timePart = String(value[..<minusIndex])
                let tzPart = String(value[value.index(after: minusIndex)...])
                timezoneOffset = try parseTimezoneOffset(tzPart, positive: false)
            }

            var hour: Int
            var minute: Int? = nil
            var second: Int? = nil
            var nanoseconds = 0

            if timePart.contains(":") {
                // Extended format: HH:MM:SS or HH:MM or HH
                let parts = timePart.split(separator: ":").map(String.init)
                guard !parts.isEmpty else {
                    throw ISO_8601.Date.Error.invalidTime("Empty time")
                }

                guard let h = Int(parts[0]) else {
                    throw ISO_8601.Date.Error.invalidHour(parts[0])
                }
                hour = h

                if parts.count >= 2 {
                    guard let m = Int(parts[1]) else {
                        throw ISO_8601.Date.Error.invalidMinute(parts[1])
                    }
                    minute = m

                    if parts.count >= 3 {
                        // Parse seconds with possible fractional part
                        let (sec, nano) = try parseFractionalSeconds(parts[2])
                        second = sec
                        nanoseconds = nano
                    }
                }
            } else {
                // Basic format: HHMMSS or HHMM or HH
                // Check for fractional seconds first
                let (intPart, fracPart) = extractFractionalPart(timePart)

                if intPart.count == 2 {
                    // HH only
                    guard let h = Int(intPart) else {
                        throw ISO_8601.Date.Error.invalidHour(intPart)
                    }
                    hour = h
                } else if intPart.count == 4 {
                    // HHMM
                    let hourStr = String(intPart.prefix(2))
                    let minuteStr = String(intPart.dropFirst(2))

                    guard let h = Int(hourStr) else {
                        throw ISO_8601.Date.Error.invalidHour(hourStr)
                    }
                    guard let m = Int(minuteStr) else {
                        throw ISO_8601.Date.Error.invalidMinute(minuteStr)
                    }

                    hour = h
                    minute = m
                } else if intPart.count == 6 || !fracPart.isEmpty {
                    // HHMMSS with possible fractional
                    let hourStr = String(intPart.prefix(2))
                    let minuteStr = String(intPart.dropFirst(2).prefix(2))
                    let secondStr = String(intPart.dropFirst(4).prefix(2))

                    guard let h = Int(hourStr) else {
                        throw ISO_8601.Date.Error.invalidHour(hourStr)
                    }
                    guard let m = Int(minuteStr) else {
                        throw ISO_8601.Date.Error.invalidMinute(minuteStr)
                    }
                    guard let s = Int(secondStr) else {
                        throw ISO_8601.Date.Error.invalidSecond(secondStr)
                    }

                    hour = h
                    minute = m
                    second = s

                    if !fracPart.isEmpty {
                        nanoseconds = try parseFractionalPart(fracPart)
                    }
                } else {
                    throw ISO_8601.Date.Error.invalidTime("Invalid time length: \(intPart.count)")
                }
            }

            return try ISO_8601.Time(
                hour: hour,
                minute: minute,
                second: second,
                nanoseconds: nanoseconds,
                timezoneOffsetSeconds: timezoneOffset
            )
        }

        private static func parseFractionalSeconds(_ value: String) throws -> (seconds: Int, nanoseconds: Int) {
            // Check for decimal point or comma
            let separator: Character
            if value.contains(".") {
                separator = "."
            } else if value.contains(",") {
                separator = ","
            } else {
                // No fractional part
                guard let s = Int(value) else {
                    throw ISO_8601.Date.Error.invalidSecond(value)
                }
                return (s, 0)
            }

            let comps = value.split(separator: separator).map(String.init)
            guard comps.count == 2 else {
                throw ISO_8601.Date.Error.invalidFormat("Invalid fractional seconds")
            }

            guard let sec = Int(comps[0]) else {
                throw ISO_8601.Date.Error.invalidSecond(comps[0])
            }

            let nano = try parseFractionalPart(comps[1])
            return (sec, nano)
        }

        private static func parseFractionalPart(_ fracStr: String) throws -> Int {
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
            return nano
        }

        private static func extractFractionalPart(_ value: String) -> (intPart: String, fracPart: String) {
            if let dotIndex = value.firstIndex(of: ".") {
                return (String(value[..<dotIndex]), String(value[value.index(after: dotIndex)...]))
            } else if let commaIndex = value.firstIndex(of: ",") {
                return (String(value[..<commaIndex]), String(value[value.index(after: commaIndex)...]))
            } else {
                return (value, "")
            }
        }

        private static func parseTimezoneOffset(_ value: String, positive: Bool) throws -> Int {
            let hours: Int
            let minutes: Int

            if value.contains(":") {
                // Extended format: HH:MM
                let parts = value.split(separator: ":").map(String.init)
                guard parts.count == 2 else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid timezone offset")
                }

                guard let h = Int(parts[0]) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid timezone hours")
                }
                guard let m = Int(parts[1]) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid timezone minutes")
                }

                hours = h
                minutes = m
            } else {
                // Basic format: HHMM
                guard value.count == 4 else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid timezone offset length")
                }

                let hoursStr = String(value.prefix(2))
                let minutesStr = String(value.dropFirst(2))

                guard let h = Int(hoursStr) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid timezone hours")
                }
                guard let m = Int(minutesStr) else {
                    throw ISO_8601.Date.Error.invalidFormat("Invalid timezone minutes")
                }

                hours = h
                minutes = m
            }

            let offset = hours * StandardTime.Time.Calendar.Gregorian.TimeConstants.secondsPerHour + minutes * StandardTime.Time.Calendar.Gregorian.TimeConstants.secondsPerMinute
            return positive ? offset : -offset
        }
    }
}

// MARK: - Codable

extension ISO_8601.Time: Codable {
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

// MARK: - Weekday

extension ISO_8601.Time {
    /// Day of the week
    ///
    /// Represents the seven days of the week in both ISO 8601 numbering
    /// (Monday=1) and Gregorian/Western numbering (Sunday=0).
    ///
    /// ## Examples
    /// ```swift
    /// // Calculate weekday from a date
    /// let weekday = Time.Weekday(year: 2024, month: 1, day: 15)
    /// print(weekday)  // monday
    ///
    /// // ISO 8601 numbering (Monday=1, Sunday=7)
    /// let isoNumber = weekday.isoNumber  // 1
    ///
    /// // Gregorian numbering (Sunday=0, Saturday=6)
    /// let gregorianNumber = weekday.gregorianNumber  // 1
    /// ```
    public enum Weekday: Int, Sendable, Equatable, Hashable, CaseIterable, Codable {
        case sunday = 0
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6

        /// Calculate the weekday for a given calendar date
        ///
        /// Uses Zeller's congruence algorithm to determine the day of the week.
        ///
        /// - Parameters:
        ///   - year: The year
        ///   - month: The month (1-12)
        ///   - day: The day of the month (1-31)
        ///   - startingWith: The first day of the week for numbering (default: Sunday for Gregorian)
        /// - Returns: The weekday for the given date
        ///
        /// ## Example
        /// ```swift
        /// let weekday = Time.Weekday(year: 2024, month: 1, day: 15)  // Monday
        /// let isoWeekday = Time.Weekday(year: 2024, month: 1, day: 15, startingWith: .monday)
        /// ```
        public init(year: Int, month: Int, day: Int, startingWith: Weekday = .sunday) {
            let calculatedDay = Self.calculate(year: year, month: month, day: day)
            self = calculatedDay
        }

        /// ISO 8601 weekday number (1=Monday, 2=Tuesday, ..., 7=Sunday)
        public var isoNumber: Int {
            switch self {
            case .monday: return 1
            case .tuesday: return 2
            case .wednesday: return 3
            case .thursday: return 4
            case .friday: return 5
            case .saturday: return 6
            case .sunday: return 7
            }
        }

        /// Gregorian/Western weekday number (0=Sunday, 1=Monday, ..., 6=Saturday)
        public var gregorianNumber: Int {
            rawValue
        }

        /// Calculate weekday using Zeller's congruence
        ///
        /// This is an internal helper that uses Zeller's congruence algorithm
        /// to determine the day of the week for any Gregorian calendar date.
        ///
        /// - Parameters:
        ///   - year: The year
        ///   - month: The month (1-12)
        ///   - day: The day of the month
        /// - Returns: The weekday
        internal static func calculate(year: Int, month: Int, day: Int) -> Weekday {
            var y = year
            var m = month

            // Zeller's congruence: treat Jan/Feb as months 13/14 of previous year
            if m < 3 {
                m += 12
                y -= 1
            }

            let q = day
            let K = y % 100
            let J = y / 100

            // Zeller's formula
            let h = (q + ((13 * (m + 1)) / 5) + K + (K / 4) + (J / 4) - (2 * J)) % 7

            // Convert from Zeller's (0=Saturday) to Gregorian (0=Sunday)
            let gregorianDay = (h + 6) % 7

            return Weekday(rawValue: gregorianDay)!
        }

        /// Create from ISO 8601 weekday number (1=Monday, ..., 7=Sunday)
        public init?(isoNumber: Int) {
            switch isoNumber {
            case 1: self = .monday
            case 2: self = .tuesday
            case 3: self = .wednesday
            case 4: self = .thursday
            case 5: self = .friday
            case 6: self = .saturday
            case 7: self = .sunday
            default: return nil
            }
        }

        /// Create from Gregorian weekday number (0=Sunday, ..., 6=Saturday)
        public init?(gregorianNumber: Int) {
            self.init(rawValue: gregorianNumber)
        }
    }
}
