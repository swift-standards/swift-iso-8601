//
//  ISO_8601.swift
//  swift-iso-8601
//
//  ISO 8601 date-time format implementation
//

// @_exported import struct StandardTime.Time

/// ISO 8601 date and time format
///
/// Implements the ISO 8601:2019 standard for representing dates and times.
///
/// ## Supported Formats
///
/// ### Calendar Date
/// - Extended: `2024-01-15`
/// - Basic: `20240115`
///
/// ### Week Date
/// - Extended: `2024-W03-2`
/// - Basic: `2024W032`
///
/// ### Ordinal Date
/// - Extended: `2024-039`
/// - Basic: `2024039`
///
/// ### Combined Date-Time
/// - `2024-01-15T12:30:00Z`
/// - `2024-01-15T12:30:00+05:30`
/// - `20240115T123000Z` (basic format)
///
/// ## Example Usage
///
/// ```swift
/// // Create from components
/// let dt = try ISO_8601.DateTime(year: 2024, month: 1, day: 15, hour: 12, minute: 30)
///
/// // Format as string
/// let formatted = ISO_8601.DateTime.Formatter.format(dt)
/// // "2024-01-15T12:30:00Z"
///
/// // Parse from string
/// let parsed = try ISO_8601.DateTime.Parser.parse("2024-01-15T12:30:00Z")
///
/// // Week date
/// let weekDate = ISO_8601.WeekDate(dt)
/// // 2024-W03-1 (Week 3, Monday)
///
/// // Ordinal date
/// let ordinal = ISO_8601.OrdinalDate(dt)
/// // 2024-015 (15th day of year)
/// ```
public enum ISO_8601 {}
