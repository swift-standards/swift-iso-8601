//
//  ISO_8601.Interval Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.Interval
//

import Foundation
import Testing

@testable import ISO_8601

@Suite
struct `ISO_8601.Interval Tests` {

    // MARK: - Start/End Intervals

    @Test
    func `Create start-end interval`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
        let interval = ISO_8601.Interval.startEnd(start: start, end: end)

        #expect(interval.hasStart == true)
        #expect(interval.hasEnd == true)
        #expect(interval.hasDuration == false)
        #expect(interval.start == start)
        #expect(interval.end == end)
    }

    @Test
    func `Format start-end interval`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
        let interval = ISO_8601.Interval.startEnd(start: start, end: end)
        let formatted = interval.description

        #expect(formatted.contains("2019-08-27"))
        #expect(formatted.contains("2019-08-29"))
        #expect(formatted.contains("/"))
    }

    @Test
    func `Parse start-end interval`() throws {
        let interval = try ISO_8601.Interval.Parser.parse("2019-08-27T00:00:00Z/2019-08-29T00:00:00Z")

        guard case .startEnd(let start, let end) = interval else {
            Issue.record("Expected startEnd interval")
            return
        }

        let startComp = start.components
        #expect(startComp.year == 2019)
        #expect(startComp.month == 8)
        #expect(startComp.day == 27)

        let endComp = end.components
        #expect(endComp.year == 2019)
        #expect(endComp.month == 8)
        #expect(endComp.day == 29)
    }

    // MARK: - Duration Only Intervals

    @Test
    func `Create duration-only interval`() throws {
        let duration = try ISO_8601.Duration(days: 3)
        let interval = ISO_8601.Interval.duration(duration)

        #expect(interval.hasStart == false)
        #expect(interval.hasEnd == false)
        #expect(interval.hasDuration == true)
        #expect(interval.duration == duration)
    }

    @Test
    func `Format duration-only interval`() throws {
        let duration = try ISO_8601.Duration(days: 3)
        let interval = ISO_8601.Interval.duration(duration)
        let formatted = interval.description

        #expect(formatted == "P3D")
    }

    @Test
    func `Parse duration-only interval`() throws {
        let interval = try ISO_8601.Interval.Parser.parse("P3D")

        guard case .duration(let dur) = interval else {
            Issue.record("Expected duration interval")
            return
        }

        #expect(dur.days == 3)
    }

    // MARK: - Start/Duration Intervals

    @Test
    func `Create start-duration interval`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let duration = try ISO_8601.Duration(days: 3)
        let interval = ISO_8601.Interval.startDuration(start: start, duration: duration)

        #expect(interval.hasStart == true)
        #expect(interval.hasEnd == false)
        #expect(interval.hasDuration == true)
        #expect(interval.start == start)
        #expect(interval.duration == duration)
    }

    @Test
    func `Format start-duration interval`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let duration = try ISO_8601.Duration(days: 3)
        let interval = ISO_8601.Interval.startDuration(start: start, duration: duration)
        let formatted = interval.description

        #expect(formatted.contains("2019-08-27"))
        #expect(formatted.contains("P3D"))
        #expect(formatted.contains("/"))
    }

    @Test
    func `Parse start-duration interval`() throws {
        let interval = try ISO_8601.Interval.Parser.parse("2019-08-27T00:00:00Z/P3D")

        guard case .startDuration(let start, let dur) = interval else {
            Issue.record("Expected startDuration interval")
            return
        }

        let startComp = start.components
        #expect(startComp.year == 2019)
        #expect(startComp.month == 8)
        #expect(startComp.day == 27)
        #expect(dur.days == 3)
    }

    // MARK: - Duration/End Intervals

    @Test
    func `Create duration-end interval`() throws {
        let duration = try ISO_8601.Duration(days: 3)
        let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
        let interval = ISO_8601.Interval.durationEnd(duration: duration, end: end)

        #expect(interval.hasStart == false)
        #expect(interval.hasEnd == true)
        #expect(interval.hasDuration == true)
        #expect(interval.duration == duration)
        #expect(interval.end == end)
    }

    @Test
    func `Format duration-end interval`() throws {
        let duration = try ISO_8601.Duration(days: 3)
        let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
        let interval = ISO_8601.Interval.durationEnd(duration: duration, end: end)
        let formatted = interval.description

        #expect(formatted.contains("P3D"))
        #expect(formatted.contains("2019-08-29"))
        #expect(formatted.contains("/"))
    }

    @Test
    func `Parse duration-end interval`() throws {
        let interval = try ISO_8601.Interval.Parser.parse("P3D/2019-08-29T00:00:00Z")

        guard case .durationEnd(let dur, let end) = interval else {
            Issue.record("Expected durationEnd interval")
            return
        }

        #expect(dur.days == 3)
        let endComp = end.components
        #expect(endComp.year == 2019)
        #expect(endComp.month == 8)
        #expect(endComp.day == 29)
    }

    // MARK: - Complex Examples

    @Test
    func `Parse interval with time components`() throws {
        let interval = try ISO_8601.Interval.Parser.parse("2019-08-27T12:30:00Z/2019-08-29T18:45:00Z")

        guard case .startEnd(let start, let end) = interval else {
            Issue.record("Expected startEnd interval")
            return
        }

        let startComp = start.components
        #expect(startComp.hour == 12)
        #expect(startComp.minute == 30)

        let endComp = end.components
        #expect(endComp.hour == 18)
        #expect(endComp.minute == 45)
    }

    @Test
    func `Parse interval with duration components`() throws {
        let interval = try ISO_8601.Interval.Parser.parse("2019-08-27T00:00:00Z/P1Y2M3DT4H5M6S")

        guard case .startDuration(let start, let dur) = interval else {
            Issue.record("Expected startDuration interval")
            return
        }

        let startComp = start.components
        #expect(startComp.year == 2019)

        #expect(dur.years == 1)
        #expect(dur.months == 2)
        #expect(dur.days == 3)
        #expect(dur.hours == 4)
        #expect(dur.minutes == 5)
        #expect(dur.seconds == 6)
    }

    // MARK: - Round-trip Tests

    @Test
    func `Round-trip start-end interval`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
        let original = ISO_8601.Interval.startEnd(start: start, end: end)
        let formatted = original.description
        let parsed = try ISO_8601.Interval.Parser.parse(formatted)

        #expect(parsed == original)
    }

    @Test
    func `Round-trip duration-only interval`() throws {
        let duration = try ISO_8601.Duration(days: 3)
        let original = ISO_8601.Interval.duration(duration)
        let formatted = original.description
        let parsed = try ISO_8601.Interval.Parser.parse(formatted)

        #expect(parsed == original)
    }

    @Test
    func `Round-trip start-duration interval`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let duration = try ISO_8601.Duration(days: 3)
        let original = ISO_8601.Interval.startDuration(start: start, duration: duration)
        let formatted = original.description
        let parsed = try ISO_8601.Interval.Parser.parse(formatted)

        #expect(parsed == original)
    }

    @Test
    func `Round-trip duration-end interval`() throws {
        let duration = try ISO_8601.Duration(days: 3)
        let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
        let original = ISO_8601.Interval.durationEnd(duration: duration, end: end)
        let formatted = original.description
        let parsed = try ISO_8601.Interval.Parser.parse(formatted)

        #expect(parsed == original)
    }

    // MARK: - Error Cases

    @Test
    func `Reject interval without slash and not duration`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Interval.Parser.parse("2019-08-27")
        }
    }

    @Test
    func `Reject interval with two durations`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Interval.Parser.parse("P3D/P5D")
        }
    }

    // MARK: - Equality

    @Test
    func `Intervals with same values are equal`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
        let i1 = ISO_8601.Interval.startEnd(start: start, end: end)
        let i2 = ISO_8601.Interval.startEnd(start: start, end: end)

        #expect(i1 == i2)
    }

    @Test
    func `Intervals with different types are not equal`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let duration = try ISO_8601.Duration(days: 3)
        let i1 = ISO_8601.Interval.startDuration(start: start, duration: duration)
        let i2 = ISO_8601.Interval.duration(duration)

        #expect(i1 != i2)
    }

    // MARK: - Codable

    @Test
    func `Interval encodes to JSON string`() throws {
        let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
        let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
        let interval = ISO_8601.Interval.startEnd(start: start, end: end)
        let encoder = JSONEncoder()
        let data = try encoder.encode(interval)
        let string = String(data: data, encoding: .utf8)

        #expect(string?.contains("2019-08-27") == true)
        #expect(string?.contains("2019-08-29") == true)
    }

    @Test
    func `Interval decodes from JSON string`() throws {
        let json = Data("\"P3D\"".utf8)
        let decoder = JSONDecoder()
        let interval = try decoder.decode(ISO_8601.Interval.self, from: json)

        guard case .duration(let dur) = interval else {
            Issue.record("Expected duration interval")
            return
        }

        #expect(dur.days == 3)
    }
}
