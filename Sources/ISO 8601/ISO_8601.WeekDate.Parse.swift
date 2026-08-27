public import Byte
public import Parser

extension ISO_8601.WeekDate {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.WeekDate.Parse: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __ISO8601ParseError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let weekYear = try ISO_8601.Digits<Input>(count: 4).parse(&input)

        let extended: Bool
        if input.startIndex < input.endIndex && input[input.startIndex] == 0x2D {
            extended = true
            input = input[input.index(after: input.startIndex)...]
        } else {
            extended = false
        }

        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x57
        else {
            throw .expectedByte(0x57)
        }
        input = input[input.index(after: input.startIndex)...]

        let week = try ISO_8601.Digits<Input>(count: 2).parse(&input)
        guard week >= 1 && week <= 53 else {
            throw .invalidMonth(week)
        }

        if extended {
            guard
                input.startIndex < input.endIndex
                    && input[input.startIndex] == 0x2D
            else {
                throw .expectedByte(0x2D)
            }
            input = input[input.index(after: input.startIndex)...]
        }

        let weekday = try ISO_8601.Digits<Input>(count: 1).parse(&input)
        guard weekday >= 1 && weekday <= 7 else {
            throw .invalidDay(weekday)
        }

        return Output(weekYear: weekYear, week: week, weekday: weekday)
    }
}
