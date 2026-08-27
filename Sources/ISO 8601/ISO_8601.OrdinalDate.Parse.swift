public import Byte
public import Parser

extension ISO_8601.OrdinalDate {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.OrdinalDate.Parse: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __ISO8601ParseError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let year = try ISO_8601.Digits<Input>(count: 4).parse(&input)

        if input.startIndex < input.endIndex && input[input.startIndex] == 0x2D {
            input = input[input.index(after: input.startIndex)...]
        }

        let day = try ISO_8601.Digits<Input>(count: 3).parse(&input)
        guard day >= 1 && day <= 366 else {
            throw .invalidDay(day)
        }

        return Output(year: year, day: day)
    }
}
