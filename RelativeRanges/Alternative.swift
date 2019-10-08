//
//  Protocol-Alternative.swift
//  RelativeRanges
//
//  Created by Tino Heth on 02.10.19.
//  Copyright © 2019 Tino Heth. All rights reserved.
//

import Foundation
//public protocol RelativeRangeType {
//	associatedtype Collection: Swift.Collection
////	associatedtype StartIndex: IndexType
////	associatedtype EndIndex: IndexType where EndIndex.CollectionT == StartIndex.CollectionT
////
////	var start: StartIndex { get }
////	var end: EndIndex { get }
//
//	func materialize(for collection: Collection) -> Range<Collection.Index>?
//}
//
//public struct RelativeRange<C: Collection>: RelativeRangeType {
//	let start: RelativeIndex<C>
//	let end: RelativeIndex<C>
//	public func materialize(for collection: C) -> Range<C.Index>? {
//		guard let start = start.value(collection[...]), let end = end.value(collection[start...]), start <= end else {
//			return nil
//		}
//		return start ..< end
//	}
//}
//
//public struct HRRange<C: Collection>: RelativeRangeType {
//	let start: C.Index
//	let end: RelativeIndex<C>
//
//	public func materialize(for collection: C) -> Range<C.Index>? {
//		guard let end = end.value(collection[start...]), start <= end else {
//			return nil
//		}
//		return start ..< end
//	}
//}


//
//
//public extension RangeReplaceableCollection {
//	subscript(range: RelativeRange<Self>) -> SubSequence? {
//		get {
//			guard let start = range.start.value(self[...]) else { return nil }
//			guard let end = range.end.value(self[start...]) else { return nil }
////			guard start <= end else {
////				return nil//return self[end ..< end]
////			}
//			return self[start ..< end]
//		}
//		set(values) {
//			guard let start = range.start.value(self[...]), start < self.endIndex else {
//				return
//			}
//			guard let end = range.end.value(self[start...]),  start <= end else {
//				return
//			}
//			if let values = values {
//				self.replaceSubrange(start..<end, with: values)
//			} else {
//				self.removeSubrange(start..<end)
//			}
//		}
//	}
//}
//
//
//public extension RelativeIndex {
//	static func ..< (lhs: RelativeIndex, rhs: RelativeIndex) -> RelativeRange<C> {
//		return RelativeRange(start: lhs, end: rhs)
//	}
//
//	static func ..< (lhs: C.Index, rhs: RelativeIndex) -> HRRange<C> {
//		return HRRange(start: lhs, end: rhs)
//	}
//
//	static func ... (lhs: RelativeIndex, rhs: RelativeIndex) -> RelativeRange<C> {
//		return RelativeRange(start: lhs, end: rhs.offset(1))
//	}
//
//	static prefix func ..< (maximum: RelativeIndex) -> RelativeRange<C> {
//		return RelativeRange(start: .start, end: maximum)
//	}
//
//	static prefix func ... (maximum: RelativeIndex) -> RelativeRange<C> {
//		return RelativeRange(start: .start, end: maximum.offset(1))
//	}
//
//	static postfix func ... (minimum: RelativeIndex) -> RelativeRange<C> {
//		return RelativeRange(start: minimum, end: .end)
//	}
//
//	static func +(lhs: RelativeIndex, rhs: Int) -> RelativeIndex {
//		return lhs.offset(rhs)
//	}
//
//	static func -(lhs: RelativeIndex, rhs: Int) -> RelativeIndex {
//		return lhs.offset(-rhs)
//	}
//
//	static func <|(lhs: RelativeIndex, rhs: Int) -> RelativeRange<C> {
//		return lhs.take(rhs)
//	}
//}
