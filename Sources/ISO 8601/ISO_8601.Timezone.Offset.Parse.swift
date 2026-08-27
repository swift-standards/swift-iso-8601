public import Byte
public import Parser

extension ISO_8601.Timezone.Offset {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.Timezone.Offset.Parse: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __ISO8601ParseError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        guard input.startIndex < input.endIndex else {
            throw .unexpectedEndOfInput
        }

        let first = input[input.startIndex]

        if first == 0x5A {
            input = input[input.index(after: input.startIndex)...]
            return Output(totalSeconds: 0)
        }

        let sign: Int
        if first == 0x2B {
            sign = 1
        } else if first == 0x2D {
            sign = -1
        } else {
            throw .expectedByte(0x5A)
        }
        input = input[input.index(after: input.startIndex)...]

        let hour = try ISO_8601.Digits<Input>(count: 2).parse(&input)

        var minute = 0
        if input.startIndex < input.endIndex {
            let next = input[input.startIndex]
            if next == 0x3A {
                input = input[input.index(after: input.startIndex)...]
                minute = try ISO_8601.Digits<Input>(count: 2).parse(&input)
            } else if next >= 0x30 && next <= 0x39 {
                minute = try ISO_8601.Digits<Input>(count: 2).parse(&input)
            }
        }

        return Output(totalSeconds: sign * (hour * 3600 + minute * 60))
    }
}
