//
//  ISO_8601.WeekDate Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.WeekDate
//

import Testing
import Foundation
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

    @Test
    func `Create week date for all weekdays`() throws {
        for weekday in 1...7 {
            let weekDate = try ISO_8601.WeekDate(weekYear: 2024, week: 1, weekday: weekday)
            #expect(weekDate.weekday == weekday)
        }
    }

    // MARK: - Validation

    @Test
    func `Reject invalid weekday 0`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.WeekDate(weekYear: 2024, week: 1, weekday: 0)
        }
    }

    @Test
    func `Reject invalid weekday 8`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.WeekDate(weekYear: 2024, week: 1, weekday: 8)
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
        let dateTime = weekDate.toDateTime()

        let comp = dateTime.components
        #expect(comp.year == 2024 || comp.year == 2023)  // Week 1 might start in previous year
    }

    @Test
    func `Week date conversion produces correct weekday`() throws {
        let weekDate = try ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 2)
        let dateTime = weekDate.toDateTime()

        #expect(dateTime.isoWeekday == 2)
    }

    // MARK: - Round-trip Conversion

    @Test
    func `Round-trip datetime to week date`() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        let weekDate = original.toWeekDate()
        let converted = weekDate.toDateTime()

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
