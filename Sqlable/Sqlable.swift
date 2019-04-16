
//
//  Sqlable.swift
//  Sqlable
//
//  Created by Elias Abel on 27/07/2016.
//  Copyright © 2016 Meniny Lab. All rights reserved.
//

///	Something that can be a constraint on a SQL table.
public protocol SQLTableConstraint: SQLPrintable {}

/// A unique constraint on a SQL table. Ensures that a column, or a combination of columns, have a unique value.
public struct UniqueSQLTableConstraint: SQLTableConstraint {
	/// The columns to check for uniqueness.
	public let columns: [SQLColumn]
	
	/// Creates a UniqueSQLTableConstraint constraint on the specified columns
	///
	/// - Parameters:
	//		- _: The columns to constrain.
	public init(_ columns: [SQLColumn]) {
		self.columns = columns
	}
	
	/// Creates a UniqueSQLTableConstraint constraint on the specified columns
	///
	/// - Parameters:
	//		- _: The columns to constrain.
	public init(_ columns: SQLColumn...) {
		self.columns = columns
	}
	
	/// Get the SQL description of the unique constraint.
	public var sqlDescription: String {
		let columnList = columns.map { $0.name }.joined(separator: ", ")
		return "unique (\(columnList)) on conflict abort"
	}
}

/// Something that can work as a SQL table.
public protocol Sqlable {
	/// The name of the table in the database. Optional, defaults to `table_{type name}`.
	static var tableName: String { get }
	
	/// The columns of the table.
	static var tableLayout: [SQLColumn] { get }
	
	/// The constraints of the table. Optional, defaults to no table constraints (but individual columns can still have value constraints).
	static var tableConstraints: [SQLTableConstraint] { get }
	
	/// Returns the current value of a column. For when inserting values into the SQLite database.
	///
	/// - Parameters:
	///		- column: The SQLColumn to get the value for. Will be one of the colums specified in `tableLayout`.
	///	- Returns: A SQLValue to insert into the row.
	///		For null, return a Null().
	///		When returning nil, the column will be omitted completely, and will need to have a default value.
	func valueForColumn(_ column: SQLColumn) -> SQLValue?
	
	/// Reads a row from the SQLite database.
	///
	/// - Parameters:
	///		- row: An object which can be used to access data from a row returned from the database.
	///	- Throws: A SQLError, preferrebly ReadError, if the row couldn't be parsed correctly.
	init(row: SQLReadRow) throws
}

public extension Sqlable {
	static var tableName: String {
		let typeName = "table_\(Mirror(reflecting: self).subjectType)"
		return typeName[typeName.startIndex ..< typeName.index(typeName.endIndex, offsetBy: -5)].lowercased()
	}
	
	static var tableConstraints: [SQLTableConstraint] {
		return []
	}
	
	/// SQL statement for creating a Sqlable as a table in SQLite.
	///
	/// - Returns: A SQL statement string.
	static func createTable() -> String {
		let columns = tableLayout.map { $0.sqlDescription }
		let constraints = tableConstraints.map { $0.sqlDescription }
		let fields = (columns + constraints).joined(separator: ", ")
		return "create table if not exists \(tableName) (\(fields))"
	}
	
	/// Returns the SQLColumn object for a specified column name.
	///
	/// - Parameters:
	///		- name: The name of the column
	///	- Returns: The found column, or nil if none found.
	static func columnForName(_ name: String) -> SQLColumn? {
		return Self.tableLayout.lazy.filter { column in column.name == name }.first
	}
	
	/// Finds and returns the primary key column.
	///
	/// - Returns: The primary key column or nil.
	static func primaryColumn() -> SQLColumn? {
		return Self.tableLayout.lazy.filter { $0.options.contains { $0 is PrimaryKey } }.first
	}
	
	/// Create an update statement, which can be run against a database.
	/// Will run a SQL update on the object it's called from.
	///
	/// - Precondition:
	///		- Self needs to have a primary key
	///		- self needs to have a value for its primary key
	/// - Returns: An update statement instance.
	func updateStatement() -> SQLStatement<Self, Void> {
		guard let primaryColumn = Self.primaryColumn() else { fatalError("\(self) doesn't have a primary key") }
		guard let primaryValue = valueForColumn(primaryColumn) else { fatalError("\(self) doesn't have a primary key value") }
		let values = Self.tableLayout.compactMap { column in valueForColumn(column).flatMap { (column, $0) } }
		return SQLStatement(operation: .update(values)).filter(primaryColumn == primaryValue)
	}
	
    func update(at db: SQLiteDatabase) throws {
        try updateStatement().run(in: db)
    }
    
	/// Create an insert statement, which can be run against a database.
	/// Will run an insert statement on the object it's called from.
	///
	/// - Returns: An insert statement instance.
	func insertStatement() -> SQLStatement<Self, Int> {
		let values = Self.tableLayout.compactMap { column in valueForColumn(column).flatMap { (column, $0) } }
		return SQLStatement(operation: .insert(values))
	}
    
    @discardableResult
    func insert(into db: SQLiteDatabase) throws -> Int {
        return try insertStatement().run(in: db)
    }
	
	/// Create a delete statement, which can be run against a database.
	/// Will run a delete statement on the object it's called from.
	///
	/// - Precondition:
	///		- Self needs to have a primary key
	///		- self needs to have a value for its primary key
	/// - Returns: A delete statement instance
	func deleteStatement() -> SQLStatement<Self, Void> {
		guard let primaryColumn = Self.primaryColumn() else { fatalError("\(self) doesn't have a primary key") }
		guard let primaryValue = valueForColumn(primaryColumn) else { fatalError("\(self) doesn't have a primary key value") }
		return SQLStatement(operation: .delete).filter(primaryColumn == primaryValue)
	}
    
    func delete(from db: SQLiteDatabase) throws {
        try deleteStatement().run(in: db)
    }
	
	/// Create a count statement, which can be run against a database.
	/// Will run a count statement on all matched objects.
	///
	/// - Returns: A count statement instance.
	static func countStatement() -> SQLStatement<Self, Int> {
		return SQLStatement(operation: .count)
	}
    
    static func count(in db: SQLiteDatabase) throws -> Int {
        return try countStatement().run(in: db)
    }
	
	/// Create a delete statement, which can be run against a database.
	/// Will run a delete statement on all matched objects.
	///
	/// - Parameters:
	///		- filter: A filter on which objects should be deleted.
	/// - Returns: A count statement instance.
	static func deleteStatement(_ filter: SQLExpression) -> SQLStatement<Self, Void> {
		return SQLStatement(operation: .delete).filter(filter)
	}
    
    static func delete(_ filter: SQLExpression, from db: SQLiteDatabase) throws {
        try deleteStatement(filter).run(in: db)
    }
    
    /// Create a query statement, which can be run against a database.
    /// Will run a read statement on all matched objects.
    ///
    /// - Returns: A read statement instance.
    static func queryStatement() -> SQLStatement<Self, [Self]> {
        return SQLStatement(operation: .select(Self.tableLayout))
    }
    
    static func query(in db: SQLiteDatabase) throws -> [Self] {
        return try queryStatement().run(in: db)
    }
    
    static func insertStatement(for value: Self) -> SQLStatement<Self, Int> {
        return value.insertStatement()
    }
    
    @discardableResult
    static func insert(_ value: Self, into db: SQLiteDatabase) throws -> Int {
        return try value.insert(into: db)
    }
    
    static func updateStatement(for value: Self) -> SQLStatement<Self, Void> {
        return value.updateStatement()
    }
    
    static func update(_ value: Self, at db: SQLiteDatabase) throws {
        return try value.update(at: db)
    }
	
	/// Will create a query statement, which can be run against a database.
	/// Will read an object with the specified id.
	///
	/// - Precondition:
	///		- self needs to have a value for its primary key
	/// - Returns: A read statement instance.
	static func queryStatement(by id: SQLValue) -> SQLStatement<Self, SQLSingleResult<Self>> {
		guard let primary = primaryColumn() else { fatalError("\(type(of: self)) have no primary key") }
		return SQLStatement(operation: .select(Self.tableLayout))
			.filter(primary == id)
			.limit(1)
			.singleResult()
	}
    
    static func query(by id: SQLValue, in db: SQLiteDatabase) throws -> SQLSingleResult<Self> {
        return try queryStatement(by: id).run(in: db)
    }
}
