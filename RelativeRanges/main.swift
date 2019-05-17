public protocol IndexType {
	associatedtype CollectionT: Swift.Collection
	func materialize(for collection: CollectionT) -> CollectionT.Index?
}

public struct RelativeIndex<C: Collection>: IndexType {
	let value: (C.SubSequence) -> C.Index?

	static var start: RelativeIndex<C> {
		return RelativeIndex(value: { $0.startIndex })
	}

	static var end: RelativeIndex<C> {
		return RelativeIndex(value: { $0.endIndex })
	}

	public init(value: @escaping (C.SubSequence) -> C.Index?) {
		self.value = value
	}

	public func materialize(for collection: C) -> C.Index? {
		return value(collection[...])
	}

	public func offset(_ offset: Int) -> RelativeIndex<C> {
		return RelativeIndex { collection in
			let limit = offset > 0 ? collection.endIndex : collection.startIndex
			guard let result = self.value(collection) else {
				return nil
			}
			return collection.index(result, offsetBy: offset, limitedBy: limit)
		}
	}

	public func take(_ count: Int) -> RelativeRange<C> {
		return RelativeRange(start: self, end: self.offset(count ))
	}
}

extension RelativeIndex where C.Element: Equatable {
	static func find(_ element: C.Element) -> RelativeIndex<C> {
		return RelativeIndex {
			$0.firstIndex(of: element) ?? $0.endIndex
		}
	}
}

public extension RelativeIndex {
	func store(in box: Box<C.Index?>) -> RelativeIndex {
		return RelativeIndex { collection in
			let index = self.value(collection)
			box.value = index
			return index
		}
	}
}

public extension Collection {
	subscript(generator: RelativeIndex<Self>) -> Element? {
		guard let index = generator.value(self[...]), index < self.endIndex else { return nil }
		return self[index]
	}
}

public extension MutableCollection {
	subscript(generator: RelativeIndex<Self>) -> Element? {
		get {
			guard let index = generator.value(self[...]), index < self.endIndex else { return nil }
			return self[index]
		}
		set(value) {
			guard let index = generator.value(self[...]), index < self.endIndex, let value = value else { return }
			self[index] = value
		}
	}
}

public class Box<T> {
	var value: T

	public init(value: T) {
		self.value = value
	}
}

extension Box {
	public func materialize<C: Collection>(for collection: C) -> C.Index? where T == C.Index? {
		return value
	}
}

public protocol RelativeRangeType {
	associatedtype Collection: Swift.Collection
//	associatedtype StartIndex: IndexType
//	associatedtype EndIndex: IndexType where EndIndex.CollectionT == StartIndex.CollectionT
//
//	var start: StartIndex { get }
//	var end: EndIndex { get }

	func materialize(for collection: Collection) -> Range<Collection.Index>?
}

public struct RelativeRange<C: Collection>: RelativeRangeType {
	let start: RelativeIndex<C>
	let end: RelativeIndex<C>
	public func materialize(for collection: C) -> Range<C.Index>? {
		guard let start = start.value(collection[...]), let end = end.value(collection[start...]), start <= end else {
			return nil
		}
		return start ..< end
	}
}

public struct HRRange<C: Collection>: RelativeRangeType {
	let start: C.Index
	let end: RelativeIndex<C>

	public func materialize(for collection: C) -> Range<C.Index>? {
		guard let end = end.value(collection[start...]), start <= end else {
			return nil
		}
		return start ..< end
	}
}

public extension Collection {
	subscript<R: RelativeRangeType>(range: R) -> SubSequence? where R.Collection == Self {
		guard let real = range.materialize(for: self) else {
			return nil
		}
		return self[real]
	}
}

public extension RangeReplaceableCollection {
	subscript(range: RelativeRange<Self>) -> SubSequence? {
		get {
			guard let start = range.start.value(self[...]) else { return nil }
			guard let end = range.end.value(self[start...]) else { return nil }
//			guard start <= end else {
//				return nil//return self[end ..< end]
//			}
			return self[start ..< end]
		}
		set(values) {
			guard let start = range.start.value(self[...]), start < self.endIndex else {
				return
			}
			guard let end = range.end.value(self[start...]),  start <= end else {
				return
			}
			if let values = values {
				self.replaceSubrange(start..<end, with: values)
			} else {
				self.removeSubrange(start..<end)
			}
		}
	}
}


public extension RelativeIndex {
	static func ..< (lhs: RelativeIndex, rhs: RelativeIndex) -> RelativeRange<C> {
		return RelativeRange(start: lhs, end: rhs)
	}

	static func ..< (lhs: C.Index, rhs: RelativeIndex) -> HRRange<C> {
		return HRRange(start: lhs, end: rhs)
	}

	static func ... (lhs: RelativeIndex, rhs: RelativeIndex) -> RelativeRange<C> {
		return RelativeRange(start: lhs, end: rhs.offset(1))
	}

	static prefix func ..< (maximum: RelativeIndex) -> RelativeRange<C> {
		return RelativeRange(start: .start, end: maximum)
	}

	static prefix func ... (maximum: RelativeIndex) -> RelativeRange<C> {
		return RelativeRange(start: .start, end: maximum.offset(1))
	}

	static postfix func ... (minimum: RelativeIndex) -> RelativeRange<C> {
		return RelativeRange(start: minimum, end: .end)
	}

	static func +(lhs: RelativeIndex, rhs: Int) -> RelativeIndex {
		return lhs.offset(rhs)
	}

	static func -(lhs: RelativeIndex, rhs: Int) -> RelativeIndex {
		return lhs.offset(-rhs)
	}

	static func <|(lhs: RelativeIndex, rhs: Int) -> RelativeRange<C> {
		return lhs.take(rhs)
	}
}

infix operator <|

var str = "12345"
print(str[.start + 3]!)							// 4
print(str[.start + 2 ..< .end - 1])				// 34
print(str[.find("2") ..< .end - 1])		// 234
print(str[.find("2") <| 3])				// 234
print(str[.find("9") + 1 ..< .end - 1])	// Empty string
print("12341234"[.find("4") ... .find("3")])

var current = Box(value: Optional(str.startIndex))
while let index = current.value {
	let sub = str[index ..< RelativeIndex<String>.find("3").store(in: current)]
	print(sub)
}

print(str)
str[.start + 20 ..< .end - 2]! = "INSERT"
print("Insert", str)
var letters = Array(str.utf8)
print(letters)
letters[.find(50) ..< .end]?.reverse()
print(letters)
letters[.find(80) ..< .end]?.shuffle()
print(letters)
print(str)
//str[str.startIndex...str.index(after: str.startIndex)] = ""

print(Array(str.utf8)[1+1])
print(Array(str.utf8)[.start+1]!)
//
//precedencegroup RelativeOffsetPrecedence {
//	higherThan: RangeFormationPrecedence
//}
//infix operator ++ : RelativeOffsetPrecedence
//infix operator -- : RelativeOffsetPrecedence
//
//public extension RelativeIndex {
//	static func ++(_ lhs: RelativeIndex, _ rhs: Int) -> RelativeIndex {
//		return lhs.offset(rhs)
//	}
//
//	static func --(_ lhs: RelativeIndex, _ rhs: Int) -> RelativeIndex {
//		return lhs.offset(-rhs)
//	}
//}

