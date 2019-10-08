precedencegroup RelativeOffsetPrecedence {
  higherThan: RangeFormationPrecedence
}

infix operator ++ : RelativeOffsetPrecedence
infix operator -- : RelativeOffsetPrecedence

extension Collection {
  internal func _clampedIndex(_ idx: Index, offsetBy offset: Int) -> Index {
    let limit = offset < 0 ? startIndex : endIndex
    return index(idx, offsetBy: offset, limitedBy: limit) ?? limit
  }
}

// TODO: doc
public enum RelativeBound<Bound: Comparable> {
  case from(Bound, offset: Int)
  case fromStart(offset: Int)
  case fromEnd(offset: Int)

  internal static func exactly(_ bound: Bound) -> RelativeBound<Bound> {
    return .from(bound, offset: 0)
  }

  internal func index<C: Collection>(for c: C) -> Bound where Bound == C.Index {
    switch self {
      case .from(let bound, let offset):
        return c._clampedIndex(bound, offsetBy: offset)
      case .fromStart(let offset):
        return c._clampedIndex(c.startIndex, offsetBy: offset)
      case .fromEnd(let offset):
        return c._clampedIndex(c.endIndex, offsetBy: -offset)
    }
  }

  internal func addingOffset(_ x: Int) -> RelativeBound<Bound> {
    switch self {
      case .from(let bound, let offset):
        return .from(bound, offset: offset + x)
      case .fromStart(let offset):
        return .fromStart(offset: offset + x)
      case .fromEnd(let offset):
        return .fromEnd(offset: offset + x)
    }
  }
}

// NOTE: Explicitly chosen not to be Comparable, to help against
// Range<RelativeBound> ambiguities.
extension RelativeBound {
  internal static func < (lhs: RelativeBound, rhs: RelativeBound) -> Bool {
    switch (lhs, rhs) {
    case (.from(let lhsBound, let lhsOffset),
          .from(let rhsBound, let rhsOffset)):
      if lhsBound == rhsBound { return lhsOffset < rhsOffset }
      return lhsBound < rhsBound
    case (.from(_, _), .fromStart(_)): return false
    case (.from(_, _), .fromEnd(_)): return true

    case (.fromStart(_), .from(_, _)): return true
    case (.fromStart(let lhs), .fromStart(let rhs)): return lhs < rhs
    case (.fromStart(_), .fromEnd(_)): return true

    case (.fromEnd(_), .from(_, _)): return false
    case (.fromEnd(_), .fromStart(_)): return true
    case (.fromEnd(let lhs), .fromEnd(let rhs)): return lhs > rhs
    }
  }
  internal static func == (lhs: RelativeBound, rhs: RelativeBound) -> Bool {
    switch (lhs, rhs) {
    case (.from(let lhsBound, let lhsOffset),
          .from(let rhsBound, let rhsOffset)):
      return lhsBound == rhsBound && lhsOffset == rhsOffset
    case (.fromStart(let lhs), .fromStart(let rhs)): return lhs == rhs
    case (.fromEnd(let lhs), .fromEnd(let rhs)): return lhs == rhs
    default: return false
    }
  }

  internal static func > (lhs: RelativeBound, rhs: RelativeBound) -> Bool {
    return rhs < lhs
  }
  internal static func >= (lhs: RelativeBound, rhs: RelativeBound) -> Bool {
    return !(lhs < rhs)
  }
  internal static func <= (lhs: RelativeBound, rhs: RelativeBound) -> Bool {
    return !(lhs > rhs)
  }
}

// TODO: doc
public struct RelativeRange<Bound: Comparable> {
  internal var lowerBound: RelativeBound<Bound>

  internal var upperBound: RelativeBound<Bound>

  internal init(
    lowerBound: RelativeBound<Bound>, upperBound: RelativeBound<Bound>
  ) {
    self.lowerBound = lowerBound
    self.upperBound = upperBound
  }
}

extension RelativeRange: RangeExpression {
  // TODO: doc
  public func relative<C: Collection>(
    to col: C
  ) -> Range<Bound> where C.Index == Bound {
    return lowerBound.index(for: col)..<upperBound.index(for: col)
  }

  // TODO: doc
  public func contains(_ element: Bound) -> Bool {
    let element = RelativeBound.exactly(element)
    return lowerBound <= element && element < upperBound
  }
}

// NOTE: If Bound is Strideable, these could be Sequences or even
// RandomAccessCollections, but:
//   A) What's the point? Just use a range, it's better
//   B) Strideable would introduce a total order which may be incompatible with
//      our partial-order, so we don't want to encourage treating such relative
//      ranges as sequences or collecitons.

// NOTE: These could be CustomStringConvertible, Decodable, Encodable,
// CustomDebugStringConvertible, CustomReflectable, Equatable, or
// conditionally Hashable. But, unlike Range, these are not meant as an API
// currency type. These are ephemeral for usability. What they even mean is
// dependent on the Collection to which they will be applied. Users are
// encouraged to convert into absolute ranges instead.

// TODO: doc
public struct RelativeClosedRange<Bound: Comparable> {
  internal var lowerBound: RelativeBound<Bound>

  internal var upperBound: RelativeBound<Bound>

  internal init(
    lowerBound: RelativeBound<Bound>, upperBound: RelativeBound<Bound>
  ) {
    self.lowerBound = lowerBound
    self.upperBound = upperBound
  }
}

extension RelativeClosedRange: RangeExpression {
  // TODO: doc
  public func relative<C: Collection>(
    to col: C
  ) -> Range<Bound> where C.Index == Bound {
    return lowerBound.index(for: col)
      ..< col.index(after: upperBound.index(for: col))
  }

  // TODO: doc
  public func contains(_ element: Bound) -> Bool {
    let element = RelativeBound.exactly(element)
    return lowerBound <= element && element <= upperBound
  }
}

// TODO: doc
public struct RelativePartialRangeUpTo<Bound: Comparable> {
  internal var upperBound: RelativeBound<Bound>

  internal init(_ upperBound: RelativeBound<Bound>) {
    self.upperBound = upperBound
  }
}
extension RelativePartialRangeUpTo: RangeExpression {
  // TODO: doc
  public func relative<C: Collection>(
    to col: C
  ) -> Range<Bound> where C.Index == Bound {
    return col.startIndex..<upperBound.index(for: col)
  }

  // TODO: doc
  public func contains(_ element: Bound) -> Bool {
    return RelativeBound.exactly(element) < upperBound
  }
}

// TODO: doc
public struct RelativePartialRangeThrough<Bound: Comparable> {
  internal var upperBound: RelativeBound<Bound>

  internal init(_ upperBound: RelativeBound<Bound>) {
    self.upperBound = upperBound
  }
}
extension RelativePartialRangeThrough: RangeExpression {
  // TODO: doc
  public func relative<C: Collection>(
    to col: C
  ) -> Range<Bound> where C.Index == Bound {
    return col.startIndex..<col.index(after: upperBound.index(for: col))
  }

  // TODO: doc
  public func contains(_ element: Bound) -> Bool {
    return RelativeBound.exactly(element) <= upperBound
  }
}

// TODO: doc
public struct RelativePartialRangeFrom<Bound: Comparable> {
  internal var lowerBound: RelativeBound<Bound>

  internal init(_ lowerBound: RelativeBound<Bound>) {
    self.lowerBound = lowerBound
  }
}
extension RelativePartialRangeFrom: RangeExpression {
  // TODO: doc
  public func relative<C: Collection>(
    to col: C
  ) -> Range<Bound> where C.Index == Bound {
    return lowerBound.index(for: col)..<col.endIndex
  }

  // TODO: doc
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= RelativeBound.exactly(element)
  }
}

// Operators
extension Int {
  // TODO: doc
  public static prefix func ++<Bound: Comparable>(
    rhs: Int
  ) -> RelativeBound<Bound> {
    return .fromStart(offset: rhs)
  }

  // TODO: doc
  public static prefix func --<Bound: Comparable>(
    rhs: Int
  ) -> RelativeBound<Bound> {
    return .fromEnd(offset: rhs)
  }
}
extension Comparable {
  // TODO: doc
  public static func ++(
    lhs: Self, rhs: Int
  ) -> RelativeBound<Self> {
    return .from(lhs, offset: rhs)
  }

  // TODO: doc
  public static func --(
    lhs: Self, rhs: Int
  ) -> RelativeBound<Self> {
    return .from(lhs, offset: -rhs)
  }
}

extension RelativeBound {
  // TODO: doc
  public static func ++(
    lhs: RelativeBound, rhs: Int
  ) -> RelativeBound {
    return lhs.addingOffset(rhs)
  }

  // TODO: doc
  public static func --(
    lhs: RelativeBound, rhs: Int
  ) -> RelativeBound {
    return lhs.addingOffset(-rhs)
  }
}

extension RelativeBound {
  // TODO: doc
  public static func ..< (
    lhs: RelativeBound<Bound>, rhs: RelativeBound<Bound>
  ) -> RelativeRange<Bound> {
    return RelativeRange(lowerBound: lhs, upperBound: rhs)
  }

  // TODO: doc
  public static func ..< (
    lhs: Bound, rhs: RelativeBound<Bound>
  ) -> RelativeRange<Bound> {
    return .exactly(lhs) ..< rhs
  }

  // TODO: doc
  public static func ..< (
    lhs: RelativeBound<Bound>, rhs: Bound
  ) -> RelativeRange<Bound> {
    return lhs ..< .exactly(rhs)
  }

  // TODO: doc
  public static func ... (
    lhs: RelativeBound<Bound>, rhs: RelativeBound<Bound>
  ) -> RelativeClosedRange<Bound> {
    return RelativeClosedRange(lowerBound: lhs, upperBound: rhs)
  }

  // TODO: doc
  public static func ... (
    lhs: Bound, rhs: RelativeBound<Bound>
  ) -> RelativeClosedRange<Bound> {
    return .exactly(lhs) ... rhs
  }

  // TODO: doc
  public static func ... (
    lhs: RelativeBound<Bound>, rhs: Bound
  ) -> RelativeClosedRange<Bound> {
    return lhs ... .exactly(rhs)
  }

  // TODO: doc
  public static prefix func ..< (
    maximum: RelativeBound<Bound>
  ) -> RelativePartialRangeUpTo<Bound> {
    return RelativePartialRangeUpTo(maximum)
  }

  // TODO: doc
  public static prefix func ... (
    maximum: RelativeBound<Bound>
  ) -> RelativePartialRangeThrough<Bound> {
    return RelativePartialRangeThrough(maximum)
  }

  // TODO: doc
  public static postfix func ... (
    maximum: RelativeBound<Bound>
  ) -> RelativePartialRangeFrom<Bound> {
    return RelativePartialRangeFrom(maximum)
  }
}

// Precedence is postfix -> prefix -> infix, but that doesn't work for
// `foo[++2...]`, etc.. So, add special overloads to make it work.
extension PartialRangeFrom where Bound == Int {
  public static prefix func ++<RBound> (
    _ rhs: PartialRangeFrom<Int>
  ) -> RelativePartialRangeFrom<RBound> {
    return (++rhs.lowerBound)...
  }

  public static prefix func --<RBound> (
    _ rhs: PartialRangeFrom<Int>
  ) -> RelativePartialRangeFrom<RBound> {
    return (--rhs.lowerBound)...
  }

  public static func ++<RBound> (
    _ lhs: RBound, _ rhs: PartialRangeFrom<Int>
  ) -> RelativePartialRangeFrom<RBound> {
    return (lhs++rhs.lowerBound)...
  }

  public static func --<RBound> (
    _ lhs: RBound, _ rhs: PartialRangeFrom<Int>
  ) -> RelativePartialRangeFrom<RBound> {
    return (lhs--rhs.lowerBound)...
  }
}

extension PartialRangeThrough {
  public static func ++ (
    _ lhs: PartialRangeThrough, _ rhs: Int
  ) -> RelativePartialRangeThrough<Bound> {
    return ...(lhs.upperBound++rhs)
  }

  public static func -- (
    _ lhs: PartialRangeThrough, _ rhs: Int
  ) -> RelativePartialRangeThrough<Bound> {
    return ...(lhs.upperBound--rhs)
  }
}

extension PartialRangeUpTo {
  public static func ++ (
    _ lhs: PartialRangeUpTo, _ rhs: Int
  ) -> RelativePartialRangeUpTo<Bound> {
    return ..<(lhs.upperBound++rhs)
  }

  public static func -- (
    _ lhs: PartialRangeUpTo, _ rhs: Int
  ) -> RelativePartialRangeUpTo<Bound> {
    return ..<(lhs.upperBound--rhs)
  }
}

extension Collection {
  // TODO: doc
  public subscript(offset: RelativeBound<Index>) -> Element {
    return self[offset.index(for: self)]
  }
}
extension MutableCollection {
  // TODO: doc
  public subscript(offset: RelativeBound<Index>) -> Element {
    get {
      return self[offset.index(for: self)]
    }
    set {
      self[offset.index(for: self)] = newValue
    }
  }
}


// Examples
func printStrings() {
  let str = "abcdefghijklmnopqrstuvwxyz"
  let idx = str.firstIndex { $0 == "n" }!
  print("-- single element subscript --")
  print(str[--14]) // m
  print(str[idx--100]) // a
  print(str[idx++1]) // o
  print(str[(idx++1)--10]) // e
  print("-- relative range --")
  print(str[++1 ..< --2]) // bcdefghijklmnopqrstuvwx
  print(str[idx--2 ..< --2]) // lmnopqrstuvwx
  print(str[idx ..< --2]) // nopqrstuvwx
  print(str[idx--2..<idx]) // lm
  print(str[idx--2..<idx++3]) // lmnop
  print(str[--4 ..< --2]) // wx
  print("-- relative range through --")
  print(str[idx--2 ... --2]) // lmnopqrstuvwxy
  print(str[idx ... --2]) // nopqrstuvwxy
  print(str[idx--2...idx]) // lmn
  print(str[idx--2...idx++3]) // lmnopq
  print(str[--4 ... --2]) // wxy
  print("-- partial relative range up to --")
  print(str[..<idx++2]) // abcdefghijklmno
  print(str[..<idx--2]) // abcdefghijk
  print(str[..<(++20)]) // abcdefghijklmnopqrst
  print(str[..<(--20)]) // abcdef
  print("-- partial relative range through --")
  print(str[...idx++2]) // abcdefghijklmnop
  print(str[...idx--2]) // abcdefghijkl
  print(str[...(++20)]) // abcdefghijklmnopqrstu
  print(str[...(--20)]) // abcdefg
  print("-- partial relative range from --")
  print(str[idx++2...]) // pqrstuvwxyz
  print(str[idx--2...]) // lmnopqrstuvwxyz
  print(str[++20...]) // uvwxyz
  print(str[--20...]) // ghijklmnopqrstuvwxyz
}

func printSplitFloats() {
  func splitAndTruncate<T: BinaryFloatingPoint>(
    _ value: T, precision: Int = 3
  ) -> (whole: Substring, fraction: Substring) {
    let str = String(describing: value)
    guard let dotIdx = str.firstIndex(of: ".") else { return (str[...], "") }
    let fracIdx = dotIdx++1
    return (str[..<dotIdx], str[fracIdx..<fracIdx++precision])
  }

  print(splitAndTruncate(1.0)) // (whole: "1", fraction: "0")
  print(splitAndTruncate(1.25)) // (whole: "1", fraction: "25")
  print(splitAndTruncate(1.1000000000000001)) // (whole: "1", fraction: "1")
  print(splitAndTruncate(1.3333333)) // (whole: "1", fraction: "333")
  print(splitAndTruncate(200)) // (whole: "200", fraction: "0")
}

func printRanges() {
  let r = 3..<10
  print((absolute: r[5...], relative: r[++5...]))
  // (absolute: Range(5..<10), relative: Range(8..<10))
}

func printFifths() {
  func getFifth<C: RandomAccessCollection>(
    _ c: C
  ) -> (absolute: C.Element, relative: C.Element) where C.Index == Int {
    return (c[5], c[++5])
  }

  let array = [0, 1,2,3,4,5,6,7,8,9]
  print(getFifth(array)) // (absolute: 5, relative: 5)
  print(getFifth(array[2...])) // (absolute: 5, relative: 7)
}

import Foundation
func printDataFifths() {
  func getFifth(_ data: Data) -> (absolute: UInt8, relative: UInt8) {
    return (data[5], data[++5])
  }

  var data = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  print(getFifth(data)) // (absolute: 5, relative: 5)

  data = data.dropFirst()
  print(getFifth(data)) // (absolute: 5, relative: 6)
}

func printRequirements() {
  func parseRequirement(
    _ str: Substring
  ) -> (predecessor: Unicode.Scalar, successor: Unicode.Scalar) {
    return (str.unicodeScalars[++5], str.unicodeScalars[++36])
  }

  """
  Step C must be finished before step A can begin.
  Step C must be finished before step F can begin.
  Step A must be finished before step B can begin.
  Step A must be finished before step D can begin.
  Step B must be finished before step E can begin.
  Step D must be finished before step E can begin.
  Step F must be finished before step E can begin.
  """.split(separator: "\n").forEach { print(parseRequirement($0)) }
  // (predecessor: "C", successor: "A")
  // (predecessor: "C", successor: "F")
  // (predecessor: "A", successor: "B")
  // (predecessor: "A", successor: "D")
  // (predecessor: "B", successor: "E")
  // (predecessor: "D", successor: "E")
  // (predecessor: "F", successor: "E")
}

func runAll() {
  printStrings()
  printSplitFloats()
  printRanges()
  printFifths()
  printDataFifths()
  printRequirements()
}


runAll()
