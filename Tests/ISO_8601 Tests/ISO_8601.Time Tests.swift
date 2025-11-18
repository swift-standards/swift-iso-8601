//
//  ISO_8601.Time Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.Time
//

import Testing
import Foundation
@testable import ISO_8601

@Suite
struct `ISO_8601.Time Tests` {

    // MARK: - Creation

    @Test
    func `Create full time`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45)

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == 45)
        #expect(time.nanoseconds == 0)
        #expect(time.timezoneOffsetSeconds == nil)
    }

    @Test
    func `Create time with fractional seconds`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45, nanoseconds: 123_000_000)

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == 45)
        #expect(time.nanoseconds == 123_000_000)
    }

    @Test
    func `Create time with timezone`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45, timezoneOffsetSeconds: 19800)

        #expect(time.timezoneOffsetSeconds == 19800)  // +05:30
    }

    @Test
    func `Create hour and minute only`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30)

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == nil)
    }

    @Test
    func `Create hour only`() throws {
        let time = try ISO_8601.Time(hour: 12)

        #expect(time.hour == 12)
        #expect(time.minute == nil)
        #expect(time.second == nil)
    }

    @Test
    func `Create midnight as 24-00-00`() throws {
        let time = try ISO_8601.Time(hour: 24, minute: 0, second: 0)

        #expect(time.hour == 24)
        #expect(time.minute == 0)
        #expect(time.second == 0)
    }

    // MARK: - Validation

    @Test
    func `Reject hour out of range`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Time(hour: 25)
        }
    }

    @Test
    func `Reject minute out of range`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Time(hour: 12, minute: 60)
        }
    }

    @Test
    func `Reject second out of range`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Time(hour: 12, minute: 30, second: 61)
        }
    }

    @Test
    func `Reject invalid nanoseconds`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Time(hour: 12, nanoseconds: 1_000_000_000)
        }
    }

    @Test
    func `Reject 24 hours with non-zero components`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Time(hour: 24, minute: 30)
        }
    }

    @Test
    func `Accept leap second`() throws {
        let time = try ISO_8601.Time(hour: 23, minute: 59, second: 60)

        #expect(time.second == 60)
    }

    // MARK: - Formatting

    @Test
    func `Format full time extended`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45)

        #expect(time.description == "12:30:45")
    }

    @Test
    func `Format full time basic`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45)
        let formatted = ISO_8601.Time.Formatter.format(time, extended: false)

        #expect(formatted == "123045")
    }

    @Test
    func `Format hour and minute extended`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30)

        #expect(time.description == "12:30")
    }

    @Test
    func `Format hour and minute basic`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30)
        let formatted = ISO_8601.Time.Formatter.format(time, extended: false)

        #expect(formatted == "1230")
    }

    @Test
    func `Format hour only`() throws {
        let time = try ISO_8601.Time(hour: 12)

        #expect(time.description == "12")
    }

    @Test
    func `Format time with fractional seconds`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45, nanoseconds: 500_000_000)
        let formatted = time.description

        #expect(formatted == "12:30:45.5")
    }

    @Test
    func `Format time with UTC timezone`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45, timezoneOffsetSeconds: 0)

        #expect(time.description == "12:30:45Z")
    }

    @Test
    func `Format time with positive offset extended`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45, timezoneOffsetSeconds: 19800)  // +05:30

        #expect(time.description == "12:30:45+05:30")
    }

    @Test
    func `Format time with positive offset basic`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45, timezoneOffsetSeconds: 19800)
        let formatted = ISO_8601.Time.Formatter.format(time, extended: false)

        #expect(formatted == "123045+0530")
    }

    @Test
    func `Format time with negative offset`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45, timezoneOffsetSeconds: -18000)  // -05:00

        #expect(time.description == "12:30:45-05:00")
    }

    @Test
    func `Format midnight as 24-00-00`() throws {
        let time = try ISO_8601.Time(hour: 24, minute: 0, second: 0)

        #expect(time.description == "24:00:00")
    }

    // MARK: - Parsing

    @Test
    func `Parse full time extended`() throws {
        let time = try ISO_8601.Time.Parser.parse("12:30:45")

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == 45)
        #expect(time.nanoseconds == 0)
        #expect(time.timezoneOffsetSeconds == nil)
    }

    @Test
    func `Parse full time basic`() throws {
        let time = try ISO_8601.Time.Parser.parse("123045")

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == 45)
    }

    @Test
    func `Parse hour and minute extended`() throws {
        let time = try ISO_8601.Time.Parser.parse("12:30")

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == nil)
    }

    @Test
    func `Parse hour and minute basic`() throws {
        let time = try ISO_8601.Time.Parser.parse("1230")

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == nil)
    }

    @Test
    func `Parse hour only`() throws {
        let time = try ISO_8601.Time.Parser.parse("12")

        #expect(time.hour == 12)
        #expect(time.minute == nil)
        #expect(time.second == nil)
    }

    @Test
    func `Parse time with fractional seconds using period`() throws {
        let time = try ISO_8601.Time.Parser.parse("12:30:45.5")

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == 45)
        #expect(time.nanoseconds == 500_000_000)
    }

    @Test
    func `Parse time with fractional seconds using comma`() throws {
        let time = try ISO_8601.Time.Parser.parse("12:30:45,5")

        #expect(time.second == 45)
        #expect(time.nanoseconds == 500_000_000)
    }

    @Test
    func `Parse time with UTC timezone`() throws {
        let time = try ISO_8601.Time.Parser.parse("12:30:45Z")

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == 45)
        #expect(time.timezoneOffsetSeconds == 0)
    }

    @Test
    func `Parse time with positive offset extended`() throws {
        let time = try ISO_8601.Time.Parser.parse("12:30:45+05:30")

        #expect(time.timezoneOffsetSeconds == 19800)
    }

    @Test
    func `Parse time with positive offset basic`() throws {
        let time = try ISO_8601.Time.Parser.parse("123045+0530")

        #expect(time.timezoneOffsetSeconds == 19800)
    }

    @Test
    func `Parse time with negative offset`() throws {
        let time = try ISO_8601.Time.Parser.parse("12:30:45-05:00")

        #expect(time.timezoneOffsetSeconds == -18000)
    }

    @Test
    func `Parse midnight as 24-00-00`() throws {
        let time = try ISO_8601.Time.Parser.parse("24:00:00")

        #expect(time.hour == 24)
        #expect(time.minute == 0)
        #expect(time.second == 0)
    }

    @Test
    func `Parse basic format with fractional seconds`() throws {
        let time = try ISO_8601.Time.Parser.parse("123045.123")

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == 45)
        #expect(time.nanoseconds == 123_000_000)
    }

    // MARK: - Round-trip Tests

    @Test
    func `Round-trip full time`() throws {
        let original = try ISO_8601.Time(hour: 12, minute: 30, second: 45)
        let formatted = original.description
        let parsed = try ISO_8601.Time.Parser.parse(formatted)

        #expect(parsed == original)
    }

    @Test
    func `Round-trip time with timezone`() throws {
        let original = try ISO_8601.Time(hour: 12, minute: 30, second: 45, timezoneOffsetSeconds: 19800)
        let formatted = original.description
        let parsed = try ISO_8601.Time.Parser.parse(formatted)

        #expect(parsed == original)
    }

    @Test
    func `Round-trip reduced precision`() throws {
        let original = try ISO_8601.Time(hour: 12, minute: 30)
        let formatted = original.description
        let parsed = try ISO_8601.Time.Parser.parse(formatted)

        #expect(parsed == original)
    }

    // MARK: - Equality

    @Test
    func `Times with same values are equal`() throws {
        let t1 = try ISO_8601.Time(hour: 12, minute: 30, second: 45)
        let t2 = try ISO_8601.Time(hour: 12, minute: 30, second: 45)

        #expect(t1 == t2)
    }

    @Test
    func `Times with different values are not equal`() throws {
        let t1 = try ISO_8601.Time(hour: 12, minute: 30, second: 45)
        let t2 = try ISO_8601.Time(hour: 12, minute: 30, second: 46)

        #expect(t1 != t2)
    }

    @Test
    func `Times with different timezones are not equal`() throws {
        let t1 = try ISO_8601.Time(hour: 12, minute: 30, timezoneOffsetSeconds: 0)
        let t2 = try ISO_8601.Time(hour: 12, minute: 30, timezoneOffsetSeconds: 3600)

        #expect(t1 != t2)
    }

    // MARK: - Codable

    @Test
    func `Time encodes to JSON string`() throws {
        let time = try ISO_8601.Time(hour: 12, minute: 30, second: 45)
        let encoder = JSONEncoder()
        let data = try encoder.encode(time)
        let string = String(data: data, encoding: .utf8)

        #expect(string?.contains("12:30:45") == true)
    }

    @Test
    func `Time decodes from JSON string`() throws {
        let json = "\"12:30:45Z\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let time = try decoder.decode(ISO_8601.Time.self, from: json)

        #expect(time.hour == 12)
        #expect(time.minute == 30)
        #expect(time.second == 45)
        #expect(time.timezoneOffsetSeconds == 0)
    }
}
