//
//  FoundationComparisonTests.swift
//  ISO 8601 Tests
//
//  Validates our ISO 8601 implementation against Foundation's reference implementation
//

import Testing
import Foundation
@testable import ISO_8601
import StandardTime

@Suite("Foundation Comparison Tests")
struct FoundationComparisonTests {

    // MARK: - Critical Year Boundary Cases

    @Test("Year boundary: 2023-01-01 (Sunday) belongs to 2022-W52")
    func yearBoundary2023Jan01() throws {
        let dt = try ISO_8601.DateTime(year: 2023, month: 1, day: 1)
        let weekDate = dt.toWeekDate()

        #expect(weekDate.weekYear == 2022, "Jan 1, 2023 (Sunday) should be in 2022-W52")
        #expect(weekDate.week == 52)
        #expect(weekDate.weekday == 7, "Sunday should be weekday 7")

        // Verify against Foundation
        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: 2023, month: 1, day: 1).date!
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: date)

        #expect(yearForWeekOfYear == 2022, "Foundation agrees: week-year is 2022")
        #expect(weekOfYear == 52, "Foundation agrees: week number is 52")
    }

    @Test("Year boundary: 2024-01-01 (Monday) is in 2024-W01")
    func yearBoundary2024Jan01() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 1, day: 1)
        let weekDate = dt.toWeekDate()

        #expect(weekDate.weekYear == 2024)
        #expect(weekDate.week == 1)
        #expect(weekDate.weekday == 1, "Monday should be weekday 1")

        // Verify against Foundation
        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: 2024, month: 1, day: 1).date!
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: date)

        #expect(yearForWeekOfYear == 2024, "Foundation agrees: week-year is 2024")
        #expect(weekOfYear == 1, "Foundation agrees: week number is 1")
    }

    @Test("Year boundary: 2025-12-29 (Monday) is in 2026-W01")
    func yearBoundary2025Dec29() throws {
        let dt = try ISO_8601.DateTime(year: 2025, month: 12, day: 29)
        let weekDate = dt.toWeekDate()

        #expect(weekDate.weekYear == 2026, "Dec 29, 2025 (Monday) should be in 2026-W01")
        #expect(weekDate.week == 1)
        #expect(weekDate.weekday == 1, "Monday should be weekday 1")

        // Verify against Foundation
        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: 2025, month: 12, day: 29).date!
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: date)

        #expect(yearForWeekOfYear == 2026, "Foundation agrees: week-year is 2026")
        #expect(weekOfYear == 1, "Foundation agrees: week number is 1")
    }

    // MARK: - January 4 Rule (Always Week 1)

    @Test("ISO 8601 rule: January 4 is always in week 1")
    func january4AlwaysWeek1() throws {
        // Test multiple years
        let years = [2020, 2021, 2022, 2023, 2024, 2025, 2026]

        for year in years {
            let dt = try ISO_8601.DateTime(year: year, month: 1, day: 4)
            let weekDate = dt.toWeekDate()

            #expect(weekDate.weekYear == year, "Jan 4, \(year) should be in year \(year)")
            #expect(weekDate.week == 1, "Jan 4, \(year) must be in week 1 by ISO 8601 definition")

            // Verify against Foundation
            let calendar = Calendar(identifier: .iso8601)
            let date = DateComponents(calendar: calendar, year: year, month: 1, day: 4).date!
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: date)

            #expect(yearForWeekOfYear == year, "Foundation confirms: Jan 4, \(year) week-year is \(year)")
            #expect(weekOfYear == 1, "Foundation confirms: Jan 4, \(year) is week 1")
        }
    }

    // MARK: - 53-Week Years

    @Test("53-week year: 2020 (Jan 1 is Wednesday + leap year)")
    func week53Year2020() throws {
        // 2020 Jan 1 is Wednesday, and 2020 is a leap year → 53 weeks
        let dt = try ISO_8601.DateTime(year: 2020, month: 12, day: 31)
        let weekDate = dt.toWeekDate()

        #expect(weekDate.weekYear == 2020)
        #expect(weekDate.week == 53, "2020 should have 53 weeks")

        // Verify against Foundation
        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: 2020, month: 12, day: 31).date!
        let weekOfYear = calendar.component(.weekOfYear, from: date)

        #expect(weekOfYear == 53, "Foundation confirms: 2020 has 53 weeks")
    }

    @Test("53-week year: 2015 (Jan 1 is Thursday)")
    func week53Year2015() throws {
        // 2015 Jan 1 is Thursday → 53 weeks
        let dt = try ISO_8601.DateTime(year: 2015, month: 12, day: 31)
        let weekDate = dt.toWeekDate()

        #expect(weekDate.weekYear == 2015)
        #expect(weekDate.week == 53, "2015 should have 53 weeks")

        // Verify against Foundation
        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: 2015, month: 12, day: 31).date!
        let weekOfYear = calendar.component(.weekOfYear, from: date)

        #expect(weekOfYear == 53, "Foundation confirms: 2015 has 53 weeks")
    }

    @Test("52-week year: 2024 (Jan 1 is Monday)")
    func week52Year2024() throws {
        // 2024 Jan 1 is Monday → 52 weeks
        let dt = try ISO_8601.DateTime(year: 2024, month: 12, day: 30)
        #expect(dt.isoWeek <= 52, "2024 should have 52 weeks")

        // Verify weeksInYear calculation
        let weeks = ISO_8601.DateTime.weeksInYear(2024)
        #expect(weeks == 52, "2024 should have exactly 52 weeks")
    }

    // MARK: - Weekday Numbering (ISO vs Gregorian)

    @Test("ISO weekday numbering: Monday=1, Sunday=7")
    func isoWeekdayNumbering() throws {
        // 2024-01-01 is Monday
        let monday = try ISO_8601.DateTime(year: 2024, month: 1, day: 1)
        #expect(monday.isoWeekday == 1, "Monday should be 1")

        // 2024-01-07 is Sunday
        let sunday = try ISO_8601.DateTime(year: 2024, month: 1, day: 7)
        #expect(sunday.isoWeekday == 7, "Sunday should be 7")

        // Verify against Foundation
        let calendar = Calendar(identifier: .iso8601)
        let mondayDate = DateComponents(calendar: calendar, year: 2024, month: 1, day: 1).date!
        let sundayDate = DateComponents(calendar: calendar, year: 2024, month: 1, day: 7).date!

        #expect(calendar.component(.weekday, from: mondayDate) == 2, "Foundation: Monday is 2")
        #expect(calendar.component(.weekday, from: sundayDate) == 1, "Foundation: Sunday is 1")

        // Note: Foundation uses 1=Sunday, 2=Monday, ... 7=Saturday
        // ISO 8601 uses 1=Monday, 2=Tuesday, ... 7=Sunday
        // We need to account for this difference
    }

    // MARK: - Ordinal Dates

    @Test("Ordinal date: Feb 29 in leap year is day 60")
    func ordinalDateLeapYearFeb29() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 2, day: 29)
        #expect(dt.ordinalDay == 60, "Feb 29 in leap year should be day 60")

        let ordinal = dt.toOrdinalDate()
        #expect(ordinal.day == 60)

        // Round-trip
        let reconstituted = ordinal.toDateTime()
        #expect(reconstituted.components.month == 2)
        #expect(reconstituted.components.day == 29)
    }

    @Test("Ordinal date: Day 60 in common year is March 1")
    func ordinalDateCommonYearDay60() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2023, day: 60)
        let dt = ordinal.toDateTime()

        #expect(dt.components.month == 3, "Day 60 in common year should be March")
        #expect(dt.components.day == 1, "Day 60 in common year should be March 1")
    }

    @Test("Ordinal date: Day 366 valid in leap year, invalid in common year")
    func ordinalDateDay366() throws {
        // Valid in leap year
        let leapYearOrdinal = try ISO_8601.OrdinalDate(year: 2024, day: 366)
        let dt = leapYearOrdinal.toDateTime()
        #expect(dt.components.month == 12)
        #expect(dt.components.day == 31)

        // Invalid in common year
        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.OrdinalDate(year: 2023, day: 366)
        }
    }

    // MARK: - Parsing Format Validation

    @Test("Parse extended format: 2024-01-15")
    func parseExtendedFormat() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("2024-01-15")
        #expect(dt.components.year == 2024)
        #expect(dt.components.month == 1)
        #expect(dt.components.day == 15)

        // Compare with Foundation
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let foundationDate = formatter.date(from: "2024-01-15")!
        let calendar = Calendar(identifier: .iso8601)
        #expect(calendar.component(.year, from: foundationDate) == 2024)
        #expect(calendar.component(.month, from: foundationDate) == 1)
        #expect(calendar.component(.day, from: foundationDate) == 15)
    }

    @Test("Parse basic format: 20240115")
    func parseBasicFormat() throws {
        let dt = try ISO_8601.DateTime.Parser.parse("20240115")
        #expect(dt.components.year == 2024)
        #expect(dt.components.month == 1)
        #expect(dt.components.day == 15)

        // Compare with Foundation (if supported)
        // Note: Foundation's ISO8601DateFormatter may not support all basic formats
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let foundationDate = formatter.date(from: "20240115") {
            let calendar = Calendar(identifier: .iso8601)
            #expect(calendar.component(.year, from: foundationDate) == 2024)
            #expect(calendar.component(.month, from: foundationDate) == 1)
            #expect(calendar.component(.day, from: foundationDate) == 15)
        }
    }

    // MARK: - Historical Dates

    @Test("Historical date: July 4, 1776 (Thursday)")
    func historicalDate1776() throws {
        // American Independence Day - known to be Thursday
        let dt = try ISO_8601.DateTime(year: 1776, month: 7, day: 4)

        // Verify weekday (should be Thursday = 4 in ISO 8601)
        let dayNum = dt.components.weekday // This is Gregorian 0=Sunday
        // Convert: Gregorian Thursday = 4, ISO Thursday = 4
        #expect(dayNum == 4, "July 4, 1776 should be Thursday (weekday 4)")

        // Verify against Foundation
        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: 1776, month: 7, day: 4).date!
        let weekday = calendar.component(.weekday, from: date)
        // Foundation: 1=Sunday, so Thursday=5
        #expect(weekday == 5, "Foundation: Thursday is weekday 5")
    }

    // MARK: - Round-Trip Tests

    @Test("Round-trip: Calendar date → Week date → Calendar date")
    func roundTripCalendarToWeekDate() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 6, day: 15)
        let weekDate = original.toWeekDate()
        let reconstituted = weekDate.toDateTime()

        #expect(reconstituted.components.year == 2024)
        #expect(reconstituted.components.month == 6)
        #expect(reconstituted.components.day == 15)
    }

    @Test("Round-trip: Calendar date → Ordinal date → Calendar date")
    func roundTripCalendarToOrdinalDate() throws {
        let original = try ISO_8601.DateTime(year: 2024, month: 6, day: 15)
        let ordinal = original.toOrdinalDate()
        let reconstituted = ordinal.toDateTime()

        #expect(reconstituted.components.year == 2024)
        #expect(reconstituted.components.month == 6)
        #expect(reconstituted.components.day == 15)
    }
}
