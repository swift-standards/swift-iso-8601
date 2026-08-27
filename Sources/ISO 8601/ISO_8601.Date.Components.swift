import Time

extension ISO_8601.Date {

    public struct Components: Sendable, Equatable {
        public let year: Int
        public let month: Int
        public let day: Int
        public let hour: Int
        public let minute: Int
        public let second: Int
        public let nanoseconds: Int
        public let weekday: Int

        public init(
            year: Int,
            month: Int,
            day: Int,
            hour: Int,
            minute: Int,
            second: Int,
            nanoseconds: Int = 0
        ) throws(ISO_8601.Date.Error) {

            guard (1...12).contains(month) else {
                throw ISO_8601.Date.Error.monthOutOfRange(month)
            }

            let maxDay = Self.daysInMonth(month, year: year)
            guard (1...maxDay).contains(day) else {
                throw ISO_8601.Date.Error.dayOutOfRange(day, month: month, year: year)
            }

            guard (0...23).contains(hour) else {
                throw ISO_8601.Date.Error.hourOutOfRange(hour)
            }

            guard (0...59).contains(minute) else {
                throw ISO_8601.Date.Error.minuteOutOfRange(minute)
            }

            guard (0...60).contains(second) else {
                throw ISO_8601.Date.Error.secondOutOfRange(second)
            }

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

            self.weekday = Self.computeWeekday(year: year, month: month, day: day)
        }
    }
}

extension ISO_8601.Date.Components {

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

    private static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    private static func computeWeekday(year: Int, month: Int, day: Int) -> Int {

        let m = month < 3 ? month + 12 : month
        let y = month < 3 ? year - 1 : year
        let q = day
        let k = y % 100
        let j = y / 100

        let h = (q + ((13 * (m + 1)) / 5) + k + (k / 4) + (j / 4) - (2 * j)) % 7

        return (h + 6) % 7
    }
}

extension ISO_8601.Date.Components {
    public init(_ dateTime: ISO_8601.Date) {

        let localTime = Time.Time(
            secondsSinceEpoch: dateTime.epoch.seconds + dateTime.timezone.offsetSeconds
        )

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

        self = ISO_8601.Date.Components(
            uncheckedYear: localTime.year.rawValue,
            month: localTime.month.rawValue,
            day: localTime.day.rawValue,
            hour: localTime.hour.value,
            minute: localTime.minute.value,
            second: localTime.second.value,
            nanoseconds: dateTime.nanoseconds,
            weekday: weekdayNumber
        )
    }
}
