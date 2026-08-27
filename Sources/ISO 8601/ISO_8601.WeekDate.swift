import Time

extension ISO_8601 {

    public struct WeekDate: Sendable, Equatable, Hashable {

        public let weekYear: Int

        public let week: Int

        public let weekday: Int

        public init(weekYear: Int, week: Int, weekday: Int) throws(ISO_8601.Date.Error) {

            guard (1...7).contains(weekday) else {
                throw ISO_8601.Date.Error.weekdayOutOfRange(weekday)
            }

            let maxWeeks = ISO_8601.DateTime.weeksInYear(weekYear)
            guard (1...maxWeeks).contains(week) else {
                throw ISO_8601.Date.Error.weekNumberOutOfRange(week, year: weekYear)
            }

            self.weekYear = weekYear
            self.week = week
            self.weekday = weekday
        }

        internal init(uncheckedWeekYear weekYear: Int, week: Int, weekday: Int) {
            self.weekYear = weekYear
            self.week = week
            self.weekday = weekday
        }

        public init(_ dateTime: ISO_8601.DateTime) {
            self.init(
                uncheckedWeekYear: dateTime.isoWeekYear,
                week: dateTime.isoWeek,
                weekday: dateTime.isoWeekday
            )
        }
    }
}

extension ISO_8601.DateTime {

    public init(_ weekDate: ISO_8601.WeekDate) {

        let jan4Time: Time.Time
        do {
            jan4Time = try Time.Time(
                year: weekDate.weekYear,
                month: 1,
                day: 4,
                hour: 0,
                minute: 0,
                second: 0
            )
        } catch {
            fatalError(
                "ISO_8601.DateTime.init(_:WeekDate): January 4th failed to construct — \(error)"
            )
        }
        let jan4DaysSinceEpoch =
            jan4Time.secondsSinceEpoch
            / Time.Time.Calendar.Gregorian.TimeConstants.secondsPerDay

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

        let mondayOfWeek1 = jan4DaysSinceEpoch - (jan4ISOWeekday - 1)

        let daysSinceEpoch = mondayOfWeek1 + ((weekDate.week - 1) * 7) + (weekDate.weekday - 1)

        let totalSeconds =
            daysSinceEpoch * Time.Time.Calendar.Gregorian.TimeConstants.secondsPerDay

        self.init(

            __unchecked: (),
            secondsEpoch: totalSeconds,
            timezoneOffsetSeconds: 0
        )
    }
}
