import Foundation

/// A named JSON document in shared storage.
public struct StoreFile: Sendable, Hashable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }

    public static let dayRecords = StoreFile("day-records")
    public static let lockSessions = StoreFile("lock-sessions")
    public static let protocolSessions = StoreFile("protocol-sessions")
    public static let taskLibrary = StoreFile("task-library")
}

/// Reads and writes `Codable` values as JSON documents.
///
/// A protocol so tests and previews can substitute an in-memory store, and so
/// the container location is injected rather than looked up globally.
public protocol FileStore: Sendable {
    func load<T: Decodable>(_ type: T.Type, from file: StoreFile) throws -> T?
    func save<T: Encodable>(_ value: T, to file: StoreFile) throws
    func delete(_ file: StoreFile) throws
}

/// JSON-on-disk implementation, pointed at a directory supplied by the caller.
public struct JSONFileStore: FileStore {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// The store backed by the shared App Group container.
    public static func appGroup() throws -> JSONFileStore {
        JSONFileStore(directory: try AppGroup.requireContainerURL())
    }

    private func url(for file: StoreFile) -> URL {
        directory.appending(path: "\(file.name).json")
    }

    public func load<T: Decodable>(_ type: T.Type, from file: StoreFile) throws -> T? {
        let url = url(for: file)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NudgeError.storageReadFailed(file: file.name)
        }
    }

    public func save<T: Encodable>(_ value: T, to file: StoreFile) throws {
        do {
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(value)
            // Atomic so an extension killed mid-write cannot leave a torn file.
            try data.write(to: url(for: file), options: .atomic)
        } catch {
            throw NudgeError.storageWriteFailed(file: file.name)
        }
    }

    public func delete(_ file: StoreFile) throws {
        let url = url(for: file)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw NudgeError.storageWriteFailed(file: file.name)
        }
    }
}
