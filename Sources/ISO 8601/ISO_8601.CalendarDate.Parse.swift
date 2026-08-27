public import Byte
public import Parser

extension ISO_8601.CalendarDate {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.CalendarDate.Parse: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __ISO8601ParseError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let year = try ISO_8601.Digits<Input>(count: 4).parse(&input)

        let extended: Bool
        if input.startIndex < input.endIndex && input[input.startIndex] == 0x2D {
            extended = true
            input = input[input.index(after: input.startIndex)...]
        } else {
            extended = false
        }

        let month = try ISO_8601.Digits<Input>(count: 2).parse(&input)
        guard month >= 1 && month <= 12 else { throw .invalidMonth(month) }

        if extended {
            guard
                input.startIndex < input.endIndex
                    && input[input.startIndex] == 0x2D
            else {
                throw .expectedByte(0x2D)
            }
            input = input[input.index(after: input.startIndex)...]
        }

        let day = try ISO_8601.Digits<Input>(count: 2).parse(&input)
        guard day >= 1 && day <= 31 else { throw .invalidDay(day) }

        return Output(year: year, month: month, day: day)
    }
}
