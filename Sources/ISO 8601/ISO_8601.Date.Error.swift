public import Time

extension ISO_8601.Date {

    public enum Error: Swift.Error, Sendable, Equatable {

        case invalidFormat(String)
        case invalidYear(String)
        case invalidMonth(String)
        case invalidDay(String)
        case invalidTime(String)
        case invalidHour(String)
        case invalidMinute(String)
        case invalidSecond(String)
        case invalidFractionalSecond(String)
        case invalidTimezone(String)

        case invalidWeekNumber(String)
        case invalidWeekday(String)
        case invalidOrdinalDay(String)

        case monthOutOfRange(Int)
        case dayOutOfRange(Int, month: Int, year: Int)
        case hourOutOfRange(Int)
        case minuteOutOfRange(Int)
        case secondOutOfRange(Int)

        case weekNumberOutOfRange(Int, year: Int)
        case weekdayOutOfRange(Int)
        case ordinalDayOutOfRange(Int, year: Int)

        case invalidComponents(Time.Time.Error)
    }
}
