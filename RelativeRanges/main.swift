public struct RelativeIndex<C: Collection> {
	let value: (C) -> C.Index

	static var start: RelativeIndex<C> {
		return RelativeIndex(value: { $0.startIndex })
	}

	static var end: RelativeIndex<C> {
		return RelativeIndex(value: { $0.endIndex })
	}

	func offset(_ offset: Int) -> RelativeIndex<C> {
		return RelativeIndex {
			let limit = offset > 0 ? $0.endIndex : $0.startIndex
			return $0.index(self.value($0), offsetBy: offset, limitedBy: limit) ?? limit
		}
	}
}

extension RelativeIndex where C.Element: Equatable {
	static func findFirst(_ element: C.Element) -> RelativeIndex<C> {
		return RelativeIndex {
			$0.firstIndex(of: element) ?? $0.endIndex
		}
	}
}

public extension Collection {
	subscript(generator: RelativeIndex<Self>) -> Element? {
		let index = generator.value(self)
		guard index < self.endIndex else { return nil }
		return self[index]
	}
}

public struct RelativeRange<C: Collection> {
	let start: RelativeIndex<C>
	let end: RelativeIndex<C>
}

public extension Collection {
	subscript(range: RelativeRange<Self>) -> SubSequence {
		let start = range.start.value(self)
		let end = range.end.value(self)
		guard start <= end else {
			return self[end ..< end]
		}
		return self[start ..< end]
	}
}

public extension RelativeIndex {
	static func ..< (lhs: RelativeIndex, rhs: RelativeIndex) -> RelativeRange<C> {
		return RelativeRange(start: lhs, end: rhs)
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
}

let str = "12345"
print(str[.start + 3]!)
print(str[.start + 2 ..< .end - 1])
print(str[.findFirst("2") ..< .end - 1])
print(str[.findFirst("9") + 1 ..< .end - 1])

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
