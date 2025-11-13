import Foundation

class LegacyLogger {
    private let logFilePath: String

    init(fileName: String = "log.txt") {
        // Manually find the documents directory
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first ?? NSTemporaryDirectory()

        // Use plain string concatenation
        logFilePath = documentsDirectory + "/" + fileName

        // Create file if it doesn’t exist
        if !FileManager.default.fileExists(atPath: logFilePath) {
            FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        }
    }

    func log(_ message: String) {
        let timestamp = Date().description
        let formatted = "[\(timestamp)] \(message)\n"

        if let handle = FileHandle(forWritingAtPath: logFilePath) {
            handle.seekToEndOfFile()
            if let data = formatted.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            try? formatted.write(toFile: logFilePath, atomically: true, encoding: .utf8)
        }
    }

    func readLogs() -> String {
        if let data = FileManager.default.contents(atPath: logFilePath),
           let contents = String(data: data, encoding: .utf8) {
            return contents
        }
        return ""
    }

    func clear() {
        try? "".write(toFile: logFilePath, atomically: true, encoding: .utf8)
    }
}
