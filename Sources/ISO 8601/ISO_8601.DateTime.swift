import Byte
import Byte_Standard_Library_Integration
import Cursor
import Cursor_Standard_Library_Integration
import Parser
import Standard_Library_Extensions
public import Time

extension ISO_8601 {

    public typealias Date = DateTime

    public struct DateTime: Sendable, Equatable, Hashable, Comparable {

        public let time: Time.Time

        public let timezoneOffset: Time.Time.Timezone.Offset

        public init(
            time: Time.Time,
            timezoneOffset: Time.Time.Timezone.Offset = .utc
        ) {
            self.time = time
            self.timezoneOffset = timezoneOffset
        }
    }
}

extension ISO_8601.DateTime {

    public init(
        secondsSinceEpoch: Int = 0,
        nanoseconds: Int = 0,
        timezoneOffsetSeconds: Int = 0
    ) throws(ISO_8601.Date.Error) {
        guard (0..<1_000_000_000).contains(nanoseconds) else {
            throw ISO_8601.Date.Error.invalidFractionalSecond(String(nanoseconds))
        }

        let millisecond = nanoseconds / 1_000_000
        let remaining = nanoseconds % 1_000_000
        let microsecond = remaining / 1000
        let nanosecond = remaining % 1000

        let baseTime = Time.Time(secondsSinceEpoch: secondsSinceEpoch)

        let millisecondValue: Time.Time.Millisecond
        let microsecondValue: Time.Time.Microsecond
        let nanosecondValue: Time.Time.Nanosecond
        do {
            millisecondValue = try Time.Time.Millisecond(millisecond)
            microsecondValue = try Time.Time.Microsecond(microsecond)
            nanosecondValue = try Time.Time.Nanosecond(nanosecond)
        } catch {
            fatalError(
                "ISO_8601.DateTime: sub-second component derived from validated nanoseconds was out of range — \(error)"
            )
        }
        let time = Time.Time(
            year: baseTime.year,
            month: baseTime.month,
            day: baseTime.day,
            hour: baseTime.hour,
            minute: baseTime.minute,
            second: baseTime.second,
            millisecond: millisecondValue,
            microsecond: microsecondValue,
            nanosecond: nanosecondValue
        )
        self.init(
            time: time,
            timezoneOffset: Time.Time.Timezone.Offset(seconds: timezoneOffsetSeconds)
        )
    }

    internal init(
        __unchecked: Void = (),
        secondsEpoch: Int,
        nanoseconds: Int = 0,
        timezoneOffsetSeconds: Int = 0
    ) {

        let millisecond = nanoseconds / 1_000_000
        let remaining = nanoseconds % 1_000_000
        let microsecond = remaining / 1000
        let nanosecond = remaining % 1000

        let baseTime = Time.Time(secondsSinceEpoch: secondsEpoch)

        let millisecondValue: Time.Time.Millisecond
        let microsecondValue: Time.Time.Microsecond
        let nanosecondValue: Time.Time.Nanosecond
        do {
            millisecondValue = try Time.Time.Millisecond(millisecond)
            microsecondValue = try Time.Time.Microsecond(microsecond)
            nanosecondValue = try Time.Time.Nanosecond(nanosecond)
        } catch {
            fatalError(
                "ISO_8601.DateTime: sub-second component derived from nanoseconds was out of range — \(error)"
            )
        }
        let time = Time.Time(
            year: baseTime.year,
            month: baseTime.month,
            day: baseTime.day,
            hour: baseTime.hour,
            minute: baseTime.minute,
            second: baseTime.second,
            millisecond: millisecondValue,
            microsecond: microsecondValue,
            nanosecond: nanosecondValue
        )
        self.init(
            time: time,
            timezoneOffset: Time.Time.Timezone.Offset(seconds: timezoneOffsetSeconds)
        )
    }
}

extension ISO_8601.DateTime {

    public var nanoseconds: Int {
        time.totalNanoseconds
    }
}

extension ISO_8601.DateTime {

    public var epoch: Epoch {
        Epoch(dateTime: self)
    }

    public var timezone: Timezone {
        Timezone(dateTime: self)
    }
}

extension ISO_8601.DateTime {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.epoch.seconds != rhs.epoch.seconds {
            return lhs.epoch.seconds < rhs.epoch.seconds
        }
        return lhs.nanoseconds < rhs.nanoseconds
    }
}

extension ISO_8601.DateTime {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.epoch.seconds == rhs.epoch.seconds && lhs.nanoseconds == rhs.nanoseconds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(epoch.seconds)
        hasher.combine(nanoseconds)
    }
}

extension ISO_8601.DateTime {

    public init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        nanoseconds: Int = 0,
        timezoneOffsetSeconds: Int = 0
    ) throws(ISO_8601.Date.Error) {

        let millisecond = nanoseconds / 1_000_000
        let remaining = nanoseconds % 1_000_000
        let microsecond = remaining / 1000
        let nanosecond = remaining % 1000

        let time: Time.Time
        do throws(Time.Time.Error) {
            time = try Time.Time(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second,
                millisecond: millisecond,
                microsecond: microsecond,
                nanosecond: nanosecond
            )
        } catch {
            throw .invalidComponents(error)
        }

        self.init(
            time: time,
            timezoneOffset: Time.Time.Timezone.Offset(seconds: timezoneOffsetSeconds)
        )
    }
}

extension ISO_8601.DateTime {

    public var components: ISO_8601.Date.Components {
        .init(self)
    }
}

extension ISO_8601.DateTime {

    public var isoWeekday: Int {
        let comp = components

        return comp.weekday == 0 ? 7 : comp.weekday
    }

    public var ordinalDay: Int {
        let comp = components
        let monthDays = Time.Time.Calendar.Gregorian.daysInMonths(year: comp.year)
        let precedingMonthDays = monthDays[0..<(comp.month - 1)].reduce(0, +)
        return comp.day + precedingMonthDays
    }

    public var isoWeekYear: Int {
        let comp = components
        let week = isoWeek

        if comp.month == 12 && week == 1 {
            return comp.year + 1
        }

        if comp.month == 1 && week >= 52 {
            return comp.year - 1
        }

        return comp.year
    }

    public var isoWeek: Int {
        let comp = components

        let isoDay = isoWeekday
        let daysSinceMonday = isoDay - 1

        let currentTime: Time.Time
        do {
            currentTime = try Time.Time(
                year: comp.year,
                month: comp.month,
                day: comp.day,
                hour: 0,
                minute: 0,
                second: 0
            )
        } catch {
            fatalError(
                "ISO_8601.DateTime.isoWeek: components of a valid DateTime failed to reconstruct — \(error)"
            )
        }
        let mondayOfWeek =
            currentTime.secondsSinceEpoch
            / Time.Time.Calendar.Gregorian.TimeConstants.secondsPerDay
            - daysSinceMonday

        let jan4Time: Time.Time
        do {
            jan4Time = try Time.Time(
                year: comp.year,
                month: 1,
                day: 4,
                hour: 0,
                minute: 0,
                second: 0
            )
        } catch {
            fatalError("ISO_8601.DateTime.isoWeek: January 4th failed to construct — \(error)")
        }
        let jan4 =
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
        let jan4DaysSinceMonday = jan4ISOWeekday - 1
        let mondayOfWeek1 = jan4 - jan4DaysSinceMonday

        let weekNumber = ((mondayOfWeek - mondayOfWeek1) / 7) + 1

        if weekNumber < 1 {

            return Self.weeksInYear(comp.year - 1)
        } else if weekNumber > Self.weeksInYear(comp.year) {

            return 1
        }

        return weekNumber
    }

    internal static func weeksInYear(_ year: Int) -> Int {

        let jan1Time: Time.Time
        do {
            jan1Time = try Time.Time(
                year: year,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0
            )
        } catch {
            fatalError("ISO_8601.DateTime.weeksInYear: January 1st failed to construct — \(error)")
        }
        let jan1WeekdayEnum = jan1Time.weekday
        let jan1Weekday: Int
        switch jan1WeekdayEnum {
        case .sunday: jan1Weekday = 0
        case .monday: jan1Weekday = 1
        case .tuesday: jan1Weekday = 2
        case .wednesday: jan1Weekday = 3
        case .thursday: jan1Weekday = 4
        case .friday: jan1Weekday = 5
        case .saturday: jan1Weekday = 6
        }
        let jan1ISOWeekday = jan1Weekday == 0 ? 7 : jan1Weekday

        if jan1ISOWeekday == 4 {
            return 53
        }

        if jan1ISOWeekday == 3 && Time.Time.Calendar.Gregorian.isLeapYear(year) {
            return 53
        }

        return 52
    }
}

extension ISO_8601.DateTime: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(Int.self, forKey: .secondsSinceEpoch)
        let nanos = try container.decodeIfPresent(Int.self, forKey: .nanoseconds) ?? 0
        let offset = try container.decodeIfPresent(Int.self, forKey: .timezoneOffsetSeconds) ?? 0
        try self.init(secondsSinceEpoch: seconds, nanoseconds: nanos, timezoneOffsetSeconds: offset)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(epoch.seconds, forKey: .secondsSinceEpoch)
        if nanoseconds != 0 {
            try container.encode(nanoseconds, forKey: .nanoseconds)
        }
        try container.encode(timezone.offsetSeconds, forKey: .timezoneOffsetSeconds)
    }
}

extension ISO_8601.DateTime: CustomStringConvertible {
    public var description: String {
        Formatter.format(self)
    }
}

extension ISO_8601.DateTime {

    public init(_ string: String) throws(ISO_8601.DateTime.Parser.Error) {
        var input = [Byte](utf8: string)[...]
        let value = try ISO_8601.DateTime.Parser<ArraySlice<Byte>>().parse(&input)
        guard input.isEmpty else { throw .unexpectedTrailingInput }
        self = value
    }
}
