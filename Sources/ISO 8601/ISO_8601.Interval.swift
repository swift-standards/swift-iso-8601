import Byte_Parser
import Parser

extension ISO_8601 {

    public enum Interval: Sendable, Equatable, Hashable {

        case startEnd(start: DateTime, end: DateTime)

        case duration(Duration)

        case startDuration(start: DateTime, duration: Duration)

        case durationEnd(duration: Duration, end: DateTime)
    }
}

extension ISO_8601.Interval: CustomStringConvertible {
    public var description: String {
        Formatter.format(self)
    }
}

extension ISO_8601.Interval: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = try ISO_8601.Interval(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension ISO_8601.Interval {

    public var hasStart: Bool {
        switch self {
        case .startEnd, .startDuration:
            return true

        case .duration, .durationEnd:
            return false
        }
    }

    public var hasEnd: Bool {
        switch self {
        case .startEnd, .durationEnd:
            return true

        case .duration, .startDuration:
            return false
        }
    }

    public var hasDuration: Bool {
        switch self {
        case .duration, .startDuration, .durationEnd:
            return true

        case .startEnd:
            return false
        }
    }

    public var start: ISO_8601.DateTime? {
        switch self {
        case .startEnd(let start, _), .startDuration(let start, _):
            return start

        case .duration, .durationEnd:
            return nil
        }
    }

    public var end: ISO_8601.DateTime? {
        switch self {
        case .startEnd(_, let end), .durationEnd(_, let end):
            return end

        case .duration, .startDuration:
            return nil
        }
    }

    public var duration: ISO_8601.Duration? {
        switch self {
        case .duration(let dur), .startDuration(_, let dur), .durationEnd(let dur, _):
            return dur

        case .startEnd:
            return nil
        }
    }
}

extension ISO_8601.Interval {

    public init(_ string: String) throws(ISO_8601.Interval.Parser.Error) {
        var input = Byte.Input(utf8: string)
        let value = try ISO_8601.Interval.Parser<Byte.Input>().parse(&input)
        guard input.isEmpty else { throw .unexpectedTrailingInput }
        self = value
    }
}
