//
//  ISO_8601.Parser Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.DateTime.Parser
//

import Testing
import Foundation
@testable import ISO_8601

@Suite
struct `ISO_8601.Parser Tests` {

    // MARK: - Calendar Date Parsing

    @Test
    func `Parse calendar date extended`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-01-15")

        let comp = dt.components
        #expect(comp.year == 2024)
        #expect(comp.month == 1)
        #expect(comp.day == 15)
    }

    @Test
    func `Parse calendar date basic`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("20240115")

        let comp = dt.components
        #expect(comp.year == 2024)
        #expect(comp.month == 1)
        #expect(comp.day == 15)
    }

    // MARK: - Week Date Parsing

    @Test
    func `Parse week date extended`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-W03-1")

        let weekDate = dt.toWeekDate()
        #expect(weekDate.weekYear == 2024)
        #expect(weekDate.week == 3)
        #expect(weekDate.weekday == 1)
    }

    @Test
    func `Parse week date basic`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024W031")

        let weekDate = dt.toWeekDate()
        #expect(weekDate.weekYear == 2024)
        #expect(weekDate.week == 3)
        #expect(weekDate.weekday == 1)
    }

    // MARK: - Ordinal Date Parsing

    @Test
    func `Parse ordinal date extended`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-039")

        let ordinal = dt.toOrdinalDate()
        #expect(ordinal.year == 2024)
        #expect(ordinal.day == 39)
    }

    @Test
    func `Parse ordinal date basic`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024039")

        let ordinal = dt.toOrdinalDate()
        #expect(ordinal.year == 2024)
        #expect(ordinal.day == 39)
    }

    // MARK: - DateTime Parsing

    @Test
    func `Parse datetime with UTC timezone`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-01-15T12:30:00Z")

        let comp = dt.components
        #expect(comp.year == 2024)
        #expect(comp.month == 1)
        #expect(comp.day == 15)
        #expect(comp.hour == 12)
        #expect(comp.minute == 30)
        #expect(comp.second == 0)
        #expect(dt.timezoneOffsetSeconds == 0)
    }

    @Test
    func `Parse datetime basic format with UTC`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("20240115T123000Z")

        let comp = dt.components
        #expect(comp.year == 2024)
        #expect(comp.month == 1)
        #expect(comp.day == 15)
        #expect(comp.hour == 12)
        #expect(comp.minute == 30)
        #expect(comp.second == 0)
    }

    @Test
    func `Parse datetime with positive offset extended`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-01-15T12:30:00+05:30")

        #expect(dt.timezoneOffsetSeconds == 19800)  // 5.5 hours
    }

    @Test
    func `Parse datetime with positive offset basic`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-01-15T12:30:00+0530")

        #expect(dt.timezoneOffsetSeconds == 19800)
    }

    @Test
    func `Parse datetime with negative offset`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-01-15T12:30:00-05:00")

        #expect(dt.timezoneOffsetSeconds == -18000)  // -5 hours
    }

    @Test
    func `Parse datetime without seconds`() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-01-15T12:30Z")

        let comp = dt.components
        #expect(comp.hour == 12)
        #expect(comp.minute == 30)
        #expect(comp.second == 0)
    }

    // MARK: - Round-trip Tests

    @Test
    func `Round-trip calendar date extended`() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 1, day: 15, hour: 12, minute: 30, second: 45)
        let formatted = ISO_8601.DateTime.Formatter.format(original)
        let parsed = try ISO_8601.DateTime.Parser.parse(formatted)

        #expect(original == parsed)
    }

    @Test
    func `Round-trip calendar date basic`() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 1, day: 15, hour: 12, minute: 30, second: 45)
        let formatted = ISO_8601.DateTime.Formatter.format(
            original,
            date: .calendar(extended: false),
            time: .time(extended: false),
            timezone: .utc
        )
        let parsed = try ISO_8601.DateTime.Parser.parse(formatted)

        #expect(original == parsed)
    }

    @Test
    func `Round-trip week date`() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 1, day: 15, hour: 12, minute: 30)
        let formatted = ISO_8601.DateTime.Formatter.format(
            original,
            date: .week(extended: true),
            time: .time(extended: true),
            timezone: .utc
        )
        let parsed = try ISO_8601.DateTime.Parser.parse(formatted)

        #expect(original == parsed)
    }

    @Test
    func `Round-trip ordinal date`() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 2, day: 8, hour: 14, minute: 30)
        let formatted = ISO_8601.DateTime.Formatter.format(
            original,
            date: .ordinal(extended: true),
            time: .time(extended: true),
            timezone: .utc
        )
        let parsed = try ISO_8601.DateTime.Parser.parse(formatted)

        #expect(original == parsed)
    }

    // MARK: - Error Cases

    @Test
    func `Reject invalid date format`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.DateTime.Parser.parse("invalid")
        }
    }

    @Test
    func `Reject invalid month`() throws {
        // Calendar validation delegated to Time - expect Time.Error
        #expect(throws: Time.Error.self) {
            _ = try ISO_8601.DateTime.Parser.parse("2024-13-01")
        }
    }

    @Test
    func `Reject invalid day`() throws {
        // Calendar validation delegated to Time - expect Time.Error
        #expect(throws: Time.Error.self) {
            _ = try ISO_8601.DateTime.Parser.parse("2024-02-30")
        }
    }

    @Test
    func `Reject empty string`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.DateTime.Parser.parse("")
        }
    }
}
