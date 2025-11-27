//
//  ISO_8601.Formatter Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.DateTime.Formatter
//

import Foundation
import Testing

@testable import ISO_8601

@Suite
struct `ISO_8601.Formatter Tests` {

    // MARK: - Calendar Date Formatting

    @Test
    func `Format calendar date extended`() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: true),
            time: .none
        )

        #expect(formatted == "2024-01-15")
    }

    @Test
    func `Format calendar date basic`() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: false),
            time: .none
        )

        #expect(formatted == "20240115")
    }

    // MARK: - Week Date Formatting

    @Test
    func `Format week date extended`() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .week(extended: true),
            time: .none
        )

        // Week 3, Monday (Jan 15, 2024)
        #expect(formatted.hasPrefix("2024-W"))
    }

    @Test
    func `Format week date basic`() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 1, day: 15)
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .week(extended: false),
            time: .none
        )

        #expect(formatted.hasPrefix("2024W"))
        #expect(!formatted.contains("-"))
    }

    // MARK: - Ordinal Date Formatting

    @Test
    func `Format ordinal date extended`() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 2, day: 8)
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .ordinal(extended: true),
            time: .none
        )

        #expect(formatted == "2024-039")
    }

    @Test
    func `Format ordinal date basic`() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 2, day: 8)
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .ordinal(extended: false),
            time: .none
        )

        #expect(formatted == "2024039")
    }

    // MARK: - Time Formatting

    @Test
    func `Format time extended`() throws {
        let dt = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            second: 45
        )
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: true),
            time: .time(extended: true),
            timezone: .none
        )

        #expect(formatted == "2024-01-15T12:30:45")
    }

    @Test
    func `Format time basic`() throws {
        let dt = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            second: 45
        )
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: false),
            time: .time(extended: false),
            timezone: .none
        )

        #expect(formatted == "20240115T123045")
    }

    // MARK: - Timezone Formatting

    @Test
    func `Format with UTC timezone`() throws {
        let dt = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30
        )
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: true),
            time: .time(extended: true),
            timezone: .utc
        )

        #expect(formatted == "2024-01-15T12:30:00Z")
    }

    @Test
    func `Format with offset timezone extended`() throws {
        let dt = try ISO_8601.DateTime(
            secondsSinceEpoch: 1_705_324_200,
            timezoneOffsetSeconds: 19800  // +05:30
        )
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: true),
            time: .time(extended: true),
            timezone: .offset(extended: true)
        )

        #expect(formatted.hasSuffix("+05:30"))
    }

    @Test
    func `Format with offset timezone basic`() throws {
        let dt = try ISO_8601.DateTime(
            secondsSinceEpoch: 1_705_324_200,
            timezoneOffsetSeconds: 19800  // +05:30
        )
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: true),
            time: .time(extended: true),
            timezone: .offset(extended: false)
        )

        #expect(formatted.hasSuffix("+0530"))
    }

    @Test
    func `Format with negative offset`() throws {
        let dt = try ISO_8601.DateTime(
            secondsSinceEpoch: 1_705_324_200,
            timezoneOffsetSeconds: -18000  // -05:00
        )
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: true),
            time: .time(extended: true),
            timezone: .offset(extended: true)
        )

        #expect(formatted.hasSuffix("-05:00"))
    }

    // MARK: - Default Format (description)

    @Test
    func `Default format uses extended calendar with UTC`() throws {
        let dt = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            second: 45
        )
        let formatted = dt.description

        #expect(formatted == "2024-01-15T12:30:45Z")
    }

    // MARK: - Combined Formats

    @Test
    func `Format basic complete datetime`() throws {
        let dt = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            second: 45
        )
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .calendar(extended: false),
            time: .time(extended: false),
            timezone: .utc
        )

        #expect(formatted == "20240115T123045Z")
    }

    @Test
    func `Format week date with time`() throws {
        let dt = try ISO_8601.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 14,
            minute: 30
        )
        let formatted = ISO_8601.DateTime.Formatter.format(
            dt,
            date: .week(extended: true),
            time: .time(extended: true),
            timezone: .utc
        )

        #expect(formatted.contains("W"))
        #expect(formatted.contains("T"))
        #expect(formatted.hasSuffix("Z"))
    }
}
