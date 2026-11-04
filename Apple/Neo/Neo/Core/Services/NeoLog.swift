import Foundation
import os

enum NeoLog {
    static let data = Logger(subsystem: "com.neo.petcompanion", category: "data")
}

enum RepositoryErrorMapping {
    static func wrap(_ error: Error) -> RepositoryError {
        if let error = error as? RepositoryError {
            return error
        }
        NeoLog.data.error("Request failed: \(String(describing: error), privacy: .private)")
        return .remote
    }
}
