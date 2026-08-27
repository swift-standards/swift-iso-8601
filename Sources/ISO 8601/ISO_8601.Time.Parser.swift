import Time

extension ISO_8601.Time {

    public enum Parser {}
}

extension ISO_8601.Time.Parser {

    public static func parse(_ value: String) throws(ISO_8601.Date.Error) -> ISO_8601.Time {

        var timePart = value
        var timezoneOffset: Int?

        if value.hasSuffix("Z") {
            timePart = String(value.dropLast())
            timezoneOffset = 0
        } else if let plusIndex = value.lastIndex(of: "+") {
            timePart = String(value[..<plusIndex])
            let tzPart = String(value[value.index(after: plusIndex)...])
            timezoneOffset = try parseTimezoneOffset(tzPart, positive: true)
        } else if let minusIndex = value.lastIndex(of: "-"), minusIndex != value.startIndex {
            timePart = String(value[..<minusIndex])
            let tzPart = String(value[value.index(after: minusIndex)...])
            timezoneOffset = try parseTimezoneOffset(tzPart, positive: false)
        }

        var hour: Int
        var minute: Int?
        var second: Int?
        var nanoseconds = 0

        if timePart.contains(":") {

            let parts = timePart.split(separator: ":").map(String.init)
            guard !parts.isEmpty else {
                throw ISO_8601.Date.Error.invalidTime("Empty time")
            }

            guard let h = Int(parts[0]) else {
                throw ISO_8601.Date.Error.invalidHour(parts[0])
            }
            hour = h

            if parts.count >= 2 {
                guard let m = Int(parts[1]) else {
                    throw ISO_8601.Date.Error.invalidMinute(parts[1])
                }
                minute = m

                if parts.count >= 3 {

                    let (sec, nano) = try parseFractionalSeconds(parts[2])
                    second = sec
                    nanoseconds = nano
                }
            }
        } else {

            let (intPart, fracPart) = extractFractionalPart(timePart)

            if intPart.count == 2 {

                guard let h = Int(intPart) else {
                    throw ISO_8601.Date.Error.invalidHour(intPart)
                }
                hour = h
            } else if intPart.count == 4 {

                let hourStr = String(intPart.prefix(2))
                let minuteStr = String(intPart.dropFirst(2))

                guard let h = Int(hourStr) else {
                    throw ISO_8601.Date.Error.invalidHour(hourStr)
                }
                guard let m = Int(minuteStr) else {
                    throw ISO_8601.Date.Error.invalidMinute(minuteStr)
                }

                hour = h
                minute = m
            } else if intPart.count == 6 || !fracPart.isEmpty {

                let hourStr = String(intPart.prefix(2))
                let minuteStr = String(intPart.dropFirst(2).prefix(2))
                let secondStr = String(intPart.dropFirst(4).prefix(2))

                guard let h = Int(hourStr) else {
                    throw ISO_8601.Date.Error.invalidHour(hourStr)
                }
                guard let m = Int(minuteStr) else {
                    throw ISO_8601.Date.Error.invalidMinute(minuteStr)
                }
                guard let s = Int(secondStr) else {
                    throw ISO_8601.Date.Error.invalidSecond(secondStr)
                }

                hour = h
                minute = m
                second = s

                if !fracPart.isEmpty {
                    nanoseconds = try parseFractionalPart(fracPart)
                }
            } else {
                throw ISO_8601.Date.Error.invalidTime("Invalid time length: \(intPart.count)")
            }
        }

        return try ISO_8601.Time(
            hour: hour,
            minute: minute,
            second: second,
            nanoseconds: nanoseconds,
            timezoneOffsetSeconds: timezoneOffset
        )
    }

    private static func parseFractionalSeconds(
        _ value: String
    ) throws(ISO_8601.Date.Error) -> (seconds: Int, nanoseconds: Int) {

        let separator: Character
        if value.contains(".") {
            separator = "."
        } else if value.contains(",") {
            separator = ","
        } else {

            guard let s = Int(value) else {
                throw ISO_8601.Date.Error.invalidSecond(value)
            }
            return (s, 0)
        }

        let comps = value.split(separator: separator).map(String.init)
        guard comps.count == 2 else {
            throw ISO_8601.Date.Error.invalidFormat("Invalid fractional seconds")
        }

        guard let sec = Int(comps[0]) else {
            throw ISO_8601.Date.Error.invalidSecond(comps[0])
        }

        let nano = try parseFractionalPart(comps[1])
        return (sec, nano)
    }

    private static func parseFractionalPart(
        _ fracStr: String
    ) throws(ISO_8601.Date.Error) -> Int {

        var paddedFrac = fracStr
        if fracStr.count < 9 {
            paddedFrac = fracStr + String(repeating: "0", count: 9 - fracStr.count)
        } else if fracStr.count > 9 {
            paddedFrac = String(fracStr.prefix(9))
        }
        guard let nano = Int(paddedFrac) else {
            throw ISO_8601.Date.Error.invalidFractionalSecond(fracStr)
        }
        return nano
    }

    private static func extractFractionalPart(
        _ value: String
    ) -> (intPart: String, fracPart: String) {
        if let dotIndex = value.firstIndex(of: ".") {
            return (String(value[..<dotIndex]), String(value[value.index(after: dotIndex)...]))
        } else if let commaIndex = value.firstIndex(of: ",") {
            return (
                String(value[..<commaIndex]), String(value[value.index(after: commaIndex)...])
            )
        } else {
            return (value, "")
        }
    }

    private static func parseTimezoneOffset(
        _ value: String,
        positive: Bool
    ) throws(ISO_8601.Date.Error) -> Int {
        let hours: Int
        let minutes: Int

        if value.contains(":") {

            let parts = value.split(separator: ":").map(String.init)
            guard parts.count == 2 else {
                throw ISO_8601.Date.Error.invalidFormat("Invalid timezone offset")
            }

            guard let h = Int(parts[0]) else {
                throw ISO_8601.Date.Error.invalidFormat("Invalid timezone hours")
            }
            guard let m = Int(parts[1]) else {
                throw ISO_8601.Date.Error.invalidFormat("Invalid timezone minutes")
            }

            hours = h
            minutes = m
        } else {

            guard value.count == 4 else {
                throw ISO_8601.Date.Error.invalidFormat("Invalid timezone offset length")
            }

            let hoursStr = String(value.prefix(2))
            let minutesStr = String(value.dropFirst(2))

            guard let h = Int(hoursStr) else {
                throw ISO_8601.Date.Error.invalidFormat("Invalid timezone hours")
            }
            guard let m = Int(minutesStr) else {
                throw ISO_8601.Date.Error.invalidFormat("Invalid timezone minutes")
            }

            hours = h
            minutes = m
        }

        let offset =
            hours * Time.Time.Calendar.Gregorian.TimeConstants.secondsPerHour
            + minutes
            * Time.Time.Calendar.Gregorian.TimeConstants.secondsPerMinute
        return positive ? offset : -offset
    }
}
