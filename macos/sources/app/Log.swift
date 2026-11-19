import Foundation

private let stamp: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return f
}()

/// Every line carries its time: the log is how a failure is diagnosed after the fact.
func log(_ message: String) {
    print("\(stamp.string(from: Date())) \(message)")
}

/// Launched from Finder the app has no terminal: standard output and error go to the log
/// file instead, which restarts past 1 MB.
func redirectOutputToLog() {
    let path = Settings.logPath
    if let size = (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? Int, size > 1_000_000 {
        try? FileManager.default.removeItem(atPath: path)
    }
    freopen(path, "a", stdout)
    freopen(path, "a", stderr)
    setvbuf(stdout, nil, _IOLBF, 0)
}
