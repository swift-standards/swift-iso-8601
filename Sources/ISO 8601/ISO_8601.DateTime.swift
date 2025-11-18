//
//  ISO_8601.DateTime.swift
//  swift-iso-8601
//
//  Core date-time representation following ISO 8601:2019
//

import Standards

// MARK: - Time Constants



extension ISO_8601 {

    public typealias Date = DateTime

    /// ISO 8601 date-time representation
    ///
    /// Represents a date-time value per ISO 8601:2019.
    /// Stores seconds since Unix epoch (1970-01-01 00:00:00 UTC) internally.
    ///
    /// ## Three Representations
    ///
    /// ISO 8601 supports three different date representations:
    /// - **Calendar Date**: Year-Month-Day (most common)
    /// - **Week Date**: Year-Week-Weekday
    /// - **Ordinal Date**: Year-DayOfYear
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dateTime = try ISO_8601.DateTime(year: 2024, month: 1, day: 15, hour: 12, minute: 30)
    /// print(ISO_8601.DateTime.Formatter.format(dateTime))
    /// // "2024-01-15T12:30:00Z"
    /// ```
    public struct DateTime: Sendable, Equatable, Hashable, Comparable {
        /// Seconds since Unix epoch (1970-01-01 00:00:00 UTC)
        public let secondsSinceEpoch: Int

        /// Nanoseconds component (0-999,999,999)
        public let nanoseconds: Int

        /// Timezone offset in seconds from UTC
        /// Positive values are east of UTC, negative values are west
        /// Example: +0100 = 3600, -0500 = -18000
        public let timezoneOffsetSeconds: Int

        /// Create a date-time from seconds since epoch
        /// - Parameters:
        ///   - secondsSinceEpoch: Seconds since Unix epoch (UTC)
        ///   - nanoseconds: Nanoseconds component (0-999,999,999, default: 0)
        ///   - timezoneOffsetSeconds: Timezone offset in seconds (default: 0 for UTC)
        /// - Throws: `ISO_8601.Date.Error` if nanoseconds is out of range
        public init(secondsSinceEpoch: Int = 0, nanoseconds: Int = 0, timezoneOffsetSeconds: Int = 0) throws {
            guard (0..<1_000_000_000).contains(nanoseconds) else {
                throw ISO_8601.Date.Error.invalidFractionalSecond(String(nanoseconds))
            }
            self.secondsSinceEpoch = secondsSinceEpoch
            self.nanoseconds = nanoseconds
            self.timezoneOffsetSeconds = timezoneOffsetSeconds
        }

        /// Create a date-time without validation (internal use only)
        /// - Warning: Using this with invalid nanoseconds will create an invalid DateTime
        internal init(uncheckedSecondsEpoch: Int, nanoseconds: Int = 0, timezoneOffsetSeconds: Int = 0) {
            self.secondsSinceEpoch = uncheckedSecondsEpoch
            self.nanoseconds = nanoseconds
            self.timezoneOffsetSeconds = timezoneOffsetSeconds
        }
    }
}

// MARK: - Comparable

extension ISO_8601.DateTime {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.secondsSinceEpoch != rhs.secondsSinceEpoch {
            return lhs.secondsSinceEpoch < rhs.secondsSinceEpoch
        }
        return lhs.nanoseconds < rhs.nanoseconds
    }
}

// MARK: - Equatable & Hashable

extension ISO_8601.DateTime {
    /// Two DateTimes are equal if they represent the same moment in time
    /// (same secondsSinceEpoch and nanoseconds), regardless of timezone offset
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.secondsSinceEpoch == rhs.secondsSinceEpoch && lhs.nanoseconds == rhs.nanoseconds
    }

    /// Hash based on the moment in time (seconds and nanoseconds), not timezone display
    public func hash(into hasher: inout Hasher) {
        hasher.combine(secondsSinceEpoch)
        hasher.combine(nanoseconds)
    }
}

// MARK: - Additional Initializers

extension ISO_8601.DateTime {
    /// Create a date-time from calendar date components with validation
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    ///   - day: Day (1-31, validated for month/year)
    ///   - hour: Hour (0-23)
    ///   - minute: Minute (0-59)
    ///   - second: Second (0-60, allowing leap second)
    ///   - nanoseconds: Nanoseconds (0-999,999,999, default: 0)
    ///   - timezoneOffsetSeconds: Timezone offset in seconds (default: 0 for UTC)
    /// - Throws: `ISO_8601.Date.Error` if any component is out of valid range
    ///
    /// Components are interpreted in UTC, then the timezone offset is applied for display.
    public init(
        year: Int,
        month: Int,  // 1-12
        day: Int,    // 1-31
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        nanoseconds: Int = 0,
        timezoneOffsetSeconds: Int = 0
    ) throws {
        // Validate all components by attempting to create Components
        // This provides consistent validation logic
        _ = try ISO_8601.Date.Components(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )

        // Calculate days since epoch
        let daysSinceEpoch = Self.daysSinceEpoch(year: year, month: month, day: day)

        // Calculate total seconds (as UTC)
        let totalSeconds =
            daysSinceEpoch * TimeConstants.secondsPerDay +
            hour * TimeConstants.secondsPerHour +
            minute * TimeConstants.secondsPerMinute +
            second

        try self.init(secondsSinceEpoch: totalSeconds, nanoseconds: nanoseconds, timezoneOffsetSeconds: timezoneOffsetSeconds)
    }
}

// MARK: - Components Extraction

extension ISO_8601.DateTime {
    /// Extract calendar date components (Year-Month-Day)
    ///
    /// Components reflect the local time based on `timezoneOffsetSeconds`.
    /// The same moment in time will have different components in different timezones.
    public var components: ISO_8601.Date.Components {
        .init(self)
    }
}

// MARK: - ISO 8601 Specific Properties

extension ISO_8601.DateTime {
    /// ISO weekday (1=Monday, 2=Tuesday, ..., 7=Sunday)
    ///
    /// Converts from Zeller's congruence (0=Sunday) to ISO 8601 numbering (1=Monday)
    public var isoWeekday: Int {
        let comp = components
        // Zeller's: 0=Sunday, 1=Monday, ..., 6=Saturday
        // ISO: 1=Monday, 2=Tuesday, ..., 7=Sunday
        return comp.weekday == 0 ? 7 : comp.weekday
    }

    /// Ordinal day of year (1-365 or 1-366 in leap years)
    ///
    /// This is the day number within the year, starting from 1 for January 1.
    public var ordinalDay: Int {
        let comp = components
        let monthDays = Self.daysInMonths(year: comp.year)
        var days = comp.day
        for m in 0..<(comp.month - 1) {
            days += monthDays[m]
        }
        return days
    }

    /// ISO week-year (may differ from calendar year at boundaries)
    ///
    /// December 29-31 might belong to next year's week 1
    /// January 1-3 might belong to previous year's last week
    public var isoWeekYear: Int {
        let comp = components
        let week = isoWeek

        // If we're in week 1 but in December, the week-year is next year
        if comp.month == 12 && week == 1 {
            return comp.year + 1
        }

        // If we're in week 52/53 but in January, the week-year is previous year
        if comp.month == 1 && week >= 52 {
            return comp.year - 1
        }

        return comp.year
    }

    /// ISO week number (1-53)
    ///
    /// Week 1 is the first week containing the first Thursday of the year
    /// (equivalently, the week containing January 4th)
    public var isoWeek: Int {
        let comp = components

        // Find the Monday of the week containing this date
        // ISO weekday: 1=Monday, 7=Sunday
        let isoDay = isoWeekday
        let daysSinceMonday = isoDay - 1
        let mondayOfWeek = Self.daysSinceEpoch(year: comp.year, month: comp.month, day: comp.day) - daysSinceMonday

        // Find January 4th of this year (which is always in week 1)
        let jan4 = Self.daysSinceEpoch(year: comp.year, month: 1, day: 4)

        // Find the Monday of the week containing January 4th
        let jan4Weekday = Self.weekday(year: comp.year, month: 1, day: 4)
        let jan4ISOWeekday = jan4Weekday == 0 ? 7 : jan4Weekday
        let jan4DaysSinceMonday = jan4ISOWeekday - 1
        let mondayOfWeek1 = jan4 - jan4DaysSinceMonday

        // Calculate week number
        let weekNumber = ((mondayOfWeek - mondayOfWeek1) / 7) + 1

        // Handle edge cases
        if weekNumber < 1 {
            // This date belongs to the last week of the previous year
            // Calculate the number of weeks in the previous year
            return Self.weeksInYear(comp.year - 1)
        } else if weekNumber > Self.weeksInYear(comp.year) {
            // This date belongs to week 1 of the next year
            return 1
        }

        return weekNumber
    }

    /// Calculate the number of weeks in a given ISO year
    internal static func weeksInYear(_ year: Int) -> Int {
        // A year has 53 weeks if:
        // - January 1 is a Thursday, OR
        // - January 1 is a Wednesday and it's a leap year

        let jan1Weekday = weekday(year: year, month: 1, day: 1)
        let jan1ISOWeekday = jan1Weekday == 0 ? 7 : jan1Weekday

        if jan1ISOWeekday == 4 { // Thursday
            return 53
        }

        if jan1ISOWeekday == 3 && isLeapYear(year) { // Wednesday and leap year
            return 53
        }

        return 52
    }
}

// MARK: - Conversion to Other ISO 8601 Representations

extension ISO_8601.DateTime {
    /// Convert to week date representation
    public func toWeekDate() -> ISO_8601.WeekDate {
        ISO_8601.WeekDate(
            uncheckedWeekYear: isoWeekYear,
            week: isoWeek,
            weekday: isoWeekday
        )
    }

    /// Convert to ordinal date representation
    public func toOrdinalDate() -> ISO_8601.OrdinalDate {
        let comp = components
        return ISO_8601.OrdinalDate(
            uncheckedYear: comp.year,
            day: ordinalDay
        )
    }
}

// MARK: - Formatter

extension ISO_8601.DateTime {
    /// Dedicated formatter for ISO 8601 date-time strings
    ///
    /// Supports all three ISO 8601 date representations:
    /// - Calendar: `2024-01-15` (extended) or `20240115` (basic)
    /// - Week: `2024-W03-2` (extended) or `2024W032` (basic)
    /// - Ordinal: `2024-039` (extended) or `2024039` (basic)
    ///
    /// Can include time and timezone:
    /// - `2024-01-15T12:30:00Z`
    /// - `2024-01-15T12:30:00+05:30`
    /// - `20240115T123000Z` (basic format)
    public enum Formatter {
        /// Date format options
        public enum DateFormat {
            case calendar(extended: Bool)    // YYYY-MM-DD or YYYYMMDD
            case week(extended: Bool)        // YYYY-Www-D or YYYYWwwD
            case ordinal(extended: Bool)     // YYYY-DDD or YYYYDDD
        }

        /// Time format options
        public enum TimeFormat {
            case none
            case time(extended: Bool)        // HH:MM:SS or HHMMSS
        }

        /// Timezone format options
        public enum TimezoneFormat {
            case none
            case utc                         // Z
            case offset(extended: Bool)      // +05:30 or +0530
        }

        /// Format a DateTime as ISO 8601 string
        ///
        /// - Parameters:
        ///   - value: The DateTime to format
        ///   - date: Date format (default: calendar extended)
        ///   - time: Time format (default: extended time)
        ///   - timezone: Timezone format (default: UTC 'Z')
        /// - Returns: ISO 8601 formatted string
        public static func format(
            _ value: ISO_8601.DateTime,
            date: DateFormat = .calendar(extended: true),
            time: TimeFormat = .time(extended: true),
            timezone: TimezoneFormat = .utc
        ) -> String {
            var result = ""

            // Format date portion
            switch date {
            case .calendar(let extended):
                result += formatCalendarDate(value, extended: extended)
            case .week(let extended):
                result += formatWeekDate(value, extended: extended)
            case .ordinal(let extended):
                result += formatOrdinalDate(value, extended: extended)
            }

            // Format time portion if requested
            switch time {
            case .none:
                break
            case .time(let extended):
                result += "T"
                result += formatTime(value, extended: extended)

                // Format timezone if time is included
                switch timezone {
                case .none:
                    break
                case .utc:
                    result += "Z"
                case .offset(let extended):
                    result += formatTimezoneOffset(value.timezoneOffsetSeconds, extended: extended)
                }
            }

            return result
        }

        // MARK: - Private Formatting Helpers

        private static func formatCalendarDate(_ value: ISO_8601.DateTime, extended: Bool) -> String {
            let comp = value.components
            let year = formatFourDigits(comp.year)
            let month = formatTwoDigits(comp.month)
            let day = formatTwoDigits(comp.day)

            if extended {
                return "\(year)-\(month)-\(day)"
            } else {
                return "\(year)\(month)\(day)"
            }
        }

        private static func formatWeekDate(_ value: ISO_8601.DateTime, extended: Bool) -> String {
            let year = formatFourDigits(value.isoWeekYear)
            let week = formatTwoDigits(value.isoWeek)
            let weekday = value.isoWeekday

            if extended {
                return "\(year)-W\(week)-\(weekday)"
            } else {
                return "\(year)W\(week)\(weekday)"
            }
        }

        private static func formatOrdinalDate(_ value: ISO_8601.DateTime, extended: Bool) -> String {
            let comp = value.components
            let year = formatFourDigits(comp.year)
            let day = formatThreeDigits(value.ordinalDay)

            if extended {
                return "\(year)-\(day)"
            } else {
                return "\(year)\(day)"
            }
        }

        private static func formatTime(_ value: ISO_8601.DateTime, extended: Bool) -> String {
            let comp = value.components
            let hour = formatTwoDigits(comp.hour)
            let minute = formatTwoDigits(comp.minute)
            let second = formatTwoDigits(comp.second)

            var result: String
            if extended {
                result = "\(hour):\(minute):\(second)"
            } else {
                result = "\(hour)\(minute)\(second)"
            }

            // Add fractional seconds if present
            if comp.nanoseconds > 0 {
                result += formatFractionalSeconds(comp.nanoseconds)
            }

            return result
        }

        private static func formatFractionalSeconds(_ nanoseconds: Int) -> String {
            // Remove trailing zeros from nanoseconds
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
            let hours = absOffset / TimeConstants.secondsPerHour
            let minutes = (absOffset % TimeConstants.secondsPerHour) / TimeConstants.secondsPerMinute

            let hoursStr = formatTwoDigits(hours)
            let minutesStr = formatTwoDigits(minutes)

            if extended {
                return "\(sign)\(hoursStr):\(minutesStr)"
            } else {
                return "\(sign)\(hoursStr)\(minutesStr)"
            }
        }

        // MARK: - Digit Formatting Helpers

        /// Fast two-digit zero-padded formatting (00-99)
        private static func formatTwoDigits(_ value: Int) -> String {
            let tens = value / 10
            let ones = value % 10
            return "\(tens)\(ones)"
        }

        /// Fast three-digit zero-padded formatting (000-999)
        private static func formatThreeDigits(_ value: Int) -> String {
            let hundreds = value / 100
            let tens = (value % 100) / 10
            let ones = value % 10
            return "\(hundreds)\(tens)\(ones)"
        }

        /// Fast four-digit zero-padded formatting (0000-9999)
        private static func formatFourDigits(_ value: Int) -> String {
            let thousands = value / 1000
            let hundreds = (value % 1000) / 100
            let tens = (value % 100) / 10
            let ones = value % 10
            return "\(thousands)\(hundreds)\(tens)\(ones)"
        }
    }
}

// MARK: - Parser

extension ISO_8601.DateTime {
    /// Dedicated parser for ISO 8601 date-time strings
    ///
    /// Supports all three ISO 8601 date representations in both extended and basic formats:
    /// - Calendar: `2024-01-15` or `20240115`
    /// - Week: `2024-W03-2` or `2024W032`
    /// - Ordinal: `2024-039` or `2024039`
    ///
    /// With optional time and timezone:
    /// - `2024-01-15T12:30:00Z`
    /// - `2024-01-15T12:30:00+05:30`
    /// - `20240115T123000Z`
    public enum Parser {
        /// Parse an ISO 8601 date-time string
        ///
        /// - Parameter value: The ISO 8601 formatted string
        /// - Returns: DateTime instance
        /// - Throws: `ISO_8601.Date.Error` if parsing fails
        public static func parse(_ value: String) throws -> ISO_8601.DateTime {
            // Split on 'T' to separate date and time portions
            let parts = value.split(separator: "T", maxSplits: 1).map(String.init)

            guard !parts.isEmpty else {
                throw ISO_8601.Date.Error.invalidFormat("Empty string")
            }

            let datePart = parts[0]
            let timePart = parts.count > 1 ? parts[1] : nil

            // Parse date portion (detect format)
            let (year, month, day) = try parseDate(datePart)

            // Parse time portion if present
            var hour = 0
            var minute = 0
            var second = 0
            var nanoseconds = 0
            var timezoneOffset = 0

            if let time = timePart {
                (hour, minute, second, nanoseconds, timezoneOffset) = try parseTime(time)
            }

            // Handle 24:00:00 (midnight at end of day)
            // ISO 8601: 24:00:00 = 00:00:00 of next day
            if hour == 24 {
                guard minute == 0 && second == 0 && nanoseconds == 0 else {
                    throw ISO_8601.Date.Error.invalidTime("24:xx:xx is not valid, only 24:00:00 is allowed")
                }

                // Advance to next day at 00:00:00
                hour = 0
                let nextDayDateTime = try ISO_8601.DateTime(
                    year: year,
                    month: month,
                    day: day,
                    hour: 0,
                    minute: 0,
                    second: 0,
                    nanoseconds: 0,
                    timezoneOffsetSeconds: timezoneOffset
                )
                // Add one day (86400 seconds)
                return try ISO_8601.DateTime(
                    secondsSinceEpoch: nextDayDateTime.secondsSinceEpoch + TimeConstants.secondsPerDay,
                    nanoseconds: 0,
                    timezoneOffsetSeconds: timezoneOffset
                )
            }

            // Create DateTime
            return try ISO_8601.DateTime(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second,
                nanoseconds: nanoseconds,
                timezoneOffsetSeconds: timezoneOffset
            )
        }

        // MARK: - Date Parsing

        private static func parseDate(_ value: String) throws -> (year: Int, month: Int, day: Int) {
            // Detect format by looking for specific patterns
            if value.contains("W") {
                return try parseWeekDate(value)
            } else if value.count >= 7 && (value.count == 7 || value.count == 8) && !value.contains("-") {
                // Could be basic ordinal (YYYYDDD) or basic calendar (YYYYMMDD)
                if value.count == 7 {
                    return try parseOrdinalDate(value)
                } else {
                    return try parseCalendarDate(value)
                }
            } else if value.contains("-") {
                // Extended format - check length to distinguish
                let dashCount = value.filter { $0 == "-" }.count
                if dashCount == 1 {
                    // YYYY-DDD (ordinal extended)
                    return try parseOrdinalDate(value)
                } else {
                    // YYYY-MM-DD (calendar extended)
                    return try parseCalendarDate(value)
                }
            } else {
                // Basic calendar format YYYYMMDD
                return try parseCalendarDate(value)
            }
        }

        private static func parseCalendarDate(_ value: String) throws -> (year: Int, month: Int, day: Int) {
            if value.contains("-") {
                // Extended format: YYYY-MM-DD
                let parts = value.split(separator: "-").map(String.init)
                guard parts.count == 3 else {
                    throw ISO_8601.Date.Error.invalidFormat("Expected YYYY-MM-DD")
                }

                guard let year = Int(parts[0]) else {
                    throw ISO_8601.Date.Error.invalidYear(parts[0])
                }
                guard let month = Int(parts[1]) else {
                    throw ISO_8601.Date.Error.invalidMonth(parts[1])
                }
                guard let day = Int(parts[2]) else {
                    throw ISO_8601.Date.Error.invalidDay(parts[2])
                }

                return (year, month, day)
            } else {
                // Basic format: YYYYMMDD
                guard value.count == 8 else {
                    throw ISO_8601.Date.Error.invalidFormat("Expected YYYYMMDD (8 digits)")
                }

                let yearStr = String(value.prefix(4))
                let monthStr = String(value.dropFirst(4).prefix(2))
                let dayStr = String(value.dropFirst(6))

                guard let year = Int(yearStr) else {
                    throw ISO_8601.Date.Error.invalidYear(yearStr)
                }
                guard let month = Int(monthStr) else {
                    throw ISO_8601.Date.Error.invalidMonth(monthStr)
                }
                guard let day = Int(dayStr) else {
                    throw ISO_8601.Date.Error.invalidDay(dayStr)
                }

                return (year, month, day)
            }
        }

        private static func parseWeekDate(_ value: String) throws -> (year: Int, month: Int, day: Int) {
            if value.contains("-") {
                // Extended format: YYYY-Www-D
                let parts = value.split(separator: "-").map(String.init)
                guard parts.count == 3 else {
                    throw ISO_8601.Date.Error.invalidFormat("Expected YYYY-Www-D")
                }

                guard let weekYear = Int(parts[0]) else {
                    throw ISO_8601.Date.Error.invalidYear(parts[0])
                }

                // Parse week (remove 'W' prefix)
                guard parts[1].hasPrefix("W") else {
                    throw ISO_8601.Date.Error.invalidFormat("Week part must start with 'W'")
                }
                let weekStr = String(parts[1].dropFirst())
                guard let week = Int(weekStr) else {
                    throw ISO_8601.Date.Error.invalidWeekNumber(weekStr)
                }

                guard let weekday = Int(parts[2]) else {
                    throw ISO_8601.Date.Error.invalidWeekday(parts[2])
                }

                let weekDate = try ISO_8601.WeekDate(weekYear: weekYear, week: week, weekday: weekday)
                let dateTime = weekDate.toDateTime()
                let comp = dateTime.components
                return (comp.year, comp.month, comp.day)
            } else {
                // Basic format: YYYYWwwD
                guard value.count == 8, value.contains("W") else {
                    throw ISO_8601.Date.Error.invalidFormat("Expected YYYYWwwD")
                }

                let yearStr = String(value.prefix(4))
                guard let weekYear = Int(yearStr) else {
                    throw ISO_8601.Date.Error.invalidYear(yearStr)
                }

                // Find W position
                guard let wIndex = value.firstIndex(of: "W") else {
                    throw ISO_8601.Date.Error.invalidFormat("Missing 'W' in week date")
                }

                let afterW = value.index(after: wIndex)
                let weekStr = String(value[afterW..<value.index(afterW, offsetBy: 2)])
                let weekdayStr = String(value[value.index(afterW, offsetBy: 2)])

                guard let week = Int(weekStr) else {
                    throw ISO_8601.Date.Error.invalidWeekNumber(weekStr)
                }
                guard let weekday = Int(weekdayStr) else {
                    throw ISO_8601.Date.Error.invalidWeekday(weekdayStr)
                }

                let weekDate = try ISO_8601.WeekDate(weekYear: weekYear, week: week, weekday: weekday)
                let dateTime = weekDate.toDateTime()
                let comp = dateTime.components
                return (comp.year, comp.month, comp.day)
            }
        }

        private static func parseOrdinalDate(_ value: String) throws -> (year: Int, month: Int, day: Int) {
            if value.contains("-") {
                // Extended format: YYYY-DDD
                let parts = value.split(separator: "-").map(String.init)
                guard parts.count == 2 else {
                    throw ISO_8601.Date.Error.invalidFormat("Expected YYYY-DDD")
                }

                guard let year = Int(parts[0]) else {
                    throw ISO_8601.Date.Error.invalidYear(parts[0])
                }
                guard let ordinalDay = Int(parts[1]) else {
                    throw ISO_8601.Date.Error.invalidOrdinalDay(parts[1])
                }

                let ordinal = try ISO_8601.OrdinalDate(year: year, day: ordinalDay)
                let dateTime = ordinal.toDateTime()
                let comp = dateTime.components
                return (comp.year, comp.month, comp.day)
            } else {
                // Basic format: YYYYDDD
                guard value.count == 7 else {
                    throw ISO_8601.Date.Error.invalidFormat("Expected YYYYDDD (7 digits)")
                }

                let yearStr = String(value.prefix(4))
                let dayStr = String(value.dropFirst(4))

                guard let year = Int(yearStr) else {
                    throw ISO_8601.Date.Error.invalidYear(yearStr)
                }
                guard let ordinalDay = Int(dayStr) else {
                    throw ISO_8601.Date.Error.invalidOrdinalDay(dayStr)
                }

                let ordinal = try ISO_8601.OrdinalDate(year: year, day: ordinalDay)
                let dateTime = ordinal.toDateTime()
                let comp = dateTime.components
                return (comp.year, comp.month, comp.day)
            }
        }

        // MARK: - Time Parsing

        private static func parseTime(_ value: String) throws -> (hour: Int, minute: Int, second: Int, nanoseconds: Int, timezoneOffset: Int) {
            // Extract timezone portion (Z, +HH:MM, -HH:MM, etc.)
            var timePart = value
            var timezoneOffset = 0

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

            // Parse time components
            var hour = 0
            var minute = 0
            var second = 0
            var nanoseconds = 0

            if timePart.contains(":") {
                // Extended format: HH:MM:SS or HH:MM
                let parts = timePart.split(separator: ":").map(String.init)
                guard parts.count >= 2 else {
                    throw ISO_8601.Date.Error.invalidTime("Expected HH:MM or HH:MM:SS")
                }

                guard let h = Int(parts[0]) else {
                    throw ISO_8601.Date.Error.invalidHour(parts[0])
                }
                guard let m = Int(parts[1]) else {
                    throw ISO_8601.Date.Error.invalidMinute(parts[1])
                }

                hour = h
                minute = m

                if parts.count >= 3 {
                    // Parse seconds and fractional seconds
                    (second, nanoseconds) = try parseFractionalSeconds(parts[2])
                }
            } else {
                // Basic format: HHMMSS or HHMM
                if timePart.count >= 4 {
                    let hourStr = String(timePart.prefix(2))
                    let minuteStr = String(timePart.dropFirst(2).prefix(2))

                    guard let h = Int(hourStr) else {
                        throw ISO_8601.Date.Error.invalidHour(hourStr)
                    }
                    guard let m = Int(minuteStr) else {
                        throw ISO_8601.Date.Error.invalidMinute(minuteStr)
                    }

                    hour = h
                    minute = m

                    if timePart.count >= 6 {
                        // Check for fractional seconds in basic format
                        let remainingPart = String(timePart.dropFirst(4))
                        if remainingPart.contains(".") || remainingPart.contains(",") {
                            (second, nanoseconds) = try parseFractionalSeconds(remainingPart)
                        } else {
                            let secondStr = String(remainingPart.prefix(2))
                            guard let s = Int(secondStr) else {
                                throw ISO_8601.Date.Error.invalidSecond(secondStr)
                            }
                            second = s
                        }
                    }
                } else {
                    throw ISO_8601.Date.Error.invalidTime("Time too short")
                }
            }

            return (hour, minute, second, nanoseconds, timezoneOffset)
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

            return (sec, nano)
        }

        private static func parseTimezoneOffset(_ value: String, positive: Bool) throws -> Int {
            if value.contains(":") {
                // Extended format: HH:MM
                let parts = value.split(separator: ":").map(String.init)
                guard parts.count == 2 else {
                    throw ISO_8601.Date.Error.invalidTimezone(value)
                }

                guard let hours = Int(parts[0]), let minutes = Int(parts[1]) else {
                    throw ISO_8601.Date.Error.invalidTimezone(value)
                }

                let offset = hours * TimeConstants.secondsPerHour + minutes * TimeConstants.secondsPerMinute
                return positive ? offset : -offset
            } else {
                // Basic format: HHMM
                guard value.count == 4 else {
                    throw ISO_8601.Date.Error.invalidTimezone(value)
                }

                let hoursStr = String(value.prefix(2))
                let minutesStr = String(value.dropFirst(2))

                guard let hours = Int(hoursStr), let minutes = Int(minutesStr) else {
                    throw ISO_8601.Date.Error.invalidTimezone(value)
                }

                let offset = hours * TimeConstants.secondsPerHour + minutes * TimeConstants.secondsPerMinute
                return positive ? offset : -offset
            }
        }
    }
}

// MARK: - Codable

extension ISO_8601.DateTime: Codable {
    private enum CodingKeys: String, CodingKey {
        case secondsSinceEpoch
        case nanoseconds
        case timezoneOffsetSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(Int.self, forKey: .secondsSinceEpoch)
        let nanos = try container.decodeIfPresent(Int.self, forKey: .nanoseconds) ?? 0
        let offset = try container.decodeIfPresent(Int.self, forKey: .timezoneOffsetSeconds) ?? 0
        try self.init(secondsSinceEpoch: seconds, nanoseconds: nanos, timezoneOffsetSeconds: offset)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(secondsSinceEpoch, forKey: .secondsSinceEpoch)
        if nanoseconds != 0 {
            try container.encode(nanoseconds, forKey: .nanoseconds)
        }
        try container.encode(timezoneOffsetSeconds, forKey: .timezoneOffsetSeconds)
    }
}

// MARK: - CustomStringConvertible

extension ISO_8601.DateTime: CustomStringConvertible {
    public var description: String {
        Formatter.format(self)
    }
}

// MARK: - Internal Helpers (Calendar Logic from RFC 5322)

extension ISO_8601.DateTime {
    internal static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    // Cached arrays to avoid allocation on every call
    static let daysInCommonYearMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    static let daysInLeapYearMonths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    static func daysInMonths(year: Int) -> [Int] {
        isLeapYear(year) ? daysInLeapYearMonths : daysInCommonYearMonths
    }

    /// Optimized O(1) calculation of year and remaining days from days since epoch
    /// Uses pure arithmetic based on Gregorian calendar structure
    static func yearAndDays(fromDaysSinceEpoch days: Int) -> (year: Int, remainingDays: Int) {
        // Gregorian calendar has a 400-year cycle with exactly 146097 days
        // This cycle contains: 97 leap years and 303 common years
        let cyclesOf400 = days / 146097
        var remainingDays = days % 146097

        // Within each 400-year cycle, 100-year periods vary:
        // - First 3 periods: 36524 days each (24 leap years, 76 common years)
        // - Last period: 36525 days (25 leap years because year x400 is always a leap year)
        // However, since 1970 is 30 years into a cycle, we need special handling

        // For epoch 1970, we're 30 years into the 1600-2000 cycle
        // So the relevant centuries starting from 1970 are: 2000, 2100, 2200, 2300...
        // 2000 is divisible by 400 (leap year), so 1970-2069 has 25 leap years = 36525 days
        // 2100, 2200, 2300 are not divisible by 400, so they have 24 leap years = 36524 days each

        var cyclesOf100: Int
        if remainingDays >= 36525 {  // First century (1970-2070) includes year 2000
            cyclesOf100 = 1
            remainingDays -= 36525
            // Add remaining centuries (each 36524 days)
            let additionalCenturies = min(remainingDays / 36524, 2)  // Max 2 more (to stay within 400-year cycle)
            cyclesOf100 += additionalCenturies
            remainingDays -= additionalCenturies * 36524
        } else {
            cyclesOf100 = 0
        }

        // Within each 100-year period, 4-year periods have 1461 days
        // (1 leap year, 3 common years)
        // We use min(_, 24) to stay within the 100-year boundary
        let cyclesOf4 = min(remainingDays / 1461, 24)
        remainingDays -= cyclesOf4 * 1461

        // Handle remaining 0-3 years, accounting for possible leap year
        var year = 1970 + cyclesOf400 * 400 + cyclesOf100 * 100 + cyclesOf4 * 4

        // Process up to 3 remaining years
        for _ in 0..<3 {
            let daysInYear = isLeapYear(year) ? 366 : 365
            if remainingDays < daysInYear {
                break
            }
            remainingDays -= daysInYear
            year += 1
        }

        return (year, remainingDays)
    }

    internal static func daysSinceEpoch(year: Int, month: Int, day: Int) -> Int {
        // Optimized calculation avoiding year-by-year iteration
        let yearsSince1970 = year - 1970

        // Calculate leap years between 1970 and year (exclusive)
        // Count years divisible by 4, subtract those divisible by 100, add back those divisible by 400
        let leapYears: Int
        if yearsSince1970 > 0 {
            let yearBefore = year - 1
            leapYears = (yearBefore / 4 - 1970 / 4) -
                        (yearBefore / 100 - 1970 / 100) +
                        (yearBefore / 400 - 1970 / 400)
        } else {
            leapYears = 0
        }

        var days = yearsSince1970 * TimeConstants.daysPerCommonYear + leapYears

        // Add days for complete months in current year
        let monthDays = daysInMonths(year: year)
        for m in 0..<(month - 1) {
            days += monthDays[m]
        }

        // Add remaining days
        days += day - 1

        return days
    }

    /// Calculate day of week (0 = Sunday, 6 = Saturday)
    /// Using Zeller's congruence algorithm
    internal static func weekday(year: Int, month: Int, day: Int) -> Int {
        var y = year
        var m = month

        if m < 3 {
            m += 12
            y -= 1
        }

        let q = day
        let K = y % 100
        let J = y / 100

        let h = (q + ((13 * (m + 1)) / 5) + K + (K / 4) + (J / 4) - (2 * J)) % 7

        // Convert from Zeller's (0=Saturday) to our (0=Sunday)
        return (h + 6) % 7
    }
}
