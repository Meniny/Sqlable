
<p align="center">
  <!-- <img src="./Assets/Sqlable.png" alt="Sqlable"> -->
  <br/><a href="https://cocoapods.org/pods/Sqlable">
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.1-brightgreen.svg">
  <img alt="Author" src="https://img.shields.io/badge/author-Meniny-blue.svg">
  <img alt="Build Passing" src="https://img.shields.io/badge/build-passing-brightgreen.svg">
  <img alt="Swift" src="https://img.shields.io/badge/swift-4.0%2B-orange.svg">
  <br/>
  <img alt="Platforms" src="https://img.shields.io/badge/platform-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg">
  <img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <br/>
  <img alt="Cocoapods" src="https://img.shields.io/badge/cocoapods-compatible-brightgreen.svg">
  <img alt="Carthage" src="https://img.shields.io/badge/carthage-working%20on-red.svg">
  <img alt="SPM" src="https://img.shields.io/badge/swift%20package%20manager-compatible-brightgreen.svg">
  </a>
</p>

## 🏵 Introduction

**Sqlable** is a tiny library for ORM written in Swift.

## 📋 Requirements

- iOS 8.0+
- macOS 10.10+
- tvOS 9.1+
- watchOS 2.2+
- Xcode 9.0+ with Swift 4.0+

## 📲 Installation

`Sqlable` is available on [CocoaPods](https://cocoapods.org):

```ruby
use_frameworks!
pod 'Sqlable'
```

## ❤️ Contribution

You are welcome to fork and submit pull requests.

## 🔖 License

`Sqlable` is open-sourced software, licensed under the `MIT` license.

## 💫 Usage

First, create a model:

```swift
struct User {
  var name: String
}
```

then, extend the model to confirm `Sqlable` protocol:

```swift
extension User: Sqlable {

}
```

and, we need to create the database columns:

```swift
extension User: Sqlable {
    // create your columns:

    static let id = SQLColumn("id", .integer, PrimaryKey(autoincrement: true))
    static let name = SQLColumn("name", .text)
    static var tableLayout: [SQLColumn] = [id, name]

    // implement there two functions:

    func valueForColumn(_ column: SQLColumn) -> SQLValue? {
        switch column {
        case User.name:
            return self.name
        default:
            return nil
        }
    }

    init(row: SQLReadRow) throws {
        name = try row.get(User.name)
    }
}
```

now, get your database:

```swift
let doc = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
let database = try SQLiteDatabase.init(filepath: doc.appendingPathComponent("User.db").path)
```

create table if not exists:

```swift
try database.create(table: User.self)
```

do your work, let's `insert` for example:

```swift
try user.insert(into: database)
```
query:

```swift
try User.query(in: database)
```
