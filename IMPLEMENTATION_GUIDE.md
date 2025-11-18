# ISO 8601 Implementation Guide

## Overview

**This is a Swift encoding of the ISO 8601:2019 standard that follows RFC 5322's organization, patterns, and naming conventions.**

### Design Principle: Mirror RFC 5322 Structure

The swift-iso-8601 package is a **sibling implementation** to swift-rfc-5322. Both encode different date-time standards but use identical Swift patterns:

- **Same module structure**: `ISO_8601.DateTime`, `ISO_8601.Date.Components`, etc.
- **Same nested types**: `DateTime.Formatter`, `DateTime.Parser` (via extensions)
- **Same file organization**: One type per file, clear separation of concerns
- **Same naming conventions**: PascalCase types, camelCase properties, descriptive names
- **Same error handling**: Typed errors nested under parent types
- **Same test patterns**: Descriptive test names, comprehensive coverage

**Reference Implementation:** `/Users/coen/Developer/swift-standards/swift-rfc-5322`

### Side-by-Side Structural Comparison

```swift
// RFC 5322 Structure                    // ISO 8601 Structure (mirror it!)
RFC_5322.DateTime                        ISO_8601.DateTime
  ├── secondsSinceEpoch: Int              ├── secondsSinceEpoch: Int
  ├── timezoneOffsetSeconds: Int          ├── timezoneOffsetSeconds: Int
  ├── components: Components              ├── components: Components
  ├── Formatter (nested enum)             ├── Formatter (nested enum)
  ├── Parser (nested enum)                ├── Parser (nested enum)
  └── format(_:) -> String                └── format(_:) -> String

RFC_5322.Date.Components                 ISO_8601.Date.Components
  ├── year: Int                            ├── year: Int
  ├── month: Int                           ├── month: Int
  ├── day: Int                             ├── day: Int
  ├── hour: Int                            ├── hour: Int
  ├── minute: Int                          ├── minute: Int
  ├── second: Int                          ├── second: Int
  ├── weekday: Int                         ├── weekday: Int
  ├── init(...) throws                     ├── init(...) throws
  └── init(unchecked...) internal          └── init(unchecked...) internal

RFC_5322.Date.Error                      ISO_8601.Date.Error
  ├── invalidFormat                        ├── invalidFormat
  ├── invalidMonth                         ├── invalidMonth
  ├── monthOutOfRange                      ├── monthOutOfRange
  └── ...                                  └── ...

RFC_5322.EmailAddress                    ISO_8601.WeekDate (different domain)
                                          ISO_8601.OrdinalDate (ISO specific)
```

**Key Insight:** The DateTime implementation should be nearly identical. Only the formatting/parsing differs.

### Implementation Strategy

This guide follows the **Hybrid Approach** from the architecture analysis:
1. **Phase 1:** Implement ISO 8601 independently (copy from RFC 5322)
2. **Phase 2:** Analyze actual overlap
3. **Phase 3:** Extract Standards/Time if criteria met

### Implementation Checklist

Before starting, ensure you understand RFC 5322's patterns:

- [ ] Read RFC 5322's main files to understand structure
  - [ ] `RFC_5322.DateTime.swift` - Core type implementation
  - [ ] `RFC_5322.Date.Components.swift` - Component validation
  - [ ] `RFC_5322.Date.Error.swift` - Error handling
- [ ] Understand the nested type pattern (Formatter/Parser via extensions)
- [ ] Review test naming conventions (`@Test func \`Descriptive name\`()`)
- [ ] Understand the unchecked initializer pattern for performance
- [ ] Note the O(1) epoch conversion algorithms (recently optimized!)

### Critical Pattern Consistency Rules

**DO:**
- ✅ Use same naming: `secondsSinceEpoch`, `timezoneOffsetSeconds`, `components`
- ✅ Use same structure: Nested types via extensions
- ✅ Use same validation: Throwing public init, unchecked internal init
- ✅ Use same documentation: Doc comments with examples
- ✅ Copy algorithms verbatim: Leap year, epoch conversion, weekday calculation
- ✅ Use backtick test names: `@Test func \`Parse extended format\`()`
- ✅ Follow RFC 5322 file organization exactly

**DON'T:**
- ❌ Create separate files for Formatter/Parser (use extensions)
- ❌ Abbreviate property names (`epoch` instead of `secondsSinceEpoch`)
- ❌ use 8601 validation logic (use RFC 5322's approach as reference only!)
- ❌ Rewrite algorithms (copy them, maintain duplication for now), adjust if necessary for 8601. 
- ❌ Use different error naming conventions
- ❌ Skip the unchecked initializer (needed for performance)

**When in doubt:** Look at the 8601 spec, then at how RFC 5322 does it and do the same if possible! otherwise apply the 5322 patterns mutatis mutandis. 

## ISO 8601 Standard Requirements

### Three Date Representations

1. **Calendar Date**
   - Extended: `YYYY-MM-DD` (e.g., `2024-01-15`)
   - Basic: `YYYYMMDD` (e.g., `20240115`)

2. **Week Date**
   - Extended: `YYYY-Www-D` (e.g., `2024-W03-2`)
   - Basic: `YYYYWwwD` (e.g., `2024W032`)
   - Week numbering: Monday=1, Sunday=7
   - Week 1 = first week containing first Thursday of year

3. **Ordinal Date**
   - Extended: `YYYY-DDD` (e.g., `2024-039`)
   - Basic: `YYYYDDD` (e.g., `2024039`)
   - Day 1-365 (366 in leap years)

### Time Representation

- Extended: `HH:MM:SS` or `HH:MM:SS.sss` (fractional seconds)
- Basic: `HHMMSS` or `HHMMSS.sss`
- Combined: `2024-01-15T12:30:00Z` or `20240115T123000Z`
- Separators: `T` between date and time
- Timezone:
  - `Z` for UTC (Zulu time)
  - `±HH:MM` (extended) or `±HHMM` (basic)

### Key Differences from RFC 5322

| Aspect | RFC 5322 | ISO 8601 |
|--------|----------|----------|
| Date separator | Space: "01 Jan 2024" | Hyphen: "2024-01-15" |
| Date order | Day-Month-Year | Year-Month-Day |
| Month | Name: "Jan" | Number: "01" |
| Day name | Required: "Mon," | Not included |
| Date/Time separator | Space | Letter "T" |
| Timezone format | `+0530` | `+05:30` or `Z` |
| Basic format | Not supported | `20240115T123000Z` |

## Implementation Structure

**Follow RFC 5322's exact organizational pattern:**

### File Structure Mapping: RFC 5322 → ISO 8601

| RFC 5322 File | ISO 8601 File | Purpose |
|---------------|---------------|---------|
| `RFC_5322.swift` | `ISO_8601.swift` | Main module, documentation |
| `RFC_5322.DateTime.swift` | `ISO_8601.DateTime.swift` | Core DateTime type |
| `RFC_5322.Date.Components.swift` | `ISO_8601.Date.Components.swift` | Component validation |
| `RFC_5322.Date.Error.swift` | `ISO_8601.Date.Error.swift` | Error types |
| *(nested in DateTime)* | *(nested in DateTime)* | Formatter (extension) |
| *(nested in DateTime)* | *(nested in DateTime)* | Parser (extension) |
| `RFC_5322.EmailAddress.swift` | `ISO_8601.WeekDate.swift` | Additional type |
| *(N/A)* | `ISO_8601.OrdinalDate.swift` | Additional type |
| `String.swift` | `String.swift` | String conversions |

### Directory Structure

```
swift-iso-8601/
├── Package.swift
├── IMPLEMENTATION_GUIDE.md (this file)
├── Sources/
│   └── ISO_8601/
│       ├── ISO_8601.swift                          # Main module (like RFC_5322.swift)
│       ├── ISO_8601.DateTime.swift                 # Core type (like RFC_5322.DateTime.swift)
│       ├── ISO_8601.Date.Components.swift          # Components (like RFC_5322.Date.Components.swift)
│       ├── ISO_8601.Date.Error.swift               # Errors (like RFC_5322.Date.Error.swift)
│       ├── ISO_8601.WeekDate.swift                 # Week date type (ISO 8601 specific)
│       ├── ISO_8601.OrdinalDate.swift              # Ordinal date type (ISO 8601 specific)
│       └── String.swift                            # String conversions
└── Tests/
    └── ISO_8601 Tests/
        ├── ISO_8601.DateTime Tests.swift           # Core tests (like RFC_5322.DateTime Tests.swift)
        ├── ISO_8601.WeekDate Tests.swift           # Week date tests
        ├── ISO_8601.OrdinalDate Tests.swift        # Ordinal date tests
        └── [UInt8] Tests.swift                     # Byte conversion tests
```

### Naming Convention Rules

**Follow RFC 5322 patterns exactly:**

1. **Module namespace**: `ISO_8601` (not `ISO8601` or `ISO-8601`)
   - Example from RFC 5322: `RFC_5322`

2. **Type names**: Nested under module namespace
   - `ISO_8601.DateTime` (like `RFC_5322.DateTime`)
   - `ISO_8601.Date.Components` (like `RFC_5322.Date.Components`)
   - `ISO_8601.Date.Error` (like `RFC_5322.Date.Error`)

3. **Nested types via extensions**:
   ```swift
   extension ISO_8601.DateTime {
       public enum Formatter { ... }    // Not a separate file
       public enum Parser { ... }       // Not a separate file
   }
   ```

4. **Property names**: Descriptive, full words
   - `secondsSinceEpoch` (not `epoch` or `seconds`)
   - `timezoneOffsetSeconds` (not `tzOffset` or `offset`)
   - `isoWeekday` (not `weekday` or `dow`)

5. **Function names**: Verb phrases
   - `toWeekDate()` (not `weekDate()`)
   - `toOrdinalDate()` (not `ordinal()`)

6. **Test names**: Backtick-quoted descriptive phrases
   ```swift
   @Test func `Create from seconds since epoch`() { ... }
   @Test func `Parse extended calendar date`() { ... }
   ```

## Phase 1: Implementation Steps

### Step 1: Copy Core Calendar Logic from RFC 5322

**Source:** `/Users/coen/Developer/swift-standards/swift-rfc-5322/Sources/RFC_5322/RFC_5322.DateTime.swift`

Copy and adapt:

1. **Time Constants** (Lines 12-18)
   ```swift
   private enum TimeConstants {
       static let secondsPerMinute = 60
       static let secondsPerHour = 3600
       static let secondsPerDay = 86400
       static let daysPerCommonYear = 365
       static let daysPerLeapYear = 366
   }
   ```

2. **Gregorian Calendar Helpers** (Lines 512-523)
   ```swift
   private static func isLeapYear(_ year: Int) -> Bool
   private static let daysInCommonYearMonths = [31, 28, 31, ...]
   private static let daysInLeapYearMonths = [31, 29, 31, ...]
   private static func daysInMonths(year: Int) -> [Int]
   ```

3. **Epoch Conversion - O(1) Year Calculation** (Lines 527-575)
   ```swift
   private static func yearAndDays(fromDaysSinceEpoch:) -> (year: Int, remainingDays: Int)
   ```
   ⚠️ **Critical:** This is the complex 400-year cycle algorithm we just fixed

4. **Days Since Epoch Calculation** (Lines 577-605)
   ```swift
   private static func daysSinceEpoch(year:month:day:) -> Int
   ```

5. **Weekday Calculation** (Lines 609-626)
   ```swift
   private static func weekday(year:month:day:) -> Int
   ```
   📝 **Note:** Returns 0=Sunday. ISO 8601 needs Monday=1, so add converter:
   ```swift
   func isoWeekday() -> Int {
       let zeller = weekday(year: year, month: month, day: day)
       return zeller == 0 ? 7 : zeller  // Sunday becomes 7, others shift
   }
   ```

6. **Components Extraction** (Lines 133-172)
   ```swift
   public var components: ISO_8601.Date.Components {
       // Convert epoch seconds to components
   }
   ```

### Step 2: Copy Components Structure

**Source:** `/Users/coen/Developer/swift-standards/swift-rfc-5322/Sources/RFC_5322/RFC_5322.Date.Components.swift`

Adapt:
- Keep validation logic (Lines 20-69)
- Keep unchecked initializer (Lines 78-94)
- Remove weekday from public init (ISO 8601 doesn't display it in calendar dates)

### Step 3: Implement ISO 8601-Specific Features

#### 3.1 ISO Week Number Calculation

```swift
extension ISO_8601.DateTime {
    /// ISO 8601 week number (1-53)
    /// Week 1 = first week containing first Thursday of the year
    public var isoWeek: Int {
        // Algorithm:
        // 1. Find day of week for Jan 1
        // 2. Determine week 1 start date
        // 3. Calculate week number from days since week 1 start
    }

    /// ISO week-year (may differ from calendar year at boundaries)
    public var isoWeekYear: Int {
        // Dec 29-31 might belong to next year's week 1
        // Jan 1-3 might belong to previous year's last week
    }
}
```

#### 3.2 Ordinal Day Calculation

```swift
extension ISO_8601.DateTime {
    /// Ordinal day of year (1-365 or 1-366)
    public var ordinalDay: Int {
        let components = self.components
        let monthDays = Self.daysInMonths(year: components.year)
        var days = components.day
        for m in 0..<(components.month - 1) {
            days += monthDays[m]
        }
        return days
    }
}
```

#### 3.3 Week Date Type

```swift
extension ISO_8601 {
    /// ISO 8601 Week Date representation: YYYY-Www-D
    public struct WeekDate: Sendable, Equatable {
        public let weekYear: Int      // ISO week-year
        public let week: Int           // 1-53
        public let weekday: Int        // 1=Monday, 7=Sunday

        public init(weekYear: Int, week: Int, weekday: Int) throws {
            // Validate ranges
        }

        /// Convert to calendar date
        public func toCalendarDate() -> DateTime {
            // Calculate date from week-year, week, weekday
        }
    }
}
```

#### 3.4 Ordinal Date Type

```swift
extension ISO_8601 {
    /// ISO 8601 Ordinal Date representation: YYYY-DDD
    public struct OrdinalDate: Sendable, Equatable {
        public let year: Int
        public let day: Int  // 1-365 (366 in leap years)

        public init(year: Int, day: Int) throws {
            // Validate: day must be valid for year
        }

        /// Convert to calendar date
        public func toCalendarDate() -> DateTime {
            // Calculate month and day from ordinal day
        }
    }
}
```

### Step 4: Implement Formatter

**Pattern:** Follow `RFC_5322.DateTime.Formatter` structure exactly

**Reference:** `/Users/coen/Developer/swift-standards/swift-rfc-5322/Sources/RFC_5322/RFC_5322.DateTime.swift` lines 192-245

**Key Pattern from RFC 5322:**
```swift
// RFC 5322 pattern:
extension RFC_5322.DateTime {
    public enum Formatter {
        public static func format(_ value: RFC_5322.DateTime) -> String { ... }
        private static func formatTwoDigits(_ value: Int) -> String { ... }
        private static func formatFourDigits(_ value: Int) -> String { ... }
    }
}
```

**Apply to ISO 8601:**
```swift
extension ISO_8601.DateTime {
    public enum Formatter {
        public enum Format {
            case calendar(extended: Bool)    // YYYY-MM-DD or YYYYMMDD
            case week(extended: Bool)        // YYYY-Www-D or YYYYWwwD
            case ordinal(extended: Bool)     // YYYY-DDD or YYYYDDD
        }

        public enum TimeFormat {
            case none
            case time(extended: Bool)                    // HH:MM:SS or HHMMSS
            case timeWithFractional(extended: Bool, precision: Int)
        }

        public enum TimezoneFormat {
            case none
            case utc            // Z
            case offset(extended: Bool)  // +05:30 or +0530
        }

        public static func format(
            _ value: ISO_8601.DateTime,
            date: Format = .calendar(extended: true),
            time: TimeFormat = .time(extended: true),
            timezone: TimezoneFormat = .utc
        ) -> String {
            // Format based on options
        }
    }
}
```

### Step 5: Implement Parser

**Pattern:** Follow `RFC_5322.DateTime.Parser` structure exactly

**Reference:** `/Users/coen/Developer/swift-standards/swift-rfc-5322/Sources/RFC_5322/RFC_5322.DateTime.swift` lines 258-380

**Key Pattern from RFC 5322:**
```swift
// RFC 5322 pattern:
extension RFC_5322.DateTime {
    public enum Parser {
        public static func parse(_ value: String) throws -> RFC_5322.DateTime {
            // 1. Split into components
            // 2. Parse each component with validation
            // 3. Construct DateTime
        }
    }
}
```

**Apply to ISO 8601:**
```swift
extension ISO_8601.DateTime {
    public enum Parser {
        public static func parse(_ value: String) throws -> ISO_8601.DateTime {
            // 1. Detect format (calendar/week/ordinal, basic/extended)
            // 2. Parse date portion
            // 3. Parse time portion (if present)
            // 4. Parse timezone (if present)
            // 5. Construct DateTime
        }

        private static func detectFormat(_ string: String) -> Format? {
            // "2024-01-15" -> calendar extended
            // "20240115" -> calendar basic
            // "2024-W03-2" -> week extended
            // "2024W032" -> week basic
            // "2024-039" -> ordinal extended
            // "2024039" -> ordinal basic
        }
    }
}
```

### Step 6: Error Types

```swift
extension ISO_8601.Date {
    public enum Error: Swift.Error, Sendable, Equatable {
        // Component validation
        case invalidYear(String)
        case invalidMonth(Int)
        case invalidDay(Int)
        case invalidHour(Int)
        case invalidMinute(Int)
        case invalidSecond(Int)
        case invalidFractionalSecond(String)

        // ISO 8601 specific
        case invalidWeekNumber(Int)
        case invalidWeekday(Int)
        case invalidOrdinalDay(Int)
        case invalidFormat(String)
        case invalidTimezone(String)
    }
}
```

## Phase 2: Testing Strategy

Follow RFC 5322 test patterns:

### Core DateTime Tests

```swift
@Suite("ISO_8601.DateTime")
struct ISO_8601_DateTime_Tests {
    // Creation tests
    @Test("Create from epoch")
    @Test("Create from components")

    // Conversion tests
    @Test("Extract calendar components")
    @Test("Extract week date components")
    @Test("Extract ordinal date")

    // Edge cases
    @Test("Handle leap years")
    @Test("Handle year boundaries (Dec 31 / Jan 1)")
    @Test("Handle century years (2000, 2100)")

    // ISO week edge cases
    @Test("Week 1 determination")
    @Test("Week 53 edge cases")
    @Test("Cross-year week dates")
}
```

### Format Tests

```swift
@Suite("ISO_8601.Formatter")
struct ISO_8601_Formatter_Tests {
    // Calendar date
    @Test("Format extended calendar date: 2024-01-15")
    @Test("Format basic calendar date: 20240115")

    // Week date
    @Test("Format extended week date: 2024-W03-2")
    @Test("Format basic week date: 2024W032")

    // Ordinal date
    @Test("Format extended ordinal: 2024-039")
    @Test("Format basic ordinal: 2024039")

    // Combined date-time
    @Test("Format with UTC: 2024-01-15T12:30:00Z")
    @Test("Format with offset: 2024-01-15T12:30:00+05:30")
    @Test("Format basic combined: 20240115T123000Z")

    // Fractional seconds
    @Test("Format with milliseconds: 2024-01-15T12:30:00.123Z")
}
```

### Parser Tests

```swift
@Suite("ISO_8601.Parser")
struct ISO_8601_Parser_Tests {
    @Test("Parse calendar date")
    @Test("Parse week date")
    @Test("Parse ordinal date")
    @Test("Parse with time")
    @Test("Parse with timezone")
    @Test("Parse basic format")
    @Test("Parse with fractional seconds")

    // Error cases
    @Test("Reject invalid formats")
    @Test("Reject invalid dates")
}
```

## Documentation to Track

### Duplication Analysis

As you implement, maintain a document tracking:

1. **Exact Duplicates** (copy as-is from RFC 5322):
   - [ ] `isLeapYear()` - Line count: ~3
   - [ ] `daysInMonth()` - Line count: ~12
   - [ ] `yearAndDays()` - Line count: ~40 (complex!)
   - [ ] `daysSinceEpoch()` - Line count: ~30
   - [ ] `weekday()` (Zeller's) - Line count: ~20
   - [ ] Components validation - Line count: ~50
   - [ ] Epoch to components - Line count: ~40

   **Total Duplication: ~195 lines**

2. **Similar But Different**:
   - ISO weekday numbering (Monday=1 vs Sunday=0)
   - Week number calculation (unique to ISO 8601)
   - Ordinal day calculation (unique to ISO 8601)

3. **Format-Specific**:
   - Parsing (completely different syntax)
   - Formatting (different string templates)
   - Month names (RFC 5322 uses "Jan", ISO uses "01")

### Standards/Time Extraction Candidates

After implementation, list what should go into Standards/Time:

#### Definite Candidates (>95% confidence):
- [ ] `GregorianCalendar.isLeapYear(_:)`
- [ ] `GregorianCalendar.daysInMonth(_:year:)`
- [ ] `EpochConversion.yearAndDays(fromDaysSinceEpoch:)`
- [ ] `EpochConversion.daysSinceEpoch(year:month:day:)`
- [ ] `EpochConversion.components(fromSecondsSinceEpoch:timezoneOffset:)`
- [ ] `DateComponents` structure with validation
- [ ] `TimeConstants` enum

#### Maybe Candidates (need both implementations to decide):
- [ ] `Weekday` type (needs mapping between conventions)
- [ ] `TimezoneOffset` type
- [ ] Date arithmetic operations

#### Keep Format-Specific:
- [ ] ISO week number calculation (ISO 8601 only)
- [ ] Ordinal day calculation (ISO 8601 only)
- [ ] RFC 5322 day/month names (RFC 5322 only)
- [ ] All parsing/formatting logic
- [ ] Protocol conformances

## Expected Timeline

- **Week 1:** Core DateTime, Components, basic Calendar date format
- **Week 2:** Week date, Ordinal date, Parser, comprehensive tests
- **Post-implementation:** Duplication analysis document (1-2 days)
- **Week 3:** Extract Standards/Time (if criteria met)

## Success Criteria

1. ✅ All three ISO 8601 date representations implemented
2. ✅ Both basic and extended formats supported
3. ✅ Fractional seconds support
4. ✅ Comprehensive test suite (>90% coverage)
5. ✅ Duplication analysis document complete
6. ✅ Decision ready for Standards/Time extraction

## Reference

- **ISO 8601:2019** - International Standard
- **RFC 3339** - ISO 8601 profile (simpler subset for Internet protocols)
- **RFC 5322** - Our implementation patterns reference
- **Wikipedia ISO 8601** - Good quick reference for formats

## Notes

- This package intentionally duplicates code from RFC 5322 temporarily
- Duplication will be resolved in Phase 3 via Standards/Time extraction
- Document all duplication to guide extraction decisions
- Follow RFC 5322 code organization and naming patterns for consistency
