//
//  ISO_8601.Date.Components.swift
//  swift-iso-8601
//
//  Date components with validation
//

import StandardTime

extension ISO_8601.Date {
    /// Date components extracted from a date-time
    ///
    /// ISO 8601 calendar date components follow the Gregorian calendar.
    /// Unlike RFC 5322, weekday is not required in the public initializer since
    /// ISO 8601 calendar dates don't include day names.
    public struct Components: Sendable, Equatable {
        public let year: Int
        public let month: Int      // 1-12
        public let day: Int        // 1-31
        public let hour: Int       // 0-23
        public let minute: Int     // 0-59
        public let second: Int     // 0-60 (allowing leap second)
        public let nanoseconds: Int  // 0-999,999,999
        public let weekday: Int    // 0=Sunday, 6=Saturday (internal, Zeller's)
        
        /// Creates date components with validation
        /// - Throws: `ISO_8601.Date.Error` if any component is out of valid range
        ///
        /// Note: weekday is computed internally and is not part of the public API
        /// for initialization, as ISO 8601 calendar dates don't display weekday names.
        public init(
            year: Int,
            month: Int,
            day: Int,
            hour: Int,
            minute: Int,
            second: Int,
            nanoseconds: Int = 0
        ) throws {
            // Validate month
            guard (1...12).contains(month) else {
                throw ISO_8601.Date.Error.monthOutOfRange(month)
            }

            // Validate day for the given month and year
            let maxDay = Self.daysInMonth(month, year: year)
            guard (1...maxDay).contains(day) else {
                throw ISO_8601.Date.Error.dayOutOfRange(day, month: month, year: year)
            }

            // Validate hour
            guard (0...23).contains(hour) else {
                throw ISO_8601.Date.Error.hourOutOfRange(hour)
            }

            // Validate minute
            guard (0...59).contains(minute) else {
                throw ISO_8601.Date.Error.minuteOutOfRange(minute)
            }

            // Validate second (allowing 60 for leap second)
            guard (0...60).contains(second) else {
                throw ISO_8601.Date.Error.secondOutOfRange(second)
            }

            // Validate nanoseconds
            guard (0..<1_000_000_000).contains(nanoseconds) else {
                throw ISO_8601.Date.Error.invalidFractionalSecond(String(nanoseconds))
            }

            self.year = year
            self.month = month
            self.day = day
            self.hour = hour
            self.minute = minute
            self.second = second
            self.nanoseconds = nanoseconds
            // Compute weekday using Zeller's congruence (0=Sunday)
            self.weekday = Self.computeWeekday(year: year, month: month, day: day)
        }
    }
}

extension ISO_8601.Date.Components {
    
    /// Creates date components without validation (internal use only)
    ///
    /// This initializer bypasses validation and should only be used when component values
    /// are known to be valid (e.g., computed from epoch seconds).
    ///
    /// - Warning: Using this with invalid values will create an invalid Components instance.
    ///   Only use when values are guaranteed valid by construction.
    internal init(
        uncheckedYear year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        nanoseconds: Int,
        weekday: Int
    ) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanoseconds = nanoseconds
        self.weekday = weekday
    }
}

extension ISO_8601.Date.Components {
    /// Returns the number of days in the given month for the given year
    private static func daysInMonth(_ month: Int, year: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12:
            return 31
        case 4, 6, 9, 11:
            return 30
        case 2:
            return isLeapYear(year) ? 29 : 28
        default:
            return 0
        }
    }
    
    /// Returns true if the year is a leap year
    private static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
    
    /// Compute weekday using Zeller's congruence
    /// Returns 0=Sunday, 1=Monday, ..., 6=Saturday
    private static func computeWeekday(year: Int, month: Int, day: Int) -> Int {
        // Zeller's congruence algorithm
        // For January and February, treat as months 13 and 14 of previous year
        let m = month < 3 ? month + 12 : month
        let y = month < 3 ? year - 1 : year
        let q = day
        let k = y % 100
        let j = y / 100
        
        let h = (q + ((13 * (m + 1)) / 5) + k + (k / 4) + (j / 4) - (2 * j)) % 7
        
        // Zeller's returns 0=Saturday, convert to 0=Sunday
        return (h + 6) % 7
    }
}

extension ISO_8601.Date.Components {
    public init(_ dateTime: ISO_8601.Date) {
        // Apply timezone offset to get local time components
        let localTime = StandardTime.Time(
            secondsSinceEpoch: dateTime.secondsSinceEpoch + dateTime.timezoneOffsetSeconds
        )

        // Convert StandardTime.Time.Weekday enum to Int (0=Sunday)
        let weekdayNumber: Int
        switch localTime.weekday {
        case .sunday: weekdayNumber = 0
        case .monday: weekdayNumber = 1
        case .tuesday: weekdayNumber = 2
        case .wednesday: weekdayNumber = 3
        case .thursday: weekdayNumber = 4
        case .friday: weekdayNumber = 5
        case .saturday: weekdayNumber = 6
        }

        // Components calculated from valid epoch seconds are always valid
        // Use unchecked initializer to bypass validation in hot path
        self = ISO_8601.Date.Components(
            uncheckedYear: localTime.year.value,
            month: localTime.month.value,
            day: localTime.day.value,
            hour: localTime.hour.value,
            minute: localTime.minute.value,
            second: localTime.second.value,
            nanoseconds: dateTime.nanoseconds,
            weekday: weekdayNumber
        )
    }
}
