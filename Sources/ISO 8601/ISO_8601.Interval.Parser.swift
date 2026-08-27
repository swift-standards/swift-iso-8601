public import Byte
public import Parser

extension ISO_8601.Interval {

    public struct Parser<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.Interval.Parser: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __IntervalParserError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ISO_8601.Interval {
        guard input.startIndex < input.endIndex else {
            throw .dateTimeError(.expectedT)
        }

        if input[input.startIndex] == 0x50 {
            let duration: ISO_8601.Duration
            do throws(__DurationParserError) {
                duration = try ISO_8601.Duration.Parser<Input>().parse(&input)
            } catch {
                throw .durationError(error)
            }

            guard input.startIndex < input.endIndex else {
                return .duration(duration)
            }
            guard input[input.startIndex] == 0x2F else {
                return .duration(duration)
            }
            input = input[input.index(after: input.startIndex)...]

            let end: ISO_8601.DateTime
            do throws(__DateTimeParserError) {
                end = try ISO_8601.DateTime.Parser<Input>().parse(&input)
            } catch {
                throw .dateTimeError(error)
            }
            return .durationEnd(duration: duration, end: end)
        }

        let start: ISO_8601.DateTime
        do throws(__DateTimeParserError) {
            start = try ISO_8601.DateTime.Parser<Input>().parse(&input)
        } catch {
            throw .dateTimeError(error)
        }

        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x2F
        else {
            throw .expectedSlash
        }
        input = input[input.index(after: input.startIndex)...]

        guard input.startIndex < input.endIndex else {
            throw .dateTimeError(.expectedT)
        }

        if input[input.startIndex] == 0x50 {
            let duration: ISO_8601.Duration
            do throws(__DurationParserError) {
                duration = try ISO_8601.Duration.Parser<Input>().parse(&input)
            } catch {
                throw .durationError(error)
            }
            return .startDuration(start: start, duration: duration)
        }

        let end: ISO_8601.DateTime
        do throws(__DateTimeParserError) {
            end = try ISO_8601.DateTime.Parser<Input>().parse(&input)
        } catch {
            throw .dateTimeError(error)
        }
        return .startEnd(start: start, end: end)
    }
}
