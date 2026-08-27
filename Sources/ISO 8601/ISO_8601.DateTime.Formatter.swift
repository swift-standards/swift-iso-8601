import Time

extension ISO_8601.DateTime {

    public enum Formatter {}
}

extension ISO_8601.DateTime.Formatter {

    public static func format(
        _ value: ISO_8601.DateTime,
        date: DateFormat = .calendar(extended: true),
        time: TimeFormat = .time(extended: true),
        timezone: TimezoneFormat = .utc
    ) -> String {
        var result = ""

        switch time {
        case .none:

            result += formatDatePortion(value, format: date)

        case .time(let extended):

            let renderValue = renderedValue(for: value, timezone: timezone)

            result += formatDatePortion(renderValue, format: date)
            result += "T"
            result += formatTime(renderValue, extended: extended)

            switch timezone {
            case .none:
                break

            case .utc:
                result += "Z"

            case .offset(let offsetExtended):
                result += formatTimezoneOffset(
                    value.timezone.offsetSeconds,
                    extended: offsetExtended
                )
            }
        }

        return result
    }

    private static func formatDatePortion(
        _ value: ISO_8601.DateTime,
        format: DateFormat
    )
        -> String
    {
        switch format {
        case .calendar(let extended):
            return formatCalendarDate(value, extended: extended)

        case .week(let extended):
            return formatWeekDate(value, extended: extended)

        case .ordinal(let extended):
            return formatOrdinalDate(value, extended: extended)
        }
    }

    private static func renderedValue(
        for value: ISO_8601.DateTime,
        timezone: TimezoneFormat
    ) -> ISO_8601.DateTime {
        switch timezone {
        case .utc:

            let utcTime: Time.Time
            do {
                utcTime = try Time.Time(
                    secondsSinceEpoch: value.epoch.seconds,
                    nanoseconds: value.nanoseconds
                )
            } catch {
                fatalError(
                    "ISO_8601.DateTime.Formatter: nanoseconds of a valid DateTime were out of range — \(error)"
                )
            }
            return ISO_8601.DateTime(time: utcTime, timezoneOffset: .utc)

        case .none, .offset:
            return value
        }
    }
}

extension ISO_8601.DateTime.Formatter {
    private static func formatCalendarDate(_ value: ISO_8601.DateTime, extended: Bool) -> String {
        let comp = value.components
        let year = formatFourDigits(comp.year)
        let month = formatTwoDigits(comp.month)
        let day = formatTwoDigits(comp.day)

        if extended {
            return "\(year)-\(month)-\(day)"
        } else {
            return "\(year)\(month)\(day)"
        }
    }

    private static func formatWeekDate(_ value: ISO_8601.DateTime, extended: Bool) -> String {
        let year = formatFourDigits(value.isoWeekYear)
        let week = formatTwoDigits(value.isoWeek)
        let weekday = value.isoWeekday

        if extended {
            return "\(year)-W\(week)-\(weekday)"
        } else {
            return "\(year)W\(week)\(weekday)"
        }
    }

    private static func formatOrdinalDate(_ value: ISO_8601.DateTime, extended: Bool) -> String {
        let comp = value.components
        let year = formatFourDigits(comp.year)
        let day = formatThreeDigits(value.ordinalDay)

        if extended {
            return "\(year)-\(day)"
        } else {
            return "\(year)\(day)"
        }
    }

    private static func formatTime(_ value: ISO_8601.DateTime, extended: Bool) -> String {
        let comp = value.components
        let hour = formatTwoDigits(comp.hour)
        let minute = formatTwoDigits(comp.minute)
        let second = formatTwoDigits(comp.second)

        var result: String
        if extended {
            result = "\(hour):\(minute):\(second)"
        } else {
            result = "\(hour)\(minute)\(second)"
        }

        if comp.nanoseconds > 0 {
            result += formatFractionalSeconds(comp.nanoseconds)
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
        let hours = absOffset / Time.Calendar.Gregorian.TimeConstants.secondsPerHour
        let minutes =
            (absOffset % Time.Calendar.Gregorian.TimeConstants.secondsPerHour)
            / Time.Calendar.Gregorian.TimeConstants.secondsPerMinute

        let hoursStr = formatTwoDigits(hours)
        let minutesStr = formatTwoDigits(minutes)

        if extended {
            return "\(sign)\(hoursStr):\(minutesStr)"
        } else {
            return "\(sign)\(hoursStr)\(minutesStr)"
        }
    }
}

extension ISO_8601.DateTime.Formatter {

    private static func formatTwoDigits(_ value: Int) -> String {
        let tens = value / 10
        let ones = value % 10
        return "\(tens)\(ones)"
    }

    private static func formatThreeDigits(_ value: Int) -> String {
        let hundreds = value / 100
        let tens = (value % 100) / 10
        let ones = value % 10
        return "\(hundreds)\(tens)\(ones)"
    }

    private static func formatFourDigits(_ value: Int) -> String {
        let thousands = value / 1000
        let hundreds = (value % 1000) / 100
        let tens = (value % 100) / 10
        let ones = value % 10
        return "\(thousands)\(hundreds)\(tens)\(ones)"
    }
}
