//
//  ISO_8601.OrdinalDate.swift
//  swift-iso-8601
//
//  ISO 8601 Ordinal Date representation
//

import StandardTime

extension ISO_8601 {
    /// ISO 8601 Ordinal Date representation: YYYY-DDD
    ///
    /// Ordinal dates represent a date as a year and day-of-year number.
    /// - Day 1 is January 1st
    /// - Day 365 is December 31st (or day 366 in leap years)
    ///
    /// ## Format
    /// - Extended: `2024-039` (39th day of 2024)
    /// - Basic: `2024039`
    ///
    /// ## Example
    /// ```swift
    /// let ordinal = ISO_8601.OrdinalDate(year: 2024, day: 39)
    /// let dateTime = ISO_8601.DateTime(ordinal)
    /// // February 8, 2024
    /// ```
    public struct OrdinalDate: Sendable, Equatable, Hashable {
        /// Calendar year
        public let year: Int

        /// Ordinal day of year (1-365 or 1-366 in leap years)
        public let day: Int

        /// Create an ordinal date with validation
        ///
        /// - Parameters:
        ///   - year: Calendar year
        ///   - day: Day of year (1-365 or 1-366 for leap years)
        /// - Throws: `ISO_8601.Date.Error` if day is out of valid range for the year
        public init(year: Int, day: Int) throws {
            let maxDay = StandardTime.Time.Calendar.Gregorian.isLeapYear(year) ? 366 : 365
            guard (1...maxDay).contains(day) else {
                throw ISO_8601.Date.Error.ordinalDayOutOfRange(day, year: year)
            }

            self.year = year
            self.day = day
        }

        /// Create an ordinal date without validation (internal use)
        internal init(uncheckedYear year: Int, day: Int) {
            self.year = year
            self.day = day
        }

        /// Initialize ordinal date from calendar date (DateTime)
        ///
        /// Converts a DateTime to its ordinal date representation.
        public init(_ dateTime: ISO_8601.DateTime) {
            let comp = dateTime.components
            self.init(
                uncheckedYear: comp.year,
                day: dateTime.ordinalDay
            )
        }
    }
}

// MARK: - DateTime Conversion

extension ISO_8601.DateTime {
    /// Initialize DateTime from ordinal date
    ///
    /// Calculates the month and day-of-month for an ordinal day.
    /// The time components will be 00:00:00 UTC.
    public init(_ ordinalDate: ISO_8601.OrdinalDate) {
        // Calculate month and day from ordinal day
        let monthDays = StandardTime.Time.Calendar.Gregorian.daysInMonths(year: ordinalDate.year)
        var remainingDays = ordinalDate.day - 1  // 0-indexed for calculation
        var month = 1

        for daysInMonth in monthDays {
            if remainingDays < daysInMonth {
                break
            }
            remainingDays -= daysInMonth
            month += 1
        }

        let dayOfMonth = remainingDays + 1

        // Create DateTime (won't throw because ordinal day was validated)
        self = try! ISO_8601.DateTime(
            year: ordinalDate.year,
            month: month,
            day: dayOfMonth,
            hour: 0,
            minute: 0,
            second: 0,
            timezoneOffsetSeconds: 0
        )
    }
}
