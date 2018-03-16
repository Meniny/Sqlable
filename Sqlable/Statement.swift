//
//  SQLStatement.swift
//  Sqlable
//
//  Created by Elias Abel on 27/07/2016.
//  Copyright © 2016 Meniny Lab. All rights reserved.
//

/// A SQL operation
public enum SQLOperation {
	/// Read the specified columns from rows in a table
	case select([SQLColumn])
	/// Insert a new row with the specified value for each column
	case insert([(column: SQLColumn, value: SQLValue)])
	/// Update a row with the specified value for each updated column
	case update([(column: SQLColumn, value: SQLValue)])
	/// Count rows
	case count
	/// Delete rows
	case delete
}

/// What to do in case of conflict
public enum OnConflict {
	/// Abort the operation and fail with an error
	case abort
	/// Ignore the operation
	case ignore
	/// Perform the operation anyway
	case replace
}

/// A single result, which might not exist (really just an optional)
public enum SQLSingleResult<T> {
	case noResult
	case result(T)
	
	public var value: T? {
		switch self {
		case .result(let value): return value
		case .noResult: return nil
		}
	}
	
	public var hasResult: Bool {
		switch self {
		case .noResult: return false
		case _: return true
		}
	}
}

public func ==<T: Equatable>(lhs: SQLSingleResult<T>, rhs: SQLSingleResult<T>) -> Bool {
	return lhs.value == rhs.value
}

/// A statement that can be run against a database
/// T: The table to run the statement on
/// SQLReturn: The return type
public struct SQLStatement<T: Sqlable, SQLReturn> {
	let operation: SQLOperation
	let filterBy: SQLExpression?
	private let orderBy: [SQLOrder]
	let limit: Int?
	let single: Bool
	let onConflict: OnConflict
	
	/// Create a statement for a certain operation
	public init(operation: SQLOperation) {
		self.operation = operation
		self.filterBy = nil
		self.orderBy = []
		self.limit = nil
		self.single = false
		self.onConflict = .abort
	}
	
	private init(operation: SQLOperation, filter: SQLExpression? = nil, orderBy: [SQLOrder] = [], limit: Int? = nil, single: Bool = false, onConflict: OnConflict = .abort) {
		self.operation = operation
		self.filterBy = filter
		self.orderBy = orderBy
		self.limit = limit
		self.single = single
		self.onConflict = onConflict
	}
	
	/// Add an expression filter to the statement
	public func filter(_ expression: SQLExpression) -> SQLStatement {
		guard filterBy == nil else { fatalError("You can only add one filter to an expression. Combine filters with &&") }
		
		return SQLStatement(operation: operation, filter: expression, orderBy: orderBy, limit: limit, single: single, onConflict: onConflict)
	}
	
	/// Add an ordering to the statement
	public func orderBy(_ column: SQLColumn, _ direction: SQLOrder.Direction = .asc) -> SQLStatement {
		let order = SQLOrder(column, direction)
		return SQLStatement(operation: operation, filter: filterBy, orderBy: orderBy + [order], limit: limit, single: single, onConflict: onConflict)
	}
	
	/// Add a row return limit to the statement
	public func limit(_ limit: Int) -> SQLStatement {
		return SQLStatement(operation: operation, filter: filterBy, orderBy: orderBy, limit: limit, single: single, onConflict: onConflict)
	}
	
	/// Only select a single row
	public func singleResult() -> SQLStatement {
		return SQLStatement(operation: operation, filter: filterBy, orderBy: orderBy, limit: limit, single: true, onConflict: onConflict)
	}
	
	/// Ignore the operation if there are any conflicts caused by the statement
	public func ignoreOnConflict() -> SQLStatement {
		return SQLStatement(operation: operation, filter: filterBy, orderBy: orderBy, limit: limit, single: single, onConflict: .ignore)
	}
    
    /// Replace row if there are any conflicts caused by the statement
    public func replaceOnConflict() -> SQLStatement {
        return SQLStatement(operation: operation, filter: filterBy, orderBy: orderBy, limit: limit, single: single, onConflict: .replace)
    }
	
	var sqlDescription: String {
		var sql: [String]
		
		let conflict: String
		switch onConflict {
		case .abort: conflict = "or abort"
		case .ignore: conflict = "or ignore"
		case .replace: conflict = "or replace"
		}
		
		switch operation {
		case .select(let columns):
			let columnNames = columns.map { $0.name }.joined(separator: ", ")
			sql = ["select \(columnNames) from \(T.tableName)"]
		case .insert(let ops):
			let columnNames = ops.map { op in op.column.name }.joined(separator: ", ")
			let values = ops.map { _ in "?" }.joined(separator: ", ")
			sql = ["insert \(conflict) into \(T.tableName) (\(columnNames)) values (\(values))"]
		case .update(let ops):
			let values = ops.map { op in "\(op.column.name) = ?" }.joined(separator: ", ")
			sql = ["update \(conflict) \(T.tableName) set \(values)"]
		case .count:
			sql = ["select count(*) from \(T.tableName)"]
		case .delete:
			sql = ["delete from \(T.tableName)"]
		}
		
		if let filter = filterBy {
			sql.append("where " + filter.sqlDescription)
		}
		
		if orderBy.count > 0 {
			sql.append("order by " + orderBy.map { $0.sqlDescription }.joined(separator: ", "))
		}
		
		if let limit = limit {
			sql.append("limit \(limit)")
		}
		
		return sql.joined(separator: " ")
	}
	
	var values: [SQLValue] {
		var values: [SQLValue] = []
		
		switch operation {
		case .select(_): break
		case .insert(let ops): values += ops.map { op in op.value }
		case .update(let ops): values += ops.map { op in op.value }
		case .count: break
		case .delete: break
		}
		
		if let filter = filterBy {
			values += filter.values
		}
		
		return values
	}
	
	/// Run the statement against a database instance
	@discardableResult
	public func run(in db: SQLiteDatabase) throws -> SQLReturn {
		return try db.run(self) as! SQLReturn
	}
}

/// Ordering of selected rows
public struct SQLOrder: SQLPrintable {
	/// Ordering direction
	public enum Direction {
		/// SQLOrder ascending
		case asc
		/// SQLOrder descending
		case desc
	}
	
	let column: SQLColumn
	let direction: Direction
	
	/// Create an ordering
	/// 
	///	- Parameters:
	///		- column: The column to order by
	///		- direction: The direction to order in
	public init(_ column: SQLColumn, _ direction: Direction) {
		self.column = column
		self.direction = direction
	}
	
	public var sqlDescription: String {
		return "\(column.name) " + (direction == .desc ? "desc": "")
	}
}
