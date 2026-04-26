import Foundation

struct CommandResult {
    var exitCode: Int32
    var standardOutput: String
    var standardError: String
}

enum ExternalCommandError: LocalizedError {
    case executableNotFound(String)
    case nonZeroExit(executable: String, exitCode: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .executableNotFound(let name):
            return "Could not find executable: \(name)"
        case .nonZeroExit(let executable, let exitCode, let stderr):
            return "\(executable) exited with code \(exitCode). \(stderr)"
        }
    }
}

final class ExternalCommandRunner {
    func findExecutable(named name: String, commonPaths: [String]) -> String? {
        let fileManager = FileManager.default
        for path in commonPaths where fileManager.isExecutableFile(atPath: path) {
            return path
        }

        let pathValue = ProcessInfo.processInfo.environment["PATH"] ?? "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        for directory in pathValue.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(name).path
            if fileManager.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    func run(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        standardInput: String? = nil
    ) async throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let inputPipe: Pipe?
        if standardInput != nil {
            let pipe = Pipe()
            process.standardInput = pipe
            inputPipe = pipe
        } else {
            inputPipe = nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { finishedProcess in
                let output = String(decoding: outputPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                let error = String(decoding: errorPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                continuation.resume(returning: CommandResult(
                    exitCode: finishedProcess.terminationStatus,
                    standardOutput: output,
                    standardError: error
                ))
            }

            do {
                try process.run()
                if let standardInput {
                    inputPipe?.fileHandleForWriting.write(Data(standardInput.utf8))
                    try? inputPipe?.fileHandleForWriting.close()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func runOrThrow(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        standardInput: String? = nil
    ) async throws -> CommandResult {
        let result = try await run(
            executable: executable,
            arguments: arguments,
            currentDirectory: currentDirectory,
            standardInput: standardInput
        )
        guard result.exitCode == 0 else {
            throw ExternalCommandError.nonZeroExit(
                executable: executable,
                exitCode: result.exitCode,
                stderr: result.standardError
            )
        }
        return result
    }
}
