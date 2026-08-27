public import ASCII_Decimal_Parser
import Parser

extension ISO_8601 {

    @usableFromInline
    struct Digits<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @usableFromInline
        let count: Int

        @inlinable
        package init(count: Int) {
            self.count = count
        }
    }
}

extension ISO_8601.Digits: Parser.`Protocol` {
    @usableFromInline
    typealias Body = Never
    @usableFromInline
    typealias Output = Int
    @usableFromInline
    typealias Failure = __ISO8601ParseError

    @inlinable
    package func parse(_ input: inout Input) throws(Failure) -> Int {
        do throws(ASCII.Decimal.Error) {
            return try ASCII.Decimal.Parser<Input, Int>(count: .exactly(count)).parse(&input)
        } catch {
            switch error {
            case .insufficientDigits: throw .expectedDigit
            case .noDigits: throw .expectedDigit
            case .overflow: throw .overflow
            case .invalidSign: throw .expectedDigit
            }
        }
    }
}
