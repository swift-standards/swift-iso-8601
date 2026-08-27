import Byte_Parser
import Parser

extension ISO_8601 {

    public struct Duration: Sendable, Equatable, Hashable {

        public let years: Int

        public let months: Int

        public let days: Int

        public let hours: Int

        public let minutes: Int

        public let seconds: Int

        public let nanoseconds: Int

        public init(
            years: Int = 0,
            months: Int = 0,
            days: Int = 0,
            hours: Int = 0,
            minutes: Int = 0,
            seconds: Int = 0,
            nanoseconds: Int = 0
        ) throws(ISO_8601.Date.Error) {
            guard (0..<1_000_000_000).contains(nanoseconds) else {
                throw ISO_8601.Date.Error.invalidFractionalSecond(String(nanoseconds))
            }

            self.years = years
            self.months = months
            self.days = days
            self.hours = hours
            self.minutes = minutes
            self.seconds = seconds
            self.nanoseconds = nanoseconds
        }
    }
}

extension ISO_8601.Duration {

    public var isZero: Bool {
        years == 0 && months == 0 && days == 0 && hours == 0 && minutes == 0 && seconds == 0
            && nanoseconds == 0
    }
}

extension ISO_8601.Duration: CustomStringConvertible {
    public var description: String {
        Formatter.format(self)
    }
}

extension ISO_8601.Duration: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = try ISO_8601.Duration(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension ISO_8601.Duration {

    public init(_ string: String) throws(ISO_8601.Duration.Parser.Error) {
        var input = Byte.Input(utf8: string)
        let value = try ISO_8601.Duration.Parser<Byte.Input>().parse(&input)
        guard input.isEmpty else { throw .unexpectedTrailingInput }
        self = value
    }
}
