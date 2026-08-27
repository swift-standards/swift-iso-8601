public import ASCII_Decimal_Parser
import Parser

extension ISO_8601.RecurringInterval {

    public struct Parser<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ISO_8601.RecurringInterval.Parser: Parser.`Protocol` {
    public typealias Body = Never
    public typealias Failure = __RecurringIntervalParserError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ISO_8601.RecurringInterval {

        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x52
        else {
            throw .expectedR
        }
        input = input[input.index(after: input.startIndex)...]

        var repetitions: Int? = nil
        if input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            if byte >= 0x30 && byte <= 0x39 {

                do throws(ASCII.Decimal.Error) {
                    repetitions = try ASCII.Decimal.Parser<Input, Int>().parse(&input)
                } catch {
                    switch error {
                    case .overflow: throw .overflow

                    case .noDigits, .insufficientDigits, .invalidSign: throw .expectedSlash
                    }
                }
            }
        }

        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x2F
        else {
            throw .expectedSlash
        }
        input = input[input.index(after: input.startIndex)...]

        let interval: ISO_8601.Interval
        do throws(__IntervalParserError) {
            interval = try ISO_8601.Interval.Parser<Input>().parse(&input)
        } catch {
            throw .intervalError(error)
        }

        do throws(ISO_8601.Date.Error) {
            return try ISO_8601.RecurringInterval(repetitions: repetitions, interval: interval)
        } catch {
            throw .overflow
        }
    }
}
