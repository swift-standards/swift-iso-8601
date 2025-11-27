//
//  ISO_8601.Date.Error.swift
//  swift-iso-8601
//
//  Error types for ISO 8601 date-time operations
//

extension ISO_8601.Date {
    /// Errors that can occur when parsing ISO 8601 date-time strings or creating date components
    public enum Error: Swift.Error, Sendable, Equatable {
        // Parsing errors
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

        // ISO 8601 specific parsing errors
        case invalidWeekNumber(String)
        case invalidWeekday(String)
        case invalidOrdinalDay(String)

        // Component validation errors
        case monthOutOfRange(Int)  // Must be 1-12
        case dayOutOfRange(Int, month: Int, year: Int)  // Must be valid for month/year
        case hourOutOfRange(Int)  // Must be 0-23
        case minuteOutOfRange(Int)  // Must be 0-59
        case secondOutOfRange(Int)  // Must be 0-60 (allowing leap second)

        // ISO 8601 specific validation errors
        case weekNumberOutOfRange(Int, year: Int)  // Must be 1-53 and valid for year
        case weekdayOutOfRange(Int)  // Must be 1-7 (Monday=1, Sunday=7)
        case ordinalDayOutOfRange(Int, year: Int)  // Must be 1-365 (366 in leap years)
    }
}
