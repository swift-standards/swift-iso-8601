# swift-iso-8601

Swift implementation of ISO 8601:2019 date and time format.

## Overview

This package provides a **Swift encoding of the ISO 8601:2019 standard** following the same organizational patterns as [swift-rfc-5322](../swift-rfc-5322).

## Status

🚧 **In Development** - See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for implementation details.

## Design Principle

This package mirrors the structure and patterns of `swift-rfc-5322`:

- **Same module organization**: `ISO_8601.DateTime`, `ISO_8601.Date.Components`
- **Same nested types**: `DateTime.Formatter`, `DateTime.Parser` (via extensions)
- **Same naming conventions**: Descriptive, full-word property names
- **Same error handling**: Typed errors nested under parent types
- **Same test patterns**: Comprehensive, descriptive test names

**The goal:** Create a consistent family of date-time packages where only the format-specific logic differs.

## Supported Formats

ISO 8601 supports three date representations:

### Calendar Date
```swift
// Extended format
"2024-01-15T12:30:00Z"

// Basic format
"20240115T123000Z"
```

### Week Date
```swift
// Extended format
"2024-W03-2T12:30:00Z"  // Year 2024, Week 3, Tuesday

// Basic format
"2024W032T123000Z"
```

### Ordinal Date
```swift
// Extended format
"2024-039T12:30:00Z"  // Year 2024, day 39

// Basic format
"2024039T123000Z"
```

## Relationship to RFC 5322

Both packages encode different standards but share identical Swift patterns:

| Aspect | RFC 5322 | ISO 8601 |
|--------|----------|----------|
| **Format** | `Mon, 15 Jan 2024 12:30:00 +0000` | `2024-01-15T12:30:00Z` |
| **Module** | `RFC_5322` | `ISO_8601` |
| **Core Type** | `RFC_5322.DateTime` | `ISO_8601.DateTime` |
| **Components** | `RFC_5322.Date.Components` | `ISO_8601.Date.Components` |
| **Formatter** | `RFC_5322.DateTime.Formatter` | `ISO_8601.DateTime.Formatter` |
| **Parser** | `RFC_5322.DateTime.Parser` | `ISO_8601.DateTime.Parser` |

**Shared underlying logic** (will be extracted to `Standards/Time` after Phase 2):
- Gregorian calendar calculations
- Leap year logic
- Epoch seconds ↔ date components conversion
- Component validation

## Implementation Status

- [x] Package structure created
- [x] Implementation guide written
- [ ] Core DateTime implementation
- [ ] Components validation
- [ ] Calendar date format
- [ ] Week date format
- [ ] Ordinal date format
- [ ] Parser implementation
- [ ] Comprehensive tests
- [ ] Duplication analysis
- [ ] Standards/Time extraction decision

See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for detailed implementation instructions.

## Architecture Strategy

This package follows the **Hybrid Approach**:

1. **Phase 1:** Implement ISO 8601 independently (copying from RFC 5322)
2. **Phase 2:** Analyze actual code overlap
3. **Phase 3:** Extract common logic to `Standards/Time` target if criteria met

This ensures evidence-based architectural decisions rather than premature abstraction.

## Installation

Add as a dependency in Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-iso-8601.git", from: "0.1.0")
]
```

## Usage (Planned)

```swift
import ISO_8601

// Create from components
let dt = try ISO_8601.DateTime(
    year: 2024,
    month: 1,
    day: 15,
    hour: 12,
    minute: 30,
    second: 0
)

// Format as calendar date
let formatted = ISO_8601.DateTime.Formatter.format(
    dt,
    date: .calendar(extended: true),
    time: .time(extended: true),
    timezone: .utc
)
// "2024-01-15T12:30:00Z"

// Parse from string
let parsed = try ISO_8601.DateTime.Parser.parse("2024-01-15T12:30:00Z")

// Convert to week date
let weekDate = ISO_8601.WeekDate(dt)
// ISO_8601.WeekDate(weekYear: 2024, week: 3, weekday: 1)

// Convert to ordinal date
let ordinal = ISO_8601.OrdinalDate(dt)
// ISO_8601.OrdinalDate(year: 2024, day: 15)
```

## Contributing

See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for implementation patterns and conventions.

**Important:** Follow RFC 5322's organizational patterns exactly to maintain consistency across the swift-standards package family.

## License

MIT

## References

- [ISO 8601:2019](https://www.iso.org/iso-8601-date-and-time-format.html) - Official standard
- [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339.html) - ISO 8601 profile for Internet protocols
- [swift-rfc-5322](../swift-rfc-5322) - Reference implementation for patterns
