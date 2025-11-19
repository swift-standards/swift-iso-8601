//
//  ISO_8601.OrdinalDate Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.OrdinalDate
//

import Testing
import Foundation
@testable import ISO_8601

@Suite
struct `ISO_8601.OrdinalDate Tests` {

    // MARK: - Creation

    @Test
    func `Create ordinal date`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2024, day: 39)

        #expect(ordinal.year == 2024)
        #expect(ordinal.day == 39)
    }

    @Test
    func `Create ordinal date for January 1`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2024, day: 1)

        #expect(ordinal.day == 1)
    }

    @Test
    func `Create ordinal date for December 31 leap year`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2024, day: 366)

        #expect(ordinal.day == 366)
    }

    @Test
    func `Create ordinal date for December 31 common year`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2023, day: 365)

        #expect(ordinal.day == 365)
    }

    // MARK: - Validation

    @Test
    func `Reject day 0`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.OrdinalDate(year: 2024, day: 0)
        }
    }

    @Test
    func `Reject day 366 in common year`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.OrdinalDate(year: 2023, day: 366)
        }
    }

    @Test
    func `Reject day 367 in leap year`() throws {
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.OrdinalDate(year: 2024, day: 367)
        }
    }

    // MARK: - Conversion to DateTime

    @Test
    func `Convert ordinal day 1 to datetime`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2024, day: 1)
        let dateTime = ordinal.toDateTime()

        let comp = dateTime.components
        #expect(comp.year == 2024)
        #expect(comp.month == 1)
        #expect(comp.day == 1)
    }

    @Test
    func `Convert ordinal day 39 to datetime`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2024, day: 39)
        let dateTime = ordinal.toDateTime()

        let comp = dateTime.components
        #expect(comp.year == 2024)
        #expect(comp.month == 2)
        #expect(comp.day == 8)  // 31 days in Jan + 8 = 39
    }

    @Test
    func `Convert ordinal day 365 to datetime in common year`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2023, day: 365)
        let dateTime = ordinal.toDateTime()

        let comp = dateTime.components
        #expect(comp.year == 2023)
        #expect(comp.month == 12)
        #expect(comp.day == 31)
    }

    @Test
    func `Convert ordinal day 366 to datetime in leap year`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2024, day: 366)
        let dateTime = ordinal.toDateTime()

        let comp = dateTime.components
        #expect(comp.year == 2024)
        #expect(comp.month == 12)
        #expect(comp.day == 31)
    }

    // MARK: - Round-trip Conversion

    @Test
    func `Round-trip datetime to ordinal date`() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 2, day: 8)
        let ordinal = original.toOrdinalDate()
        let converted = ordinal.toDateTime()

        #expect(original.components.year == converted.components.year)
        #expect(original.components.month == converted.components.month)
        #expect(original.components.day == converted.components.day)
    }

    @Test(arguments: [1, 32, 60, 100, 200, 300, 365])
    func `Round-trip all days in year`(day: Int) throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2023, day: day)
        let dateTime = ordinal.toDateTime()
        let roundTrip = dateTime.toOrdinalDate()

        #expect(roundTrip.year == ordinal.year, "Day \(day) - year")
        #expect(roundTrip.day == ordinal.day, "Day \(day) - day")
    }

    // MARK: - Equality

    @Test
    func `Ordinal dates with same values are equal`() throws {
        let od1 = try ISO_8601.OrdinalDate(year: 2024, day: 39)
        let od2 = try ISO_8601.OrdinalDate(year: 2024, day: 39)

        #expect(od1 == od2)
    }

    @Test
    func `Ordinal dates with different values are not equal`() throws {
        let od1 = try ISO_8601.OrdinalDate(year: 2024, day: 39)
        let od2 = try ISO_8601.OrdinalDate(year: 2024, day: 40)

        #expect(od1 != od2)
    }
}
