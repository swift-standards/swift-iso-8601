import Time

extension ISO_8601 {

    public struct Time: Sendable, Equatable, Hashable {

        public let hour: Int

        public let minute: Int?

        public let second: Int?

        public let nanoseconds: Int

        internal let _timezoneOffsetSeconds: Int?

        public init(
            hour: Int,
            minute: Int? = nil,
            second: Int? = nil,
            nanoseconds: Int = 0,
            timezoneOffsetSeconds: Int? = nil
        ) throws(ISO_8601.Date.Error) {

            guard (0...24).contains(hour) else {
                throw ISO_8601.Date.Error.hourOutOfRange(hour)
            }

            if hour == 24 {
                guard minute == nil || minute == 0,
                    second == nil || second == 0,
                    nanoseconds == 0
                else {
                    throw ISO_8601.Date.Error.invalidTime(
                        "24:xx:xx is not valid, only 24:00:00 is allowed"
                    )
                }
            }

            if let min = minute {
                guard (0...59).contains(min) else {
                    throw ISO_8601.Date.Error.minuteOutOfRange(min)
                }
            }

            if let sec = second {
                guard (0...60).contains(sec) else {
                    throw ISO_8601.Date.Error.secondOutOfRange(sec)
                }
            }

            guard (0..<1_000_000_000).contains(nanoseconds) else {
                throw ISO_8601.Date.Error.invalidFractionalSecond(String(nanoseconds))
            }

            self.hour = hour
            self.minute = minute
            self.second = second
            self.nanoseconds = nanoseconds
            self._timezoneOffsetSeconds = timezoneOffsetSeconds
        }
    }
}

extension ISO_8601.Time {

    public var timezone: Timezone {
        Timezone(time: self)
    }
}

extension ISO_8601.Time: CustomStringConvertible {
    public var description: String {
        Formatter.format(self)
    }
}

extension ISO_8601.Time: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = try Parser.parse(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
