//
//  ISO_8601.DateTime Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.DateTime including creation, formatting, and parsing
//

import Foundation
import StandardTime
import Testing

@testable import ISO_8601

@Suite
struct `ISO_8601.DateTime Tests` {

    // MARK: - Creation from Epoch

    @Test
    func `Create from seconds since epoch`() throws {
        let dateTime = try ISO_8601.DateTime(secondsSinceEpoch: 1_609_459_200)
        #expect(dateTime.secondsSinceEpoch == 1_609_459_200)
        #expect(dateTime.timezoneOffsetSeconds == 0)
    }

    @Test
    func `Create from epoch with timezone offset`() throws {
        let dateTime = try ISO_8601.DateTime(
            secondsSinceEpoch: 1_609_459_200,
            timezoneOffsetSeconds: 3600  // +01:00
        )
        #expect(dateTime.secondsSinceEpoch == 1_609_459_200)
        #expect(dateTime.timezoneOffsetSeconds == 3600)
    }

    // MARK: - Creation from Components

    @Test
    func `Create from date components`() throws {
        let dateTime = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            second: 45
        )

        let components = dateTime.components
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)
        #expect(components.hour == 12)
        #expect(components.minute == 30)
        #expect(components.second == 45)
    }

    @Test
    func `Create from components with timezone offset`() throws {
        let dateTime = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            timezoneOffsetSeconds: 3600
        )

        #expect(dateTime.timezoneOffsetSeconds == 3600)
    }

    // MARK: - Components Extraction

    @Test
    func `Extract components from UTC datetime`() throws {
        let dateTime = try ISO_8601.DateTime(
            year: 2021,
            month: 1,
            day: 1,
            hour: 0,
            minute: 0,
            second: 0
        )

        let components = dateTime.components
        #expect(components.year == 2021)
        #expect(components.month == 1)
        #expect(components.day == 1)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test
    func `Components reflect timezone offset`() throws {
        // Create datetime at midnight UTC
        let utcDateTime = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 1,
            hour: 0,
            minute: 0,
            timezoneOffsetSeconds: 0
        )

        // Same moment but displayed in +03:00 timezone
        let offsetDateTime = try ISO_8601.DateTime(
            secondsSinceEpoch: utcDateTime.secondsSinceEpoch,
            timezoneOffsetSeconds: 10800  // +03:00
        )

        let components = offsetDateTime.components
        // Should show 03:00 local time
        #expect(components.hour == 3)
    }

    // MARK: - ISO Weekday

    @Test
    func `ISO weekday Monday is 1`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 1, day: 1)  // Monday
        #expect(dateTime.isoWeekday == 1)
    }

    @Test
    func `ISO weekday Sunday is 7`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 1, day: 7)  // Sunday
        #expect(dateTime.isoWeekday == 7)
    }

    // MARK: - Ordinal Day

    @Test
    func `Ordinal day for January 1`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 1, day: 1)
        #expect(dateTime.ordinalDay == 1)
    }

    @Test
    func `Ordinal day for February 8`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 2, day: 8)
        #expect(dateTime.ordinalDay == 39)  // 31 days in Jan + 8
    }

    @Test
    func `Ordinal day for December 31 in common year`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2023, month: 12, day: 31)
        #expect(dateTime.ordinalDay == 365)
    }

    @Test
    func `Ordinal day for December 31 in leap year`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 12, day: 31)
        #expect(dateTime.ordinalDay == 366)
    }

    // MARK: - ISO Week Number

    @Test
    func `Week number for January 4 is always 1`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 1, day: 4)
        #expect(dateTime.isoWeek == 1)
    }

    @Test
    func `Week number increments correctly`() throws {
        let week2 = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        #expect(week2.isoWeek == 3)
    }

    // MARK: - ISO Week Year

    @Test
    func `Week year matches calendar year for mid-year dates`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 6, day: 15)
        #expect(dateTime.isoWeekYear == 2024)
    }

    // MARK: - Conversions

    @Test
    func `Convert to week date`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        let weekDate = ISO_8601.WeekDate(dateTime)

        #expect(weekDate.weekYear == 2024)
        #expect(weekDate.week > 0)
        #expect(weekDate.weekday >= 1 && weekDate.weekday <= 7)
    }

    @Test
    func `Convert to ordinal date`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 2, day: 8)
        let ordinal = ISO_8601.OrdinalDate(dateTime)

        #expect(ordinal.year == 2024)
        #expect(ordinal.day == 39)
    }

    // MARK: - Equality and Comparison

    @Test
    func `Equal datetimes have same epoch`() throws {
        let dt1 = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        let dt2 = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)

        #expect(dt1 == dt2)
    }

    @Test
    func `Timezone offset does not affect equality`() throws {
        let utc = try ISO_8601.DateTime(year: 2024, month: 1, day: 1, hour: 12)
        let offset = try ISO_8601.DateTime(
            secondsSinceEpoch: utc.secondsSinceEpoch,
            timezoneOffsetSeconds: 3600
        )

        #expect(utc == offset)
    }

    @Test
    func `DateTime comparison works`() throws {
        let earlier = try ISO_8601.DateTime(year: 2024, month: 1, day: 1)
        let later = try ISO_8601.DateTime(year: 2024, month: 1, day: 2)

        #expect(earlier < later)
        #expect(later > earlier)
    }

    // MARK: - Validation

    @Test
    func `Rejects invalid month`() throws {
        // Calendar validation delegated to Time - expect Time.Error
        #expect(throws: Time.Error.monthOutOfRange(13)) {
            _ = try ISO_8601.DateTime(year: 2024, month: 13, day: 1)
        }
    }

    @Test
    func `Rejects invalid day`() throws {
        // Calendar validation delegated to Time - expect Time.Error
        #expect(throws: Time.Error.self) {
            _ = try ISO_8601.DateTime(year: 2024, month: 2, day: 30)
        }
    }

    @Test
    func `Rejects invalid hour`() throws {
        // Calendar validation delegated to Time - expect Time.Error
        #expect(throws: Time.Error.self) {
            _ = try ISO_8601.DateTime(year: 2024, month: 1, day: 1, hour: 24)
        }
    }

    @Test
    func `Accepts February 29 in leap year`() throws {
        let dateTime = try ISO_8601.DateTime(year: 2024, month: 2, day: 29)
        #expect(dateTime.components.day == 29)
    }

    @Test
    func `Rejects February 29 in common year`() throws {
        // Calendar validation delegated to Time - expect Time.Error
        #expect(throws: Time.Error.self) {
            _ = try ISO_8601.DateTime(year: 2023, month: 2, day: 29)
        }
    }
}
