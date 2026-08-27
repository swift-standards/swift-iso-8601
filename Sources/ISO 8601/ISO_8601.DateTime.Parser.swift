public import Byte
public import Parser
public import Time

extension ISO_8601.DateTime {

    public struct Parser<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.DateTime.Parser: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __DateTimeParserError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ISO_8601.DateTime {

        var probe = input.startIndex
        var hasWeekDesignator = false
        var dashCount = 0
        var fieldLength = 0
        while probe < input.endIndex {
            let byte = input[probe]
            if byte == 0x54 || byte == 0x2F { break }
            if byte == 0x57 {
                hasWeekDesignator = true
            } else if byte == 0x2D {
                dashCount += 1
            }
            fieldLength += 1
            input.formIndex(after: &probe)
        }

        let isWeek = hasWeekDesignator
        let isOrdinal =
            !hasWeekDesignator && (dashCount == 1 || (dashCount == 0 && fieldLength == 7))

        let year: Int
        let month: Int
        let day: Int
        if isWeek {
            let parsed: ISO_8601.WeekDate.Parse<Input>.Output
            do throws(__ISO8601ParseError) {
                parsed = try ISO_8601.WeekDate.Parse<Input>().parse(&input)
            } catch {
                throw .dateError(error)
            }
            let weekDate: ISO_8601.WeekDate
            do throws(ISO_8601.Date.Error) {
                weekDate = try ISO_8601.WeekDate(
                    weekYear: parsed.weekYear,
                    week: parsed.week,
                    weekday: parsed.weekday
                )
            } catch {
                throw .invalidComponents(error)
            }
            let components = ISO_8601.DateTime(weekDate).components
            (year, month, day) = (components.year, components.month, components.day)
        } else if isOrdinal {
            let parsed: ISO_8601.OrdinalDate.Parse<Input>.Output
            do throws(__ISO8601ParseError) {
                parsed = try ISO_8601.OrdinalDate.Parse<Input>().parse(&input)
            } catch {
                throw .dateError(error)
            }
            let ordinalDate: ISO_8601.OrdinalDate
            do throws(ISO_8601.Date.Error) {
                ordinalDate = try ISO_8601.OrdinalDate(year: parsed.year, day: parsed.day)
            } catch {
                throw .invalidComponents(error)
            }
            let components = ISO_8601.DateTime(ordinalDate).components
            (year, month, day) = (components.year, components.month, components.day)
        } else {
            let parsed: ISO_8601.CalendarDate.Parse<Input>.Output
            do throws(__ISO8601ParseError) {
                parsed = try ISO_8601.CalendarDate.Parse<Input>().parse(&input)
            } catch {
                throw .dateError(error)
            }
            (year, month, day) = (parsed.year, parsed.month, parsed.day)
        }

        var hour = 0
        var minute = 0
        var second = 0
        var nanoseconds = 0
        if input.startIndex < input.endIndex, input[input.startIndex] == 0x54 {
            input = input[input.index(after: input.startIndex)...]
            let time: ISO_8601.Time.Parse<Input>.Output
            do throws(__ISO8601ParseError) {
                time = try ISO_8601.Time.Parse<Input>().parse(&input)
            } catch {
                throw .timeError(error)
            }
            (hour, minute, second, nanoseconds) =
                (time.hour, time.minute, time.second, time.nanoseconds)
        }

        var timezoneOffset = 0
        if input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            if byte == 0x5A || byte == 0x2B || byte == 0x2D {
                let offset: ISO_8601.Timezone.Offset.Parse<Input>.Output
                do throws(__ISO8601ParseError) {
                    offset = try ISO_8601.Timezone.Offset.Parse<Input>().parse(&input)
                } catch {
                    throw .timezoneError(error)
                }
                timezoneOffset = offset.totalSeconds
            }
        }

        if hour == 24 {
            guard minute == 0, second == 0, nanoseconds == 0 else {
                throw .invalidComponents(
                    .invalidTime("24:xx:xx is not valid, only 24:00:00 is allowed")
                )
            }

            let localMidnight: Time.Time
            do throws(Time.Time.Error) {
                localMidnight = try Time.Time(
                    year: year,
                    month: month,
                    day: day,
                    hour: 0,
                    minute: 0,
                    second: 0
                )
            } catch {
                throw .invalidComponents(.invalidComponents(error))
            }
            let trueEpochOfMidnight = localMidnight.secondsSinceEpoch - timezoneOffset
            do throws(ISO_8601.Date.Error) {
                return try ISO_8601.DateTime(
                    secondsSinceEpoch: trueEpochOfMidnight
                        + Time.Time.Calendar.Gregorian.TimeConstants.secondsPerDay,
                    nanoseconds: 0,
                    timezoneOffsetSeconds: timezoneOffset
                )
            } catch {
                throw .invalidComponents(error)
            }
        }

        let millisecond = nanoseconds / 1_000_000
        let microsecondRemainder = nanoseconds % 1_000_000
        let microsecond = microsecondRemainder / 1000
        let nanosecond = microsecondRemainder % 1000

        let localTime: Time.Time
        do throws(Time.Time.Error) {
            localTime = try Time.Time(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second,
                millisecond: millisecond,
                microsecond: microsecond,
                nanosecond: nanosecond
            )
        } catch {
            throw .invalidComponents(.invalidComponents(error))
        }
        let trueEpochSeconds = localTime.secondsSinceEpoch - timezoneOffset

        do throws(ISO_8601.Date.Error) {
            return try ISO_8601.DateTime(
                secondsSinceEpoch: trueEpochSeconds,
                nanoseconds: nanoseconds,
                timezoneOffsetSeconds: timezoneOffset
            )
        } catch {
            throw .invalidComponents(error)
        }
    }
}
