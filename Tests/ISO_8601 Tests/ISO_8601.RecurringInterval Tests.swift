//
//  ISO_8601.RecurringInterval Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.RecurringInterval
//

import Foundation
import Testing

@testable import ISO_8601

@Suite
struct `ISO_8601.RecurringInterval Tests` {

    // MARK: - Creation

    @Test
    func `Create recurring interval with count`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 1, day: 1)
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.startDuration(start: start, duration: duration)
        let recurring = try ISO_8601.RecurringInterval(repetitions: 5, interval: interval)

        #expect(recurring.repetitions == 5)
        #expect(recurring.isUnlimited == false)
        #expect(recurring.interval == interval)
    }

    @Test
    func `Create unlimited recurring interval`() throws {
        let duration = try ISO_8601.Duration(days: 7)
        let interval = ISO_8601.Interval.duration(duration)
        let recurring = try ISO_8601.RecurringInterval(repetitions: nil, interval: interval)

        #expect(recurring.repetitions == nil)
        #expect(recurring.isUnlimited == true)
    }

    @Test
    func `Reject negative repetitions`() throws {
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.duration(duration)

        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.RecurringInterval(repetitions: -1, interval: interval)
        }
    }

    @Test
    func `Accept zero repetitions`() throws {
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.duration(duration)
        let recurring = try ISO_8601.RecurringInterval(repetitions: 0, interval: interval)

        #expect(recurring.repetitions == 0)
    }

    // MARK: - Formatting

    @Test
    func `Format recurring interval with count`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 1, day: 1)
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.startDuration(start: start, duration: duration)
        let recurring = try ISO_8601.RecurringInterval(repetitions: 5, interval: interval)
        let formatted = recurring.description

        #expect(formatted.hasPrefix("R5/"))
        #expect(formatted.contains("2019-01-01"))
        #expect(formatted.contains("P1D"))
    }

    @Test
    func `Format unlimited recurring interval`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 1, day: 1)
        let duration = try ISO_8601.Duration(days: 7)  // 1 week = 7 days
        let interval = ISO_8601.Interval.startDuration(start: start, duration: duration)
        let recurring = try ISO_8601.RecurringInterval(repetitions: nil, interval: interval)
        let formatted = recurring.description

        #expect(formatted.hasPrefix("R/"))
        #expect(!formatted.hasPrefix("R0/"))
    }

    @Test
    func `Format recurring with duration only`() throws {
        let duration = try ISO_8601.Duration(months: 1)
        let interval = ISO_8601.Interval.duration(duration)
        let recurring = try ISO_8601.RecurringInterval(repetitions: 12, interval: interval)
        let formatted = recurring.description

        #expect(formatted == "R12/P1M")
    }

    // MARK: - Parsing

    @Test
    func `Parse recurring interval with count`() throws {
        let recurring = try ISO_8601.RecurringInterval.Parser.parse("R5/2019-01-01T00:00:00Z/P1D")

        #expect(recurring.repetitions == 5)
        #expect(recurring.isUnlimited == false)

        guard case .startDuration(let start, let dur) = recurring.interval else {
            Issue.record("Expected startDuration interval")
            return
        }

        let startComp = start.components
        #expect(startComp.year == 2019)
        #expect(startComp.month == 1)
        #expect(startComp.day == 1)
        #expect(dur.days == 1)
    }

    @Test
    func `Parse unlimited recurring interval`() throws {
        let recurring = try ISO_8601.RecurringInterval.Parser.parse("R/2019-01-01T00:00:00Z/P7D")

        #expect(recurring.repetitions == nil)
        #expect(recurring.isUnlimited == true)

        guard case .startDuration(_, let dur) = recurring.interval else {
            Issue.record("Expected startDuration interval")
            return
        }

        #expect(dur.days == 7)
    }

    @Test
    func `Parse recurring with duration only`() throws {
        let recurring = try ISO_8601.RecurringInterval.Parser.parse("R12/P1M")

        #expect(recurring.repetitions == 12)

        guard case .duration(let dur) = recurring.interval else {
            Issue.record("Expected duration interval")
            return
        }

        #expect(dur.months == 1)
    }

    @Test
    func `Parse recurring with end date`() throws {
        let recurring = try ISO_8601.RecurringInterval.Parser.parse("R3/P1Y2M10DT2H30M/2019-12-31T23:59:59Z")

        #expect(recurring.repetitions == 3)

        guard case .durationEnd(let dur, let end) = recurring.interval else {
            Issue.record("Expected durationEnd interval")
            return
        }

        #expect(dur.years == 1)
        #expect(dur.months == 2)
        #expect(dur.days == 10)
        #expect(dur.hours == 2)
        #expect(dur.minutes == 30)

        let endComp = end.components
        #expect(endComp.year == 2019)
        #expect(endComp.month == 12)
        #expect(endComp.day == 31)
    }

    @Test
    func `Parse recurring with start and end`() throws {
        let recurring = try ISO_8601.RecurringInterval.Parser.parse("R7/2019-01-01T00:00:00Z/2019-01-08T00:00:00Z")

        #expect(recurring.repetitions == 7)

        guard case .startEnd(let start, let end) = recurring.interval else {
            Issue.record("Expected startEnd interval")
            return
        }

        let startComp = start.components
        #expect(startComp.day == 1)
        let endComp = end.components
        #expect(endComp.day == 8)
    }

    // MARK: - Round-trip Tests

    @Test
    func `Round-trip recurring interval with count`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 1, day: 1)
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.startDuration(start: start, duration: duration)
        let original = try ISO_8601.RecurringInterval(repetitions: 5, interval: interval)
        let formatted = original.description
        let parsed = try ISO_8601.RecurringInterval.Parser.parse(formatted)

        #expect(parsed == original)
    }

    @Test
    func `Round-trip unlimited recurring interval`() throws {
        let duration = try ISO_8601.Duration(days: 7)  // 1 week = 7 days
        let interval = ISO_8601.Interval.duration(duration)
        let original = try ISO_8601.RecurringInterval(repetitions: nil, interval: interval)
        let formatted = original.description
        let parsed = try ISO_8601.RecurringInterval.Parser.parse(formatted)

        #expect(parsed == original)
    }

    // MARK: - Error Cases

    @Test
    func `Reject recurring without R prefix`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.RecurringInterval.Parser.parse("5/2019-01-01T00:00:00Z/P1D")
        }
    }

    @Test
    func `Reject recurring without slash`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.RecurringInterval.Parser.parse("R5")
        }
    }

    @Test
    func `Reject recurring with invalid count`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.RecurringInterval.Parser.parse("RABC/P1D")
        }
    }

    @Test
    func `Reject recurring with just R`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.RecurringInterval.Parser.parse("R")
        }
    }

    // MARK: - Equality

    @Test
    func `Recurring intervals with same values are equal`() throws {
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.duration(duration)
        let r1 = try ISO_8601.RecurringInterval(repetitions: 5, interval: interval)
        let r2 = try ISO_8601.RecurringInterval(repetitions: 5, interval: interval)

        #expect(r1 == r2)
    }

    @Test
    func `Recurring intervals with different repetitions are not equal`() throws {
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.duration(duration)
        let r1 = try ISO_8601.RecurringInterval(repetitions: 5, interval: interval)
        let r2 = try ISO_8601.RecurringInterval(repetitions: 10, interval: interval)

        #expect(r1 != r2)
    }

    @Test
    func `Unlimited and limited recurring intervals are not equal`() throws {
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.duration(duration)
        let r1 = try ISO_8601.RecurringInterval(repetitions: nil, interval: interval)
        let r2 = try ISO_8601.RecurringInterval(repetitions: 5, interval: interval)

        #expect(r1 != r2)
    }

    // MARK: - Codable

    @Test
    func `Recurring interval encodes to JSON string`() throws {
        let duration = try ISO_8601.Duration(days: 1)
        let interval = ISO_8601.Interval.duration(duration)
        let recurring = try ISO_8601.RecurringInterval(repetitions: 5, interval: interval)
        let encoder = JSONEncoder()
        let data = try encoder.encode(recurring)
        let string = String(data: data, encoding: .utf8)

        #expect(string?.contains("R5") == true)
        #expect(string?.contains("P1D") == true)
    }

    @Test
    func `Recurring interval decodes from JSON string`() throws {
        let json = Data("\"R12/P1M\"".utf8)
        let decoder = JSONDecoder()
        let recurring = try decoder.decode(ISO_8601.RecurringInterval.self, from: json)

        #expect(recurring.repetitions == 12)

        guard case .duration(let dur) = recurring.interval else {
            Issue.record("Expected duration interval")
            return
        }

        #expect(dur.months == 1)
    }
}
