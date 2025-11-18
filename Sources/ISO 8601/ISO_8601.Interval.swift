//
//  ISO_8601.Interval.swift
//  swift-iso-8601
//
//  ISO 8601 Time Interval representation
//

extension ISO_8601 {
    /// ISO 8601 Time Interval representation
    ///
    /// Represents a time interval using one of four formats per ISO 8601:2019.
    ///
    /// ## Four Interval Formats
    ///
    /// 1. **Start and End**: `2019-08-27/2019-08-29`
    /// 2. **Duration Only**: `P3D`
    /// 3. **Start and Duration**: `2019-08-27/P3D`
    /// 4. **Duration and End**: `P3D/2019-08-29`
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Start and end
    /// let start = try ISO_8601.DateTime(year: 2019, month: 8, day: 27)
    /// let end = try ISO_8601.DateTime(year: 2019, month: 8, day: 29)
    /// let interval = ISO_8601.Interval.startEnd(start: start, end: end)
    ///
    /// // Start and duration
    /// let duration = try ISO_8601.Duration(days: 3)
    /// let interval2 = ISO_8601.Interval.startDuration(start: start, duration: duration)
    ///
    /// // Parse from string
    /// let parsed = try ISO_8601.Interval.Parser.parse("2019-08-27/P3D")
    /// ```
    public enum Interval: Sendable, Equatable, Hashable {
        /// Interval defined by start and end date-times
        case startEnd(start: DateTime, end: DateTime)

        /// Interval defined only by duration (no specific start/end)
        case duration(Duration)

        /// Interval defined by start and duration
        case startDuration(start: DateTime, duration: Duration)

        /// Interval defined by duration and end
        case durationEnd(duration: Duration, end: DateTime)
    }
}

// MARK: - Formatting

extension ISO_8601.Interval: CustomStringConvertible {
    public var description: String {
        Formatter.format(self)
    }
}

extension ISO_8601.Interval {
    /// Formatter for ISO 8601 interval strings
    public enum Formatter {
        /// Format an interval as an ISO 8601 string
        ///
        /// - Parameter value: The interval to format
        /// - Returns: ISO 8601 interval string (e.g., "2019-08-27/2019-08-29")
        public static func format(_ value: ISO_8601.Interval) -> String {
            switch value {
            case .startEnd(let start, let end):
                let startStr = ISO_8601.DateTime.Formatter.format(start)
                let endStr = ISO_8601.DateTime.Formatter.format(end)
                return "\(startStr)/\(endStr)"

            case .duration(let duration):
                return duration.description

            case .startDuration(let start, let duration):
                let startStr = ISO_8601.DateTime.Formatter.format(start)
                let durationStr = duration.description
                return "\(startStr)/\(durationStr)"

            case .durationEnd(let duration, let end):
                let durationStr = duration.description
                let endStr = ISO_8601.DateTime.Formatter.format(end)
                return "\(durationStr)/\(endStr)"
            }
        }
    }
}

// MARK: - Parsing

extension ISO_8601.Interval {
    /// Parser for ISO 8601 interval strings
    public enum Parser {
        /// Parse an ISO 8601 interval string
        ///
        /// - Parameter value: The interval string (e.g., "2019-08-27/2019-08-29", "P3D", "2019-08-27/P3D")
        /// - Returns: Interval instance
        /// - Throws: `ISO_8601.Date.Error` if parsing fails
        public static func parse(_ value: String) throws -> ISO_8601.Interval {
            // Check if it's a duration-only interval (starts with P, no slash)
            if value.hasPrefix("P") && !value.contains("/") {
                let duration = try ISO_8601.Duration.Parser.parse(value)
                return .duration(duration)
            }

            // Split on slash
            let parts = value.split(separator: "/", maxSplits: 1).map(String.init)
            guard parts.count == 2 else {
                throw ISO_8601.Date.Error.invalidFormat("Interval must have format: start/end, start/duration, or duration/end")
            }

            let first = parts[0]
            let second = parts[1]

            // Determine which format based on presence of 'P'
            let firstIsDuration = first.hasPrefix("P")
            let secondIsDuration = second.hasPrefix("P")

            if firstIsDuration && secondIsDuration {
                throw ISO_8601.Date.Error.invalidFormat("Interval cannot have two durations")
            }

            if firstIsDuration {
                // Duration/End
                let duration = try ISO_8601.Duration.Parser.parse(first)
                let end = try ISO_8601.DateTime.Parser.parse(second)
                return .durationEnd(duration: duration, end: end)
            } else if secondIsDuration {
                // Start/Duration
                let start = try ISO_8601.DateTime.Parser.parse(first)
                let duration = try ISO_8601.Duration.Parser.parse(second)
                return .startDuration(start: start, duration: duration)
            } else {
                // Start/End
                let start = try ISO_8601.DateTime.Parser.parse(first)
                let end = try ISO_8601.DateTime.Parser.parse(second)
                return .startEnd(start: start, end: end)
            }
        }
    }
}

// MARK: - Codable

extension ISO_8601.Interval: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = try Parser.parse(string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

// MARK: - Helpers

extension ISO_8601.Interval {
    /// Check if this interval has a defined start
    public var hasStart: Bool {
        switch self {
        case .startEnd, .startDuration:
            return true
        case .duration, .durationEnd:
            return false
        }
    }

    /// Check if this interval has a defined end
    public var hasEnd: Bool {
        switch self {
        case .startEnd, .durationEnd:
            return true
        case .duration, .startDuration:
            return false
        }
    }

    /// Check if this interval has a defined duration
    public var hasDuration: Bool {
        switch self {
        case .duration, .startDuration, .durationEnd:
            return true
        case .startEnd:
            return false
        }
    }

    /// Get the start date-time if defined
    public var start: ISO_8601.DateTime? {
        switch self {
        case .startEnd(let start, _), .startDuration(let start, _):
            return start
        case .duration, .durationEnd:
            return nil
        }
    }

    /// Get the end date-time if defined
    public var end: ISO_8601.DateTime? {
        switch self {
        case .startEnd(_, let end), .durationEnd(_, let end):
            return end
        case .duration, .startDuration:
            return nil
        }
    }

    /// Get the duration if defined
    public var duration: ISO_8601.Duration? {
        switch self {
        case .duration(let dur), .startDuration(_, let dur), .durationEnd(let dur, _):
            return dur
        case .startEnd:
            return nil
        }
    }
}
