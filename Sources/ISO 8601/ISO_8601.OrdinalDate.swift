import Time

extension ISO_8601 {

    public struct OrdinalDate: Sendable, Equatable, Hashable {

        public let year: Int

        public let day: Int

        public init(year: Int, day: Int) throws(ISO_8601.Date.Error) {
            let maxDay = Time.Time.Calendar.Gregorian.isLeapYear(year) ? 366 : 365
            guard (1...maxDay).contains(day) else {
                throw ISO_8601.Date.Error.ordinalDayOutOfRange(day, year: year)
            }

            self.year = year
            self.day = day
        }

        internal init(uncheckedYear year: Int, day: Int) {
            self.year = year
            self.day = day
        }

        public init(_ dateTime: ISO_8601.DateTime) {
            let comp = dateTime.components
            self.init(
                uncheckedYear: comp.year,
                day: dateTime.ordinalDay
            )
        }
    }
}

extension ISO_8601.DateTime {

    public init(_ ordinalDate: ISO_8601.OrdinalDate) {

        let monthDays = Time.Time.Calendar.Gregorian.daysInMonths(year: ordinalDate.year)
        var remainingDays = ordinalDate.day - 1
        var month = 1

        for daysInMonth in monthDays {
            if remainingDays < daysInMonth {
                break
            }
            remainingDays -= daysInMonth
            month += 1
        }

        let dayOfMonth = remainingDays + 1

        do {
            self = try ISO_8601.DateTime(
                year: ordinalDate.year,
                month: month,
                day: dayOfMonth,
                hour: 0,
                minute: 0,
                second: 0,
                timezoneOffsetSeconds: 0
            )
        } catch {
            fatalError(
                "ISO_8601.DateTime.init(_:OrdinalDate): month/day derived from a validated ordinal day was out of range — \(error)"
            )
        }
    }
}
