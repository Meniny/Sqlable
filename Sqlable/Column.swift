//
//  SQLColumn.swift
//  Sqlable
//
//  Created by Elias Abel on 27/07/2016.
//  Copyright © 2016 Meniny Lab. All rights reserved.
//

/// Protocol for everything that can be an additional option for a SQL table column
public protocol ColumnOption: SQLPrintable {
	
}

/// Defines the primary key of a table
public struct PrimaryKey: ColumnOption {
	/// Wether or not the primay key should have autoincrement
	public let autoincrement: Bool
	
	/// Create a primary key option
	/// 
	/// - Parameters:
	///		- autoincrement: Wether or not the primary key should automatically increment on insertion (SQLite autoincrement)
	public init(autoincrement: Bool) {
		self.autoincrement = autoincrement
	}
	
	public var sqlDescription: String {
		var sql = ["primary key"]
		
		if autoincrement {
			sql.append("autoincrement")
		}
		
		return sql.joined(separator: " ")
	}
}

/// Rules for handling updates or deletions
public enum Rule: SQLPrintable {
	/// Ignore the update or deletion
	case ignore
	/// Perform a cascading delete
	case cascade
	/// Set the updated or deleted reference to null
	case setNull
	/// Set the updated or deleted reference to the default value
	case setDefault
	
	public var sqlDescription: String {
		switch self {
		case .ignore: return "no action"
		case .cascade: return "cascade"
		case .setNull: return "set null"
		case .setDefault: return "set default"
		}
	}
}

/// Defines a foreign key to another table
public struct ForeignKey<To: Sqlable>: ColumnOption, SQLPrintable {
	/// Which column in the other table to use for identification
	public let column: SQLColumn
	/// What to do when the referenced row is deleted
	public let onDelete: Rule
	/// What to do when the referenced row is updated
	public let onUpdate: Rule
	
	/// Create a foreign key constraint
	/// 
	/// - Parameters:
	///		- column: The column in the other Sqlable to reference for identification (default is the 'id' column)
	///		- onDelete: What to do when the referenced row is deleted (default is ignore)
	///		- onUpdate: What to do when the referenced row is updated (default is ignore)
	public init(column: SQLColumn = SQLColumn("id", .integer), onDelete: Rule = .ignore, onUpdate: Rule = .ignore) {
		self.column = column
		self.onDelete = onDelete
		self.onUpdate = onUpdate
	}
	
	public var sqlDescription: String {
		var sql = ["references \(To.tableName)(\(column.name))"]
		
		if onUpdate != .ignore {
			sql.append("on update \(onUpdate.sqlDescription)")
		}
		
		if onDelete != .ignore {
			sql.append("on delete \(onDelete.sqlDescription)")
		}
		
		return sql.joined(separator: " ")
	}
}

/// A column in a SQL table
public struct SQLColumn: Equatable {
	/// The SQL name of the column
	public let name: String
	/// The SQL type of the column
	public let type: SQLType
	/// Additional options and constraints
	public let options: [ColumnOption]
	
	let modifiers: [String]
	
	/// Create a new column
	/// 
	/// - Parameters:
	///		- name: The SQL name of the column
	///		- type: The SQL type of the column
	///		- options: Additional options and constraints
	public init(_ name: String, _ type: SQLType, _ options: ColumnOption...) {
		self.name = name
		self.type = type
		self.options = options
		self.modifiers = []
	}
	
	init(_ name: String, _ type: SQLType, _ options: [ColumnOption], modifiers: [String]) {
		self.name = name
		self.type = type
		self.options = options
		self.modifiers = modifiers
	}
}

extension SQLColumn {
	/// Choose the column with an uppercase modifier (for use in filters)
	public func uppercase() -> SQLColumn {
		return SQLColumn(name, type, options, modifiers: modifiers + ["upper"])
	}
	
	/// Choose the column with a lowercase modifier (for use in filters)
	public func lowercase() -> SQLColumn {
		return SQLColumn(name, type, options, modifiers: modifiers + ["lower"])
	}
	
	var expressionName: String {
		return modifiers.reduce(name) { name, modifier in "\(modifier)(\(name))" }
	}
}

public func ==(lhs: SQLColumn, rhs: SQLColumn) -> Bool {
	return lhs.name == rhs.name && lhs.type == rhs.type
}

public func ~=(lhs: SQLColumn, rhs: SQLColumn) -> Bool {
	return lhs.name == rhs.name
}

extension SQLColumn: SQLPrintable {
	public var sqlDescription: String {
		var statement = ["\(name) \(type.sqlDescription)"]
		
		for option in options {
			statement.append(option.sqlDescription)
		}
		
		return statement.joined(separator: " ")
	}
}
