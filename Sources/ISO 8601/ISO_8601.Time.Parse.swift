public import Byte
public import Parser

extension ISO_8601.Time {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.Time.Parse: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __ISO8601ParseError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let hour = try ISO_8601.Digits<Input>(count: 2).parse(&input)
        guard hour >= 0 && hour <= 24 else { throw .invalidHour(hour) }

        let extended: Bool
        if input.startIndex < input.endIndex && input[input.startIndex] == 0x3A {
            extended = true
            input = input[input.index(after: input.startIndex)...]
        } else {
            extended = false
        }

        let minute = try ISO_8601.Digits<Input>(count: 2).parse(&input)
        guard minute >= 0 && minute <= 59 else { throw .invalidMinute(minute) }

        let hasSeconds: Bool
        if extended {
            if input.startIndex < input.endIndex && input[input.startIndex] == 0x3A {
                input = input[input.index(after: input.startIndex)...]
                hasSeconds = true
            } else {
                hasSeconds = false
            }
        } else if input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            hasSeconds = byte >= 0x30 && byte <= 0x39
        } else {
            hasSeconds = false
        }

        var second = 0
        var nanoseconds = 0
        if hasSeconds {
            second = try ISO_8601.Digits<Input>(count: 2).parse(&input)

            guard second >= 0 && second <= 60 else { throw .invalidSecond(second) }

            if input.startIndex < input.endIndex {
                let sep = input[input.startIndex]
                if sep == 0x2E || sep == 0x2C {
                    input = input[input.index(after: input.startIndex)...]
                    var fraction = 0
                    var digits = 0
                    var index = input.startIndex
                    while index < input.endIndex {
                        let byte = input[index]
                        guard byte >= 0x30 && byte <= 0x39 else { break }
                        if digits < 9 {
                            fraction = fraction &* 10 &+ Int(byte.underlying &- 0x30)
                        }
                        input.formIndex(after: &index)
                        digits += 1
                    }
                    input = input[index...]

                    while digits < 9 {
                        fraction = fraction &* 10
                        digits += 1
                    }
                    nanoseconds = fraction
                }
            }
        }

        return Output(
            hour: hour,
            minute: minute,
            second: second,
            nanoseconds: nanoseconds
        )
    }
}
