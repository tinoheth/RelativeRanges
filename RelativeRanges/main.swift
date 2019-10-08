var string = "123,234,555,100,999"
var array = string.split(separator: ",")

public protocol IndexType {
	func materialize<CollectionT: Collection>(for collection: CollectionT) -> CollectionT.Index?
	//func materialize(for collection: CollectionT) -> CollectionT.Index?
}

open class RelativeIndex<C: Collection> {
	public typealias CollectionT = C
	public init() {
	}

	final func materialize(for collection: C) -> C.Index? {
		return materialize(for: collection[...])
	}

	open func materialize(for collection: C.SubSequence) -> C.Index? {
		return collection.startIndex
	}
}

public extension Collection {
		subscript<Index: RelativeIndex<Self>>(index: Index) -> Element? {
		guard let real = index.materialize(for: self) else {
			return nil
		}
		return self[real]
	}
}

public class EndIndex<C: Collection>: RelativeIndex<C> {
	override public func materialize(for collection: C.SubSequence) -> CollectionT.Index? {
		return collection.endIndex
	}
}

public class OffsetIndex<C: Collection, Base: RelativeIndex<C>>: RelativeIndex<C> {
	let base: Base
	let offset: Int

	public required init(base: Base, offset: Int) {
		self.base = base
		self.offset = offset
	}

	override public func materialize(for collection: C.SubSequence) -> CollectionT.Index? {
		guard let index = base.materialize(for: collection) else { return nil }
		return collection.index(index, offsetBy: offset, limitedBy: collection.endIndex)
	}
}

public class NegativeOffsetIndex<C: BidirectionalCollection, Base: RelativeIndex<C>>: OffsetIndex<C, Base> {
	override public func materialize(for collection: C.SubSequence) -> CollectionT.Index? {
		guard let index = base.materialize(for: collection) else { return nil }
		return collection.index(index, offsetBy: offset, limitedBy: collection.startIndex)
	}
}


public class FindIndex<C: Collection>: RelativeIndex<C> where C.Element: Equatable {
	let value: CollectionT.Element

	init(value: CollectionT.Element) {
		self.value = value
	}

	override public func materialize(for collection: C.SubSequence) -> CollectionT.Index? {
		return collection.firstIndex(of: value)
	}
}

public extension Collection where Element: Equatable {
	func indexAfterSubsequence<C: Collection>(_ sub: C) -> Index? where C.Element == Element {
		var current = startIndex
		var iter = sub.makeIterator()
		while current < endIndex {
			while let test = iter.next() {
				if test != self[current] {
					iter = sub.makeIterator()
				}
				self.formIndex(after: &current)
				guard current < endIndex else {
					break
				}
			}
			if iter.next() == nil {
				return current
			} else if current < endIndex {
				self.formIndex(after: &current)
			} else {
				return nil
			}
		}
		return nil
	}
}
public class FindSubsequence<C: Collection, S: Collection>: RelativeIndex<C> where C.Element: Equatable, C.Element == S.Element {
	let value: S

	init(value: S) {
		self.value = value
	}

	override public func materialize(for collection: C.SubSequence) -> CollectionT.Index? {
		return collection.indexAfterSubsequence(value)
	}
}

public class RelativeRange<C: Collection, Start: RelativeIndex<C>, End: RelativeIndex<C>> {
	let start: Start
	let end: End

	init(start: Start, end: End) {
    	self.start = start
    	self.end = end
	}

	public func materialize(for collection: C) -> Range<C.Index>? {
		guard let startIndex = start.materialize(for: collection),
		let endIndex = end.materialize(for: collection.suffix(from: startIndex)),
		startIndex <= endIndex else {
			return nil
		}
		return Range(uncheckedBounds: (startIndex, endIndex))
	}
}

public extension RelativeIndex {
	static var start: RelativeIndex { return RelativeIndex() }
	static var end: EndIndex<CollectionT> { return EndIndex() }

	static func ..< <R: RelativeIndex>(lhs: RelativeIndex, rhs: R) -> RelativeRange<CollectionT, RelativeIndex, R> {
		return RelativeRange(start: lhs, end: rhs)
	}

	static func ... <R: RelativeIndex>(lhs: RelativeIndex, rhs: R) -> RelativeRange<CollectionT, RelativeIndex, OffsetIndex<C, R>> {
		return RelativeRange(start: lhs, end: OffsetIndex(base: rhs, offset: 1))
	}

	static func +(base: RelativeIndex, _ offset: Int) -> OffsetIndex<C, RelativeIndex<C>> {
		return OffsetIndex(base: base, offset: offset)
	}

	func offset(_ offset: Int) -> OffsetIndex<C, RelativeIndex<C>> {
		return OffsetIndex(base: self, offset: offset)
	}

	func take(_ count: Int) -> RelativeRange<C, RelativeIndex<C>, OffsetIndex<C, RelativeIndex>> {
		return RelativeRange(start: self, end: self.offset(count ))
	}
}

public extension RelativeIndex where C: BidirectionalCollection {
	static func -(base: RelativeIndex, _ offset: Int) -> NegativeOffsetIndex<C, RelativeIndex<C>> {
		return NegativeOffsetIndex(base: base, offset: -offset)
	}
}

public extension RelativeIndex where CollectionT.Element: Equatable {
	static func find(_ value: CollectionT.Element) -> FindIndex<CollectionT> {
		return FindIndex(value: value)
	}

	static func find<S: Collection>(_ value: S) -> FindSubsequence<CollectionT, S> where S.Element == C.Element {
		return FindSubsequence(value: value)
	}
}

public extension Collection {
	subscript<Start: RelativeIndex<Self>, End: RelativeIndex<Self>>(range: RelativeRange<Self, Start, End>) -> SubSequence? {
		guard let real = range.materialize(for: self) else {
			return nil
		}
		return self[real]
	}
}

let s = string[.start ..< .find("5")]
print(s ?? "nil")
print("single", string[.find("5")] ?? "nil")


public class IndexMarker<C: Collection>: RelativeIndex<C> {
	var index: C.Index?

	public init(index: C.Index) {
		self.index = index
	}

	public override func materialize(for collection: C.SubSequence) -> C.Index? {
		return index
	}
}

public extension Collection {
	func startMarker() -> IndexMarker<Self> {
		return IndexMarker(index: self.startIndex)
	}
}

public extension RelativeIndex {
	class Memo<Base: RelativeIndex>: RelativeIndex<Base.CollectionT> {
		let base: Base
		let box: IndexMarker<Base.CollectionT>
		let offset: Int

		public init(base: Base, box: IndexMarker<Base.CollectionT>, offset: Int = 1) {
			self.base = base
			self.box = box
			self.offset = offset
		}

		public override func materialize(for collection: C.SubSequence) -> C.Index? {
			let value = base.materialize(for: collection)
			let limit = collection.endIndex
			box.index = value.map { collection.index($0, offsetBy: offset, limitedBy: limit) } ?? nil
			return value ?? limit
		}
	}

	func store(in box: IndexMarker<CollectionT>, offset: Int = 1) -> Memo<RelativeIndex> {
		return Memo(base: self, box: box, offset: offset)
	}
}

var current = string.startMarker()
while let index = current.index, index < string.endIndex {
	let sub = string[current ..< RelativeIndex.find(",").store(in: current)]
	print(sub ?? "nil")
}

public extension RangeReplaceableCollection {
	subscript<Start: RelativeIndex<Self>, End: RelativeIndex<Self>>(range: RelativeRange<Self, Start, End>) -> SubSequence? {
		get {
			guard let real = range.materialize(for: self) else {
				return nil
			}
			return self[real]
		}
		set(values) {
			guard let real = range.materialize(for: self) else { return }
			if let values = values {
				self.replaceSubrange(real, with: values)
			} else {
				self.removeSubrange(real)
			}

		}
	}
}


current = string.startMarker()
while let index = current.index, index < string.endIndex {
	print(string[current ..< RelativeIndex.find(",").store(in: current)] ?? "Not found")
}
print(string)

public extension Collection {
	subscript(generator: RelativeIndex<Self>) -> Element? {
		guard let index = generator.materialize(for: self[...]), index < self.endIndex else { return nil }
		return self[index]
	}
}

public extension MutableCollection {
	subscript(generator: RelativeIndex<Self>) -> Element? {
		get {
			guard let index = generator.materialize(for: self[...]), index < self.endIndex else { return nil }
			return self[index]
		}
		set(value) {
			guard let index = generator.materialize(for: self[...]), index < self.endIndex, let value = value else { return }
			self[index] = value
		}
	}
}


infix operator <|

var str = "12345"
print(str[.start + 3]!)							// 4
print(str[.start + 2 ..< .end - 1]!)				// 34
print(str[.find("2") ..< .end - 1]!)		// 234
//print(str[.find("2") <| 3])				// 234
print(str[.find("9") + 1 ..< .end - 1]!)	// Empty string
print("value=55;"[.find("=") ..< .find(";")]!)
//
//var current = Box(value: Optional(str.startIndex))
//while let index = current.value {
//	let sub = str[index ..< RelativeIndex<String>.find("3").store(in: current)]
//	print(sub)
//}
//
//print(str)
//str[.start + 20 ..< .end - 2]! = "INSERT"
//print("Insert", str)
//var letters = Array(str.utf8)
//print(letters)
//letters[.find(50) ..< .end]?.reverse()
//print(letters)
//letters[.find(80) ..< .end]?.shuffle()
//print(letters)
//print(str)
////str[str.startIndex...str.index(after: str.startIndex)] = ""
//
//print(Array(str.utf8)[1+1])
//print(Array(str.utf8)[.start+1]!)
////
////precedencegroup RelativeOffsetPrecedence {
////	higherThan: RangeFormationPrecedence
////}
////infix operator ++ : RelativeOffsetPrecedence
////infix operator -- : RelativeOffsetPrecedence
////
////public extension RelativeIndex {
////	static func ++(_ lhs: RelativeIndex, _ rhs: Int) -> RelativeIndex {
////		return lhs.offset(rhs)
////	}
////
////	static func --(_ lhs: RelativeIndex, _ rhs: Int) -> RelativeIndex {
////		return lhs.offset(-rhs)
////	}
////}

