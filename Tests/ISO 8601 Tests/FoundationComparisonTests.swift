import Foundation
import Testing
import Time

@testable import ISO_8601

@Suite
struct `Foundation Comparison Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Foundation Comparison Tests`.`Edge Case` {

    @Test
    func `Ordinal date: Feb 29 in leap year is day 60`() throws {
        let dt = try ISO_8601.DateTime(year: 2024, month: 2, day: 29)
        #expect(dt.ordinalDay == 60, "Feb 29 in leap year should be day 60")

        let ordinal = ISO_8601.OrdinalDate(dt)
        #expect(ordinal.day == 60)

        let reconstituted = ISO_8601.DateTime(ordinal)
        #expect(reconstituted.components.month == 2)
        #expect(reconstituted.components.day == 29)
    }

    @Test
    func `Ordinal date: Day 60 in common year is March 1`() throws {
        let ordinal = try ISO_8601.OrdinalDate(year: 2023, day: 60)
        let dt = ISO_8601.DateTime(ordinal)

        #expect(dt.components.month == 3, "Day 60 in common year should be March")
        #expect(dt.components.day == 1, "Day 60 in common year should be March 1")
    }

    @Test
    func `Ordinal date: Day 366 valid in leap year, invalid in common year`() throws {

        let leapYearOrdinal = try ISO_8601.OrdinalDate(year: 2024, day: 366)
        let dt = ISO_8601.DateTime(leapYearOrdinal)
        #expect(dt.components.month == 12)
        #expect(dt.components.day == 31)

        #expect(throws: ISO_8601.Date.Error.self) {
            _ = try ISO_8601.OrdinalDate(year: 2023, day: 366)
        }
    }
}

extension `Foundation Comparison Tests`.Integration {

    @Test(
        arguments: [
            (
                year: 2023, month: 1, day: 1,
                expected: (weekYear: 2022, week: 52, weekday: 7),
                desc: "2023-01-01 (Sunday) → 2022-W52"
            ),
            (
                year: 2024, month: 1, day: 1,
                expected: (weekYear: 2024, week: 1, weekday: 1),
                desc: "2024-01-01 (Monday) → 2024-W01"
            ),
            (
                year: 2025, month: 12, day: 29,
                expected: (weekYear: 2026, week: 1, weekday: 1),
                desc: "2025-12-29 (Monday) → 2026-W01"
            ),
        ]
    )
    func `Year boundary`(
        year: Int,
        month: Int,
        day: Int,
        expected: (weekYear: Int, week: Int, weekday: Int),
        desc: String
    ) throws {
        let dt = try ISO_8601.DateTime(year: year, month: month, day: day)
        let weekDate = ISO_8601.WeekDate(dt)

        #expect(weekDate.weekYear == expected.weekYear, "\(desc) - week-year")
        #expect(weekDate.week == expected.week, "\(desc) - week number")
        #expect(weekDate.weekday == expected.weekday, "\(desc) - weekday")

        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: year, month: month, day: day).date!
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: date)

        #expect(yearForWeekOfYear == expected.weekYear, "Foundation agrees: \(desc) week-year")
        #expect(weekOfYear == expected.week, "Foundation agrees: \(desc) week number")
    }

    @Test(
        arguments: [2020, 2021, 2022, 2023, 2024, 2025, 2026]
    )
    func `ISO 8601 rule: January 4 is always in week 1`(year: Int) throws {
        let dt = try ISO_8601.DateTime(year: year, month: 1, day: 4)
        let weekDate = ISO_8601.WeekDate(dt)

        #expect(weekDate.weekYear == year, "Jan 4, \(year) should be in year \(year)")
        #expect(weekDate.week == 1, "Jan 4, \(year) must be in week 1 by ISO 8601 definition")

        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: year, month: 1, day: 4).date!
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: date)

        #expect(
            yearForWeekOfYear == year,
            "Foundation confirms: Jan 4, \(year) week-year is \(year)"
        )
        #expect(weekOfYear == 1, "Foundation confirms: Jan 4, \(year) is week 1")
    }

    @Test(
        arguments: [
            (year: 2020, expectedWeeks: 53, desc: "2020 (Jan 1 = Wed + leap year)"),
            (year: 2015, expectedWeeks: 53, desc: "2015 (Jan 1 = Thu)"),
            (year: 2024, expectedWeeks: 52, desc: "2024 (Jan 1 = Mon)"),
        ]
    )
    func `Weeks in year`(year: Int, expectedWeeks: Int, desc: String) throws {

        let lastDay = Time.Time.Calendar.Gregorian.isLeapYear(year) ? 31 : 30
        let dt = try ISO_8601.DateTime(year: year, month: 12, day: lastDay)

        if expectedWeeks == 53 {
            let weekDate = ISO_8601.WeekDate(dt)
            #expect(weekDate.weekYear == year, "\(desc) - year should have week 53")
            #expect(weekDate.week == 53, "\(desc) - should have 53 weeks")

            let calendar = Calendar(identifier: .iso8601)
            let date = DateComponents(calendar: calendar, year: year, month: 12, day: 31).date!
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            #expect(weekOfYear == 53, "Foundation confirms: \(desc) has 53 weeks")
        }

        let weeks = ISO_8601.DateTime.weeksInYear(year)
        #expect(weeks == expectedWeeks, "\(desc) should have exactly \(expectedWeeks) weeks")
    }

    @Test
    func `ISO weekday numbering: Monday=1, Sunday=7`() throws {

        let monday = try ISO_8601.DateTime(year: 2024, month: 1, day: 1)
        #expect(monday.isoWeekday == 1, "Monday should be 1")

        let sunday = try ISO_8601.DateTime(year: 2024, month: 1, day: 7)
        #expect(sunday.isoWeekday == 7, "Sunday should be 7")

        let calendar = Calendar(identifier: .iso8601)
        let mondayDate = DateComponents(calendar: calendar, year: 2024, month: 1, day: 1).date!
        let sundayDate = DateComponents(calendar: calendar, year: 2024, month: 1, day: 7).date!

        #expect(calendar.component(.weekday, from: mondayDate) == 2, "Foundation: Monday is 2")
        #expect(calendar.component(.weekday, from: sundayDate) == 1, "Foundation: Sunday is 1")

    }

    @Test
    func `Parse extended format: 2024-01-15`() throws {
        let dt = try ISO_8601.DateTime("2024-01-15")
        #expect(dt.components.year == 2024)
        #expect(dt.components.month == 1)
        #expect(dt.components.day == 15)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let foundationDate = formatter.date(from: "2024-01-15")!
        let calendar = Calendar(identifier: .iso8601)
        #expect(calendar.component(.year, from: foundationDate) == 2024)
        #expect(calendar.component(.month, from: foundationDate) == 1)
        #expect(calendar.component(.day, from: foundationDate) == 15)
    }

    @Test
    func `Parse basic format: 20240115`() throws {
        let dt = try ISO_8601.DateTime("20240115")
        #expect(dt.components.year == 2024)
        #expect(dt.components.month == 1)
        #expect(dt.components.day == 15)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let foundationDate = formatter.date(from: "20240115") {
            let calendar = Calendar(identifier: .iso8601)
            #expect(calendar.component(.year, from: foundationDate) == 2024)
            #expect(calendar.component(.month, from: foundationDate) == 1)
            #expect(calendar.component(.day, from: foundationDate) == 15)
        }
    }

    @Test
    func `Historical date: July 4, 1776 (Thursday)`() throws {

        let dt = try ISO_8601.DateTime(year: 1776, month: 7, day: 4)

        let dayNum = dt.components.weekday

        #expect(dayNum == 4, "July 4, 1776 should be Thursday (weekday 4)")

        let calendar = Calendar(identifier: .iso8601)
        let date = DateComponents(calendar: calendar, year: 1776, month: 7, day: 4).date!
        let weekday = calendar.component(.weekday, from: date)

        #expect(weekday == 5, "Foundation: Thursday is weekday 5")
    }

    @Test(
        arguments: [
            (year: 2024, month: 6, day: 15, desc: "mid-year date"),
            (year: 2023, month: 1, day: 1, desc: "year boundary (Sun)"),
            (year: 2024, month: 1, day: 1, desc: "year boundary (Mon)"),
            (year: 2024, month: 2, day: 29, desc: "leap day"),
            (year: 2024, month: 12, day: 31, desc: "year end"),
        ]
    )
    func `Round-trip conversions`(year: Int, month: Int, day: Int, desc: String) throws {
        let original = try ISO_8601.DateTime(year: year, month: month, day: day)

        let weekDate = ISO_8601.WeekDate(original)
        let fromWeekDate = ISO_8601.DateTime(weekDate)
        #expect(fromWeekDate.components.year == year, "\(desc) - week date year")
        #expect(fromWeekDate.components.month == month, "\(desc) - week date month")
        #expect(fromWeekDate.components.day == day, "\(desc) - week date day")

        let ordinal = ISO_8601.OrdinalDate(original)
        let fromOrdinal = ISO_8601.DateTime(ordinal)
        #expect(fromOrdinal.components.year == year, "\(desc) - ordinal year")
        #expect(fromOrdinal.components.month == month, "\(desc) - ordinal month")
        #expect(fromOrdinal.components.day == day, "\(desc) - ordinal day")
    }
}
