# ISO 8601:2019 Specification Analysis

## Current Implementation Status

### ✅ Implemented (ISO 8601-1:2019 Core)

1. **Calendar Dates**
   - Extended: `2024-01-15`
   - Basic: `20240115`

2. **Week Dates**
   - Extended: `2024-W03-2`
   - Basic: `2024W032`

3. **Ordinal Dates**
   - Extended: `2024-039`
   - Basic: `2024039`

4. **Time Representations**
   - Extended: `HH:MM:SS`
   - Basic: `HHMMSS`

5. **Combined Date-Time**
   - `2024-01-15T12:30:00Z`
   - `20240115T123000Z`

6. **Timezone Representations**
   - UTC: `Z`
   - Offset Extended: `+05:30` or `-05:00`
   - Offset Basic: `+0530` or `-0500`

---

## 🔴 Missing Features (ISO 8601-1:2019)

### 1. Durations (P Format)

**Format:** `P[n]Y[n]M[n]DT[n]H[n]M[n]S`

- `P` prefix indicates period/duration
- `T` separates date components from time components
- Components can be omitted if zero

**Examples:**
- `P3Y6M4DT12H30M5S` - 3 years, 6 months, 4 days, 12 hours, 30 minutes, 5 seconds
- `P1Y` - 1 year
- `PT5M` - 5 minutes
- `P3D` - 3 days
- `PT0.5S` - half a second (fractional)

**Swift Type:** `ISO_8601.Duration`

```swift
public struct Duration: Sendable, Equatable {
    public let years: Int
    public let months: Int
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Double  // Supports fractional
}
```

### 2. Time Intervals

**Four Variants:**

a) **Start/End:** `2019-08-27/2019-08-29`
b) **Duration Only:** `P3D`
c) **Start/Duration:** `2019-08-27/P3D`
d) **Duration/End:** `P3D/2019-08-29`

**Swift Type:** `ISO_8601.Interval`

```swift
public enum Interval: Sendable, Equatable {
    case startEnd(start: DateTime, end: DateTime)
    case duration(Duration)
    case startDuration(start: DateTime, duration: Duration)
    case durationEnd(duration: Duration, end: DateTime)
}
```

### 3. Recurring Intervals (R Format)

**Format:** `Rn/<interval>`

- `R` prefix indicates recurrence
- `n` = number of repetitions (omit for unlimited)
- `<interval>` is any interval format

**Examples:**
- `R5/2019-01-01T00:00:00Z/P1D` - 5 daily repetitions starting Jan 1, 2019
- `R/2019-01-01T00:00:00Z/P1W` - Unlimited weekly repetitions
- `R3/P1Y2M10DT2H30M/2019-12-31T23:59:59Z` - 3 repetitions ending Dec 31, 2019

**Swift Type:** `ISO_8601.RecurringInterval`

```swift
public struct RecurringInterval: Sendable, Equatable {
    public let repetitions: Int?  // nil = unlimited
    public let interval: Interval
}
```

### 4. Fractional Seconds

**Current:** Integer seconds only
**Needed:** Fractional seconds with arbitrary precision

**Format:**
- Period (common): `12:30:45.123456`
- Comma (ISO preferred): `12:30:45,123456`

**Implementation:**
- Add `nanoseconds: Int` or `fractionalSeconds: Double` to DateTime
- Update Formatter to support precision parameter
- Update Parser to handle both `,` and `.` separators

### 5. Reduced Precision / Truncated Representations

**Dates:**
- Year only: `2024`
- Year-month: `2024-01` or `202401`
- Year-week: `2024-W03` or `2024W03`

**Times:**
- Hour only: `12`
- Hour-minute: `12:30` or `1230`
- No seconds: `12:30` (already partially supported in parser)

**DateTime:**
- Date + hour: `2024-01-15T12`
- Date + hour-minute: `2024-01-15T12:30`

**Swift Approach:**
- Create `PartialDate` and `PartialTime` types
- Or use optionals in existing types
- Support in Parser with intelligent defaults

### 6. 24:00:00 Format (Midnight at End of Day)

**Current:** Not supported
**Needed:** `24:00:00` = midnight at END of calendar day

**Equivalence:**
- `2024-01-15T24:00:00` = `2024-01-16T00:00:00`

**Implementation:**
- Add special case in Parser
- Normalize to next day at 00:00:00
- Optionally preserve in Formatter (configuration)

### 7. Time-Only Representations

**Format:**
- Basic: `123045` or `1230` or `12`
- Extended: `12:30:45` or `12:30` or `12`
- With timezone: `12:30:45Z` or `12:30:45+05:30`

**Swift Type:** `ISO_8601.Time`

```swift
public struct Time: Sendable, Equatable {
    public let hour: Int
    public let minute: Int?
    public let second: Int?
    public let fractionalSeconds: Double?
    public let timezoneOffsetSeconds: Int?
}
```

### 8. Decimal Comma Support

**Current:** Only period (`.`) supported
**Needed:** Both comma (`,`) and period (`.`)

**Note:** Comma is ISO 8601 preferred, but period is universally used in practice

**Implementation:**
- Update Parser to accept both separators
- Formatter configuration to choose separator (default: period)

### 9. Date-Only with Timezone

**Format:**
- `2024-01-15+05:30`
- Represents a calendar date in a specific timezone

**Implementation:**
- DateTime already supports this
- Ensure Formatter/Parser handle it correctly

---

## Implementation Priority

### Phase 1: Core Enhancements (High Priority)
1. ✅ Fractional seconds support
2. ✅ Reduced precision in Parser (accept partial times)
3. ✅ 24:00:00 support
4. ✅ Decimal comma support
5. ✅ Time-only representations

### Phase 2: Duration & Intervals (Medium Priority)
6. Duration type and P format parsing/formatting
7. Interval types (all four variants)
8. Interval parsing/formatting

### Phase 3: Advanced Features (Lower Priority)
9. Recurring intervals (R format)
10. Complex interval arithmetic

---

## Swifty Design Principles

1. **Type Safety:** Use enums for variants, structs for concrete types
2. **Sendable:** All types conform to Sendable
3. **Codable:** Support JSON encoding/decoding
4. **CustomStringConvertible:** Default ISO 8601 formatting
5. **Validation:** Throwing initializers for invalid inputs
6. **Internal unchecked initializers:** For performance when validity is guaranteed
7. **Mirroring RFC 5322:** Follow established patterns

---

## Testing Strategy

- Unit tests for each new type
- Format/parse round-trip tests
- Edge cases (24:00:00, fractional seconds, etc.)
- Error cases (invalid formats)
- Performance tests for duration arithmetic

---

## Documentation Updates Needed

1. Main ISO_8601.swift module documentation
2. README with complete feature list
3. Examples for all supported formats
4. Migration guide (if breaking changes)
