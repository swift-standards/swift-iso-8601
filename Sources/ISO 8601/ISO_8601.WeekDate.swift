//
//  ISO_8601.WeekDate.swift
//  swift-iso-8601
//
//  ISO 8601 Week Date representation
//

import StandardTime

extension ISO_8601 {
    /// ISO 8601 Week Date representation: YYYY-Www-D
    ///
    /// Week dates provide an alternative calendar representation based on weeks.
    /// - Week 1 is the first week containing the first Thursday of the year
    /// - Weeks always start on Monday (weekday=1) and end on Sunday (weekday=7)
    /// - The week-year may differ from the calendar year at year boundaries
    ///
    /// ## Format
    /// - Extended: `2024-W03-2` (Year 2024, Week 3, Tuesday)
    /// - Basic: `2024W032`
    ///
    /// ## Example
    /// ```swift
    /// let weekDate = ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 2)
    /// let dateTime = weekDate.toDateTime()
    /// ```
    public struct WeekDate: Sendable, Equatable, Hashable {
        /// ISO week-year (may differ from calendar year at boundaries)
        public let weekYear: Int

        /// ISO week number (1-53)
        public let week: Int

        /// ISO weekday (1=Monday, 2=Tuesday, ..., 7=Sunday)
        public let weekday: Int

        /// Create a week date with validation
        ///
        /// - Parameters:
        ///   - weekYear: ISO week-year
        ///   - week: Week number (1-53, validated for the year)
        ///   - weekday: Weekday (1=Monday, 7=Sunday)
        /// - Throws: `ISO_8601.Date.Error` if any component is out of valid range
        public init(weekYear: Int, week: Int, weekday: Int) throws {
            // Validate weekday
            guard (1...7).contains(weekday) else {
                throw ISO_8601.Date.Error.weekdayOutOfRange(weekday)
            }

            // Validate week number (must be valid for the year)
            let maxWeeks = ISO_8601.DateTime.weeksInYear(weekYear)
            guard (1...maxWeeks).contains(week) else {
                throw ISO_8601.Date.Error.weekNumberOutOfRange(week, year: weekYear)
            }

            self.weekYear = weekYear
            self.week = week
            self.weekday = weekday
        }

        /// Create a week date without validation (internal use)
        internal init(uncheckedWeekYear weekYear: Int, week: Int, weekday: Int) {
            self.weekYear = weekYear
            self.week = week
            self.weekday = weekday
        }

        /// Initialize week date from calendar date (DateTime)
        ///
        /// Converts a DateTime to its week date representation.
        public init(_ dateTime: ISO_8601.DateTime) {
            self.init(
                uncheckedWeekYear: dateTime.isoWeekYear,
                week: dateTime.isoWeek,
                weekday: dateTime.isoWeekday
            )
        }
    }
}

// MARK: - DateTime Conversion

extension ISO_8601.DateTime {
    /// Initialize DateTime from week date
    ///
    /// Calculates the calendar date corresponding to a week date.
    /// The time components will be 00:00:00 UTC.
    public init(_ weekDate: ISO_8601.WeekDate) {
        // Find January 4th of the week-year (which is always in week 1)
        let jan4Time = try! StandardTime.Time(
            year: weekDate.weekYear,
            month: 1,
            day: 4,
            hour: 0,
            minute: 0,
            second: 0
        )
        let jan4DaysSinceEpoch =
            jan4Time.secondsSinceEpoch
            / StandardTime.Time.Calendar.Gregorian.TimeConstants.secondsPerDay

        // Find the weekday of January 4th
        let jan4WeekdayEnum = jan4Time.weekday
        let jan4Weekday: Int
        switch jan4WeekdayEnum {
        case .sunday: jan4Weekday = 0
        case .monday: jan4Weekday = 1
        case .tuesday: jan4Weekday = 2
        case .wednesday: jan4Weekday = 3
        case .thursday: jan4Weekday = 4
        case .friday: jan4Weekday = 5
        case .saturday: jan4Weekday = 6
        }
        let jan4ISOWeekday = jan4Weekday == 0 ? 7 : jan4Weekday

        // Find the Monday of week 1
        let mondayOfWeek1 = jan4DaysSinceEpoch - (jan4ISOWeekday - 1)

        // Calculate the date
        // Week 1 starts at mondayOfWeek1
        // Our date is (week - 1) weeks later, plus (weekday - 1) days
        let daysSinceEpoch = mondayOfWeek1 + ((weekDate.week - 1) * 7) + (weekDate.weekday - 1)

        let totalSeconds =
            daysSinceEpoch * StandardTime.Time.Calendar.Gregorian.TimeConstants.secondsPerDay

        self.init(
            __unchecked: (),
            secondsEpoch: totalSeconds,
            timezoneOffsetSeconds: 0
        )
    }
}
