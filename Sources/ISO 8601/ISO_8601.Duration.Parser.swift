public import ASCII_Decimal_Parser
import Parser

extension ISO_8601.Duration {

    public struct Parser<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.Duration.Parser: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __DurationParserError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ISO_8601.Duration {

        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x50
        else {
            throw .expectedP
        }
        input = input[input.index(after: input.startIndex)...]

        var years = 0
        var months = 0
        var days = 0
        var hours = 0
        var minutes = 0
        var seconds = 0
        var nanoseconds = 0
        var inTimePart = false
        var hasComponent = false

        while input.startIndex < input.endIndex {
            let byte = input[input.startIndex]

            if byte == 0x54 {
                inTimePart = true
                input = input[input.index(after: input.startIndex)...]
                continue
            }

            guard byte >= 0x30 && byte <= 0x39 else { break }

            let value: Int
            do throws(ASCII.Decimal.Error) {
                value = try ASCII.Decimal.Parser<Input, Int>().parse(&input)
            } catch {
                switch error {
                case .overflow: throw .overflow

                case .noDigits, .insufficientDigits, .invalidSign: throw .invalidDigit
                }
            }

            var fracNanos = 0
            if input.startIndex < input.endIndex {
                let sep = input[input.startIndex]
                if sep == 0x2E || sep == 0x2C {
                    input = input[input.index(after: input.startIndex)...]
                    var fraction = 0
                    var digits = 0
                    while input.startIndex < input.endIndex {
                        let fb = input[input.startIndex]
                        guard fb >= 0x30 && fb <= 0x39 else { break }
                        if digits < 9 {
                            fraction = fraction &* 10 &+ Int(fb.underlying &- 0x30)
                        }
                        input = input[input.index(after: input.startIndex)...]
                        digits += 1
                    }
                    while digits < 9 {
                        fraction = fraction &* 10
                        digits += 1
                    }
                    fracNanos = fraction
                }
            }

            guard input.startIndex < input.endIndex else {
                throw .expectedComponentDesignator
            }
            let designator = input[input.startIndex]
            input = input[input.index(after: input.startIndex)...]
            hasComponent = true

            if inTimePart {
                switch designator {
                case 0x48: hours = value
                case 0x4D: minutes = value

                case 0x53:
                    seconds = value
                    nanoseconds = fracNanos

                default: throw .expectedComponentDesignator
                }
            } else {
                switch designator {
                case 0x59: years = value
                case 0x4D: months = value
                case 0x44: days = value
                default: throw .expectedComponentDesignator
                }
            }
        }

        guard hasComponent else { throw .emptyDuration }

        do throws(ISO_8601.Date.Error) {
            return try ISO_8601.Duration(
                years: years,
                months: months,
                days: days,
                hours: hours,
                minutes: minutes,
                seconds: seconds,
                nanoseconds: nanoseconds
            )
        } catch {
            throw .overflow
        }
    }
}
