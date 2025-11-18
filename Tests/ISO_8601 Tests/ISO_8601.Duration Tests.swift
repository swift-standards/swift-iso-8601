//
//  ISO_8601.Duration Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.Duration
//

import Testing
import Foundation
@testable import ISO_8601

@Suite
struct `ISO_8601.Duration Tests` {

    // MARK: - Creation

    @Test
    func `Create duration with all components`() throws {
        let duration = try ISO_8601.Duration(
            years: 1,
            months: 6,
            days: 15,
            hours: 12,
            minutes: 30,
            seconds: 45,
            nanoseconds: 123_000_000
        )

        #expect(duration.years == 1)
        #expect(duration.months == 6)
        #expect(duration.days == 15)
        #expect(duration.hours == 12)
        #expect(duration.minutes == 30)
        #expect(duration.seconds == 45)
        #expect(duration.nanoseconds == 123_000_000)
    }

    @Test
    func `Create duration with only years`() throws {
        let duration = try ISO_8601.Duration(years: 3)

        #expect(duration.years == 3)
        #expect(duration.months == 0)
        #expect(duration.days == 0)
    }

    @Test
    func `Create duration with only time components`() throws {
        let duration = try ISO_8601.Duration(hours: 2, minutes: 30)

        #expect(duration.hours == 2)
        #expect(duration.minutes == 30)
        #expect(duration.years == 0)
    }

    @Test
    func `Zero duration is recognized`() throws {
        let duration = try ISO_8601.Duration()

        #expect(duration.isZero == true)
    }

    @Test
    func `Non-zero duration is recognized`() throws {
        let duration = try ISO_8601.Duration(seconds: 1)

        #expect(duration.isZero == false)
    }

    // MARK: - Validation

    @Test
    func `Reject invalid nanoseconds`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Duration(nanoseconds: 1_000_000_000)
        }
    }

    @Test
    func `Accept maximum valid nanoseconds`() throws {
        let duration = try ISO_8601.Duration(nanoseconds: 999_999_999)

        #expect(duration.nanoseconds == 999_999_999)
    }

    // MARK: - Formatting

    @Test
    func `Format duration with all components`() throws {
        let duration = try ISO_8601.Duration(
            years: 3,
            months: 6,
            days: 4,
            hours: 12,
            minutes: 30,
            seconds: 5
        )
        let formatted = duration.description

        #expect(formatted == "P3Y6M4DT12H30M5S")
    }

    @Test
    func `Format duration with only years`() throws {
        let duration = try ISO_8601.Duration(years: 1)

        #expect(duration.description == "P1Y")
    }

    @Test
    func `Format duration with only time`() throws {
        let duration = try ISO_8601.Duration(hours: 5, minutes: 30)

        #expect(duration.description == "PT5H30M")
    }

    @Test
    func `Format duration with only seconds`() throws {
        let duration = try ISO_8601.Duration(seconds: 45)

        #expect(duration.description == "PT45S")
    }

    @Test
    func `Format duration with fractional seconds`() throws {
        let duration = try ISO_8601.Duration(seconds: 5, nanoseconds: 500_000_000)
        let formatted = duration.description

        // Should output "PT5.5S"
        #expect(formatted.contains("5.5S") || formatted.contains("5.500000000S"))
    }

    @Test
    func `Format zero duration`() throws {
        let duration = try ISO_8601.Duration()

        #expect(duration.description == "PT0S")
    }

    // MARK: - Parsing

    @Test
    func `Parse duration with all components`() throws {
        let duration = try ISO_8601.Duration.Parser.parse("P3Y6M4DT12H30M5S")

        #expect(duration.years == 3)
        #expect(duration.months == 6)
        #expect(duration.days == 4)
        #expect(duration.hours == 12)
        #expect(duration.minutes == 30)
        #expect(duration.seconds == 5)
    }

    @Test
    func `Parse duration with only years`() throws {
        let duration = try ISO_8601.Duration.Parser.parse("P1Y")

        #expect(duration.years == 1)
        #expect(duration.months == 0)
    }

    @Test
    func `Parse duration with only time`() throws {
        let duration = try ISO_8601.Duration.Parser.parse("PT5M")

        #expect(duration.minutes == 5)
        #expect(duration.hours == 0)
        #expect(duration.years == 0)
    }

    @Test
    func `Parse duration with fractional seconds using period`() throws {
        let duration = try ISO_8601.Duration.Parser.parse("PT5.5S")

        #expect(duration.seconds == 5)
        #expect(duration.nanoseconds == 500_000_000)
    }

    @Test
    func `Parse duration with fractional seconds using comma`() throws {
        let duration = try ISO_8601.Duration.Parser.parse("PT5,5S")

        #expect(duration.seconds == 5)
        #expect(duration.nanoseconds == 500_000_000)
    }

    @Test
    func `Parse zero duration`() throws {
        let duration = try ISO_8601.Duration.Parser.parse("PT0S")

        #expect(duration.isZero)
    }

    // MARK: - Round-trip Tests

    @Test
    func `Round-trip full duration`() throws {
        let original = try ISO_8601.Duration(
            years: 1,
            months: 2,
            days: 3,
            hours: 4,
            minutes: 5,
            seconds: 6
        )
        let formatted = original.description
        let parsed = try ISO_8601.Duration.Parser.parse(formatted)

        #expect(parsed == original)
    }

    @Test
    func `Round-trip time-only duration`() throws {
        let original = try ISO_8601.Duration(hours: 2, minutes: 30, seconds: 45)
        let formatted = original.description
        let parsed = try ISO_8601.Duration.Parser.parse(formatted)

        #expect(parsed == original)
    }

    // MARK: - Error Cases

    @Test
    func `Reject duration without P prefix`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Duration.Parser.parse("1Y2M")
        }
    }

    @Test
    func `Reject invalid format`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.Duration.Parser.parse("PABC")
        }
    }

    // MARK: - Equality

    @Test
    func `Durations with same values are equal`() throws {
        let d1 = try ISO_8601.Duration(years: 1, days: 15)
        let d2 = try ISO_8601.Duration(years: 1, days: 15)

        #expect(d1 == d2)
    }

    @Test
    func `Durations with different values are not equal`() throws {
        let d1 = try ISO_8601.Duration(years: 1, days: 15)
        let d2 = try ISO_8601.Duration(years: 1, days: 16)

        #expect(d1 != d2)
    }

    // MARK: - Codable

    @Test
    func `Duration encodes to JSON string`() throws {
        let duration = try ISO_8601.Duration(hours: 2, minutes: 30)
        let encoder = JSONEncoder()
        let data = try encoder.encode(duration)
        let string = String(data: data, encoding: .utf8)

        #expect(string?.contains("PT2H30M") == true)
    }

    @Test
    func `Duration decodes from JSON string`() throws {
        let json = "\"P1Y2M3D\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let duration = try decoder.decode(ISO_8601.Duration.self, from: json)

        #expect(duration.years == 1)
        #expect(duration.months == 2)
        #expect(duration.days == 3)
    }
}
