//
//  ISO_8601.Time.Weekday Tests.swift
//  ISO 8601 Tests
//
//  Tests for ISO_8601.Time.Weekday
//

import Testing
import Foundation
@testable import ISO_8601

@Suite
struct `ISO_8601.Time.Weekday Tests` {

    // MARK: - Known Dates

    @Test
    func `Calculate weekday for January 1, 2024 (Monday)`() {
        let weekday = ISO_8601.Time.Weekday(year: 2024, month: 1, day: 1)

        #expect(weekday == .monday)
        #expect(weekday.isoNumber == 1)
        #expect(weekday.gregorianNumber == 1)
    }

    @Test
    func `Calculate weekday for January 15, 2024 (Monday)`() {
        let weekday = ISO_8601.Time.Weekday(year: 2024, month: 1, day: 15)

        #expect(weekday == .monday)
    }

    @Test
    func `Calculate weekday for December 25, 2024 (Wednesday)`() {
        let weekday = ISO_8601.Time.Weekday(year: 2024, month: 12, day: 25)

        #expect(weekday == .wednesday)
        #expect(weekday.isoNumber == 3)
        #expect(weekday.gregorianNumber == 3)
    }

    @Test
    func `Calculate weekday for January 1, 2000 (Saturday)`() {
        let weekday = ISO_8601.Time.Weekday(year: 2000, month: 1, day: 1)

        #expect(weekday == .saturday)
        #expect(weekday.isoNumber == 6)
        #expect(weekday.gregorianNumber == 6)
    }

    @Test
    func `Calculate weekday for July 4, 1776 (Thursday)`() {
        let weekday = ISO_8601.Time.Weekday(year: 1776, month: 7, day: 4)

        #expect(weekday == .thursday)
        #expect(weekday.isoNumber == 4)
    }

    @Test
    func `Calculate weekday for Sunday`() {
        // January 7, 2024 is a Sunday
        let weekday = ISO_8601.Time.Weekday(year: 2024, month: 1, day: 7)

        #expect(weekday == .sunday)
        #expect(weekday.isoNumber == 7)  // ISO: Sunday = 7
        #expect(weekday.gregorianNumber == 0)  // Gregorian: Sunday = 0
    }

    // MARK: - ISO vs Gregorian Numbering

    @Test
    func `ISO numbering for all days`() {
        let days: [(ISO_8601.Time.Weekday, Int)] = [
            (.monday, 1),
            (.tuesday, 2),
            (.wednesday, 3),
            (.thursday, 4),
            (.friday, 5),
            (.saturday, 6),
            (.sunday, 7)
        ]

        for (day, expectedISO) in days {
            #expect(day.isoNumber == expectedISO)
        }
    }

    @Test
    func `Gregorian numbering for all days`() {
        let days: [(ISO_8601.Time.Weekday, Int)] = [
            (.sunday, 0),
            (.monday, 1),
            (.tuesday, 2),
            (.wednesday, 3),
            (.thursday, 4),
            (.friday, 5),
            (.saturday, 6)
        ]

        for (day, expectedGregorian) in days {
            #expect(day.gregorianNumber == expectedGregorian)
        }
    }

    // MARK: - Initialization from Numbers

    @Test
    func `Create from ISO number`() {
        #expect(ISO_8601.Time.Weekday(isoNumber: 1) == .monday)
        #expect(ISO_8601.Time.Weekday(isoNumber: 2) == .tuesday)
        #expect(ISO_8601.Time.Weekday(isoNumber: 3) == .wednesday)
        #expect(ISO_8601.Time.Weekday(isoNumber: 4) == .thursday)
        #expect(ISO_8601.Time.Weekday(isoNumber: 5) == .friday)
        #expect(ISO_8601.Time.Weekday(isoNumber: 6) == .saturday)
        #expect(ISO_8601.Time.Weekday(isoNumber: 7) == .sunday)
    }

    @Test
    func `Create from Gregorian number`() {
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 0) == .sunday)
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 1) == .monday)
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 2) == .tuesday)
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 3) == .wednesday)
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 4) == .thursday)
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 5) == .friday)
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 6) == .saturday)
    }

    @Test
    func `Reject invalid ISO number`() {
        #expect(ISO_8601.Time.Weekday(isoNumber: 0) == nil)
        #expect(ISO_8601.Time.Weekday(isoNumber: 8) == nil)
        #expect(ISO_8601.Time.Weekday(isoNumber: -1) == nil)
    }

    @Test
    func `Reject invalid Gregorian number`() {
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 7) == nil)
        #expect(ISO_8601.Time.Weekday(gregorianNumber: -1) == nil)
        #expect(ISO_8601.Time.Weekday(gregorianNumber: 10) == nil)
    }

    // MARK: - Edge Cases

    @Test
    func `Calculate weekday for leap year February 29`() {
        // February 29, 2024 is a Thursday
        let weekday = ISO_8601.Time.Weekday(year: 2024, month: 2, day: 29)

        #expect(weekday == .thursday)
    }

    @Test
    func `Calculate weekday for year boundary`() {
        // December 31, 2023 is a Sunday
        let weekday1 = ISO_8601.Time.Weekday(year: 2023, month: 12, day: 31)
        #expect(weekday1 == .sunday)

        // January 1, 2024 is a Monday
        let weekday2 = ISO_8601.Time.Weekday(year: 2024, month: 1, day: 1)
        #expect(weekday2 == .monday)
    }

    @Test
    func `Calculate weekday across centuries`() {
        // January 1, 1900 was a Monday
        let weekday1900 = ISO_8601.Time.Weekday(year: 1900, month: 1, day: 1)
        #expect(weekday1900 == .monday)

        // January 1, 2000 was a Saturday
        let weekday2000 = ISO_8601.Time.Weekday(year: 2000, month: 1, day: 1)
        #expect(weekday2000 == .saturday)
    }

    // MARK: - CaseIterable

    @Test
    func `All cases are available`() {
        let allDays = ISO_8601.Time.Weekday.allCases

        #expect(allDays.count == 7)
        #expect(allDays.contains(.sunday))
        #expect(allDays.contains(.monday))
        #expect(allDays.contains(.tuesday))
        #expect(allDays.contains(.wednesday))
        #expect(allDays.contains(.thursday))
        #expect(allDays.contains(.friday))
        #expect(allDays.contains(.saturday))
    }

    // MARK: - Codable

    @Test
    func `Weekday encodes to JSON`() throws {
        let weekday = ISO_8601.Time.Weekday.monday
        let encoder = JSONEncoder()
        let data = try encoder.encode(weekday)
        let string = String(data: data, encoding: .utf8)

        #expect(string == "1")
    }

    @Test
    func `Weekday decodes from JSON`() throws {
        let json = "2".data(using: .utf8)!
        let decoder = JSONDecoder()
        let weekday = try decoder.decode(ISO_8601.Time.Weekday.self, from: json)

        #expect(weekday == .tuesday)
    }

    // MARK: - Consistency Tests

    @Test
    func `Weekday calculation matches Components weekday`() throws {
        // Test a few dates to ensure consistency with existing weekday calculation
        let testDates = [
            (year: 2024, month: 1, day: 15),   // Monday
            (year: 2024, month: 2, day: 14),   // Wednesday
            (year: 2024, month: 12, day: 25),  // Wednesday
            (year: 2000, month: 1, day: 1)     // Saturday
        ]

        for testDate in testDates {
            let weekday = ISO_8601.Time.Weekday(year: testDate.year, month: testDate.month, day: testDate.day)
            let dateTime = try ISO_8601.DateTime(year: testDate.year, month: testDate.month, day: testDate.day)
            let components = dateTime.components

            // Components.weekday is Zeller's format (0=Sunday)
            #expect(weekday.gregorianNumber == components.weekday)
        }
    }

    @Test
    func `Round-trip between ISO and enum`() {
        for day in ISO_8601.Time.Weekday.allCases {
            let iso = day.isoNumber
            let recovered = ISO_8601.Time.Weekday(isoNumber: iso)
            #expect(recovered == day)
        }
    }

    @Test
    func `Round-trip between Gregorian and enum`() {
        for day in ISO_8601.Time.Weekday.allCases {
            let gregorian = day.gregorianNumber
            let recovered = ISO_8601.Time.Weekday(gregorianNumber: gregorian)
            #expect(recovered == day)
        }
    }
}
