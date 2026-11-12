// file: Database.swift
// what: a small wrapper around sqlcipher (encrypted sqlite). opens the file with a key and runs sql.
// story: us01

import Foundation
import SQLCipher

enum DatabaseError: Error, Equatable {
    case openFailed(String)
    case wrongKey
    case sqlError(String)
}

// one value going into or coming out of the database
enum SQLValue: Equatable {
    case int(Int64)
    case double(Double)
    case text(String)
    case null
}

// one row from a query, looked up by column name
struct Row {
    let values: [String: SQLValue]

    func int(_ column: String) -> Int? {
        if case .int(let value) = values[column] { return Int(value) }
        return nil
    }

    func double(_ column: String) -> Double? {
        switch values[column] {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return nil
        }
    }

    func text(_ column: String) -> String? {
        if case .text(let value) = values[column] { return value }
        return nil
    }
}

final class Database {
    // the first 16 bytes of every normal (unencrypted) sqlite file
    static let plainSQLiteHeader = Data("SQLite format 3\0".utf8)

    let path: String
    private var handle: OpaquePointer?

    // opens (or creates) the database file and unlocks it with the key.
    // throws .wrongKey if the key does not match the file.
    init(path: String, key: Data) throws {
        self.path = path

        guard sqlite3_open(path, &handle) == SQLITE_OK else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(handle)
            throw DatabaseError.openFailed(message)
        }

        // give sqlcipher the raw 32-byte key as hex, like x'ab12...'
        let hexKey = key.hexString
        try execute("PRAGMA key = \"x'\(hexKey)'\";")

        // reading the schema only works if the key is right
        do {
            _ = try query("SELECT count(*) AS n FROM sqlite_master;")
        } catch {
            sqlite3_close(handle)
            handle = nil
            throw DatabaseError.wrongKey
        }

        // turn on foreign keys so deleting a parent also deletes its children
        try execute("PRAGMA foreign_keys = ON;")
    }

    deinit {
        close()
    }

    func close() {
        if handle != nil {
            sqlite3_close(handle)
            handle = nil
        }
    }

    // runs sql that does not return rows (create, insert, update, delete)
    func execute(_ sql: String, _ values: [SQLValue] = []) throws {
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }

        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE || result == SQLITE_ROW else {
            throw DatabaseError.sqlError(errorMessage())
        }
    }

    // runs a select and returns every row
    func query(_ sql: String, _ values: [SQLValue] = []) throws -> [Row] {
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }

        var rows: [Row] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW else {
                throw DatabaseError.sqlError(errorMessage())
            }
            rows.append(readRow(statement))
        }
        return rows
    }

    // the id of the last row inserted
    var lastInsertId: Int64 {
        sqlite3_last_insert_rowid(handle)
    }

    // runs several changes as one unit. if any fails, none are kept.
    func transaction(_ work: () throws -> Void) throws {
        try execute("BEGIN TRANSACTION;")
        do {
            try work()
            try execute("COMMIT;")
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    // the sqlcipher version, which also proves the encrypted library is in use
    func cipherVersion() -> String? {
        let rows = try? query("PRAGMA cipher_version;")
        return rows?.first?.values.values.first.flatMap { value in
            if case .text(let text) = value { return text }
            return nil
        }
    }

    // MARK: checks used by the security screen and the tests

    // true if the file does not start with the normal sqlite header
    static func fileLooksEncrypted(path: String) -> Bool {
        guard let file = FileHandle(forReadingAtPath: path) else { return false }
        defer { try? file.close() }
        let firstBytes = file.readData(ofLength: plainSQLiteHeader.count)
        return firstBytes.count == plainSQLiteHeader.count && firstBytes != plainSQLiteHeader
    }

    // true if the file can be read with no key at all (it should not be)
    static func opensWithoutKey(path: String) -> Bool {
        var handle: OpaquePointer?
        defer { sqlite3_close(handle) }
        guard sqlite3_open_v2(path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return false
        }
        let result = sqlite3_exec(handle, "SELECT count(*) FROM sqlite_master;", nil, nil, nil)
        return result == SQLITE_OK
    }

    // MARK: private helpers

    // tells sqlite to copy our text right away, so swift can free it
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private func prepare(_ sql: String, _ values: [SQLValue]) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.sqlError(errorMessage())
        }

        // fill in each ? in the sql with a value (sqlite counts from 1)
        for (index, value) in values.enumerated() {
            let position = Int32(index + 1)
            switch value {
            case .int(let number): sqlite3_bind_int64(statement, position, number)
            case .double(let number): sqlite3_bind_double(statement, position, number)
            case .text(let text): sqlite3_bind_text(statement, position, text, -1, transient)
            case .null: sqlite3_bind_null(statement, position)
            }
        }
        return statement
    }

    private func readRow(_ statement: OpaquePointer?) -> Row {
        var values: [String: SQLValue] = [:]
        for column in 0..<sqlite3_column_count(statement) {
            let name = String(cString: sqlite3_column_name(statement, column))
            switch sqlite3_column_type(statement, column) {
            case SQLITE_INTEGER:
                values[name] = .int(sqlite3_column_int64(statement, column))
            case SQLITE_FLOAT:
                values[name] = .double(sqlite3_column_double(statement, column))
            case SQLITE_TEXT:
                values[name] = .text(String(cString: sqlite3_column_text(statement, column)))
            default:
                values[name] = .null
            }
        }
        return Row(values: values)
    }

    private func errorMessage() -> String {
        guard let handle else { return "database is closed" }
        return String(cString: sqlite3_errmsg(handle))
    }
}
