import Time

extension ISO_8601.Time {

    public enum Formatter {}
}

extension ISO_8601.Time.Formatter {

    public static func format(_ value: ISO_8601.Time, format: Format = .extended) -> String {
        let extended = format == .extended
        var result = ""

        let hourStr = value.hour < 10 ? "0\(value.hour)" : "\(value.hour)"

        if let minute = value.minute {
            let minStr = minute < 10 ? "0\(minute)" : "\(minute)"

            if let second = value.second {
                let secStr = second < 10 ? "0\(second)" : "\(second)"

                if extended {
                    result = "\(hourStr):\(minStr):\(secStr)"
                } else {
                    result = "\(hourStr)\(minStr)\(secStr)"
                }

                if value.nanoseconds > 0 {
                    result += formatFractionalSeconds(value.nanoseconds)
                }
            } else {

                if extended {
                    result = "\(hourStr):\(minStr)"
                } else {
                    result = "\(hourStr)\(minStr)"
                }
            }
        } else {

            result = hourStr
        }

        if let offset = value.timezone.offsetSeconds {
            if offset == 0 {
                result += "Z"
            } else {
                result += formatTimezoneOffset(offset, extended: extended)
            }
        }

        return result
    }

    private static func formatFractionalSeconds(_ nanoseconds: Int) -> String {

        var nano = nanoseconds
        while nano > 0 && nano % 10 == 0 {
            nano /= 10
        }

        if nano == 0 {
            return ""
        }

        return ".\(nano)"
    }

    private static func formatTimezoneOffset(_ offsetSeconds: Int, extended: Bool) -> String {
        let sign = offsetSeconds >= 0 ? "+" : "-"
        let absOffset = abs(offsetSeconds)
        let hours =
            absOffset / Time.Time.Calendar.Gregorian.TimeConstants.secondsPerHour
        let minutes =
            (absOffset % Time.Time.Calendar.Gregorian.TimeConstants.secondsPerHour)
            / Time.Time.Calendar.Gregorian.TimeConstants.secondsPerMinute

        let hoursStr = hours < 10 ? "0\(hours)" : "\(hours)"
        let minutesStr = minutes < 10 ? "0\(minutes)" : "\(minutes)"

        if extended {
            return "\(sign)\(hoursStr):\(minutesStr)"
        } else {
            return "\(sign)\(hoursStr)\(minutesStr)"
        }
    }
}
