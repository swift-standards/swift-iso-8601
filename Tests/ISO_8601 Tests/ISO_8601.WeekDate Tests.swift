//
//  ISO_8601.WeekDate Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.WeekDate
//

import Foundation
import Testing

@testable import ISO_8601

@Suite
struct `ISO_8601.WeekDate Tests` {

    // MARK: - Creation

    @Test
    func `Create week date`() throws {
        let weekDate = try ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 1)

        #expect(weekDate.weekYear == 2024)
        #expect(weekDate.week == 3)
        #expect(weekDate.weekday == 1)
    }

    @Test(arguments: [1, 2, 3, 4, 5, 6, 7])
    func `Create week date for all weekdays`(weekday: Int) throws {
        let weekDate = try ISO_8601.WeekDate(weekYear: 2024, week: 1, weekday: weekday)
        #expect(weekDate.weekday == weekday)
    }

    // MARK: - Validation

    @Test(arguments: [0, 8, -1, 10])
    func `Reject invalid weekday`(weekday: Int) throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.WeekDate(weekYear: 2024, week: 1, weekday: weekday)
        }
    }

    @Test
    func `Reject invalid week 0`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.WeekDate(weekYear: 2024, week: 0, weekday: 1)
        }
    }

    @Test
    func `Reject week 53 in year with only 52 weeks`() throws {
        // 2023 has only 52 weeks
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.WeekDate(weekYear: 2023, week: 53, weekday: 1)
        }
    }

    // MARK: - Conversion to DateTime

    @Test
    func `Convert week date to datetime`() throws {
        let weekDate = try ISO_8601.WeekDate(weekYear: 2024, week: 1, weekday: 1)
        let dateTime = ISO_8601.DateTime(weekDate)

        let comp = dateTime.components
        #expect(comp.year == 2024 || comp.year == 2023)  // Week 1 might start in previous year
    }

    @Test
    func `Week date conversion produces correct weekday`() throws {
        let weekDate = try ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 2)
        let dateTime = ISO_8601.DateTime(weekDate)

        #expect(dateTime.isoWeekday == 2)
    }

    // MARK: - Round-trip Conversion

    @Test
    func `Round-trip datetime to week date`() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        let weekDate = ISO_8601.WeekDate(original)
        let converted = ISO_8601.DateTime(weekDate)

        // Should be the same date
        #expect(original.components.year == converted.components.year)
        #expect(original.components.month == converted.components.month)
        #expect(original.components.day == converted.components.day)
    }

    // MARK: - Equality

    @Test
    func `Week dates with same values are equal`() throws {
        let wd1 = try ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 1)
        let wd2 = try ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 1)

        #expect(wd1 == wd2)
    }

    @Test
    func `Week dates with different values are not equal`() throws {
        let wd1 = try ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 1)
        let wd2 = try ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 2)

        #expect(wd1 != wd2)
    }
}
