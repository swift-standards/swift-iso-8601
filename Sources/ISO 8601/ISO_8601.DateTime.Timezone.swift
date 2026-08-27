import Time

extension ISO_8601.DateTime {

    public struct Timezone: Sendable {
        internal let dateTime: ISO_8601.DateTime
    }
}

extension ISO_8601.DateTime.Timezone {

    public var offsetSeconds: Int {
        dateTime.timezoneOffset.seconds
    }
}
