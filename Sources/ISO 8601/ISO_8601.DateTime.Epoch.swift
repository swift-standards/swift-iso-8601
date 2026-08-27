import Time

extension ISO_8601.DateTime {

    public struct Epoch: Sendable {
        internal let dateTime: ISO_8601.DateTime
    }
}

extension ISO_8601.DateTime.Epoch {

    public var seconds: Int {
        dateTime.time.secondsSinceEpoch
    }
}
