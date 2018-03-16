//
//  SQLValue.swift
//  Sqlable
//
//  Created by Elias Abel on 27/07/2016.
//  Copyright © 2016 Meniny Lab. All rights reserved.
//

import Foundation
import SQLite3

/// A value which can be used to write to a sql row
public protocol SQLValue {
	/// Bind the value of the type to a position in a write handle
	func bind(_ db: OpaquePointer, handle: OpaquePointer, index: Int32) throws
}

extension Int: SQLValue {
	public func bind(_ db: OpaquePointer, handle: OpaquePointer, index: Int32) throws {
		if sqlite3_bind_int64(handle, index, Int64(self)) != SQLITE_OK {
			try throwLastError(db)
		}
	}
}

extension String: SQLValue {
	public func bind(_ db: OpaquePointer, handle: OpaquePointer, index: Int32) throws {
		if sqlite3_bind_text(handle, index, self, -1, SQLiteDatabase.SQLITE_TRANSIENT) != SQLITE_OK {
			try throwLastError(db)
		}
	}
}

extension Date: SQLValue {
	public func bind(_ db: OpaquePointer, handle: OpaquePointer, index: Int32) throws {
		if sqlite3_bind_int64(handle, index, Int64(self.timeIntervalSince1970)) != SQLITE_OK {
			try throwLastError(db)
		}
	}
}

extension Double: SQLValue {
	public func bind(_ db: OpaquePointer, handle: OpaquePointer, index: Int32) throws {
		if sqlite3_bind_double(handle, index, self) != SQLITE_OK {
			try throwLastError(db)
		}
	}
}

extension Float: SQLValue {
	public func bind(_ db: OpaquePointer, handle: OpaquePointer, index: Int32) throws {
		if sqlite3_bind_double(handle, index, Double(self)) != SQLITE_OK {
			try throwLastError(db)
		}
	}
}

extension Bool: SQLValue {
	public func bind(_ db: OpaquePointer, handle: OpaquePointer, index: Int32) throws {
		if sqlite3_bind_int(handle, index, Int32(self ? 1: 0)) != SQLITE_OK {
			try throwLastError(db)
		}
	}
}

/// A SQL null
public struct Null {
	public init() {
		
	}
}

extension Null: SQLValue {
	public func bind(_ db: OpaquePointer, handle: OpaquePointer, index: Int32) throws {
		if sqlite3_bind_null(handle, index) != SQLITE_OK {
			try throwLastError(db)
		}
	}
}
