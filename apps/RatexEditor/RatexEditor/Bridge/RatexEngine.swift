import Foundation

/// Status code returned by the C ABI
public enum RatexStatus: UInt32, Sendable {
    case success = 0
    case compilationError = 1
    case invalidInput = 2
    case noConvergence = 3
    case internalError = 4
    
    public var description: String {
        switch self {
        case .success: return String(localized: "Success")
        case .compilationError: return String(localized: "Compilation Error")
        case .invalidInput: return String(localized: "Invalid Input")
        case .noConvergence: return String(localized: "Did Not Converge")
        case .internalError: return String(localized: "Internal Engine Error")
        }
    }
}

/// Result of a TeX compilation run
public struct RatexCompilationResult: Sendable {
    public let status: RatexStatus
    public let pdfData: Data?
    public let log: String
    public let diagnostics: String
    public let passes: Int
    public let durationMs: Double
    public let timestamp: Date
    
    public var isSuccess: Bool {
        status == .success && pdfData != nil && !(pdfData?.isEmpty ?? true)
    }
}

/// Thread-safe Swift actor wrapping the in-process ratex compiler engine.
public actor RatexEngine {
    public static let shared = RatexEngine()
    
    public init() {
        let abi = tex_abi_version()
        assert(abi == 1, "Expected ratex ABI version 1, got \(abi)")
    }
    
    /// Compiles a LaTeX document source into PDF data in-memory.
    ///
    /// - Parameters:
    ///   - source: LaTeX document content
    ///   - filename: Virtual entrypoint filename (e.g. "main.tex")
    ///   - additionalFiles: Any auxiliary or resource files (e.g. images, .bib) mapped by path
    /// - Returns: RatexCompilationResult containing PDF bytes and diagnostic info
    public func compile(
        source: String,
        filename: String = "main.tex",
        additionalFiles: [String: Data] = [:]
    ) async -> RatexCompilationResult {
        let startTime = DispatchTime.now()
        
        guard let session = tex_session_new() else {
            return RatexCompilationResult(
                status: .internalError,
                pdfData: nil,
                log: "",
                diagnostics: String(localized: "Failed to initialize ratex compiler session."),
                passes: 0,
                durationMs: 0,
                timestamp: Date()
            )
        }
        defer {
            tex_session_free(session)
        }
        
        // Add main document
        let entryBytes = Array(filename.utf8)
        let sourceBytes = Array(source.utf8)
        
        let addStatus: UInt32 = entryBytes.withUnsafeBufferPointer { nameBuf in
            sourceBytes.withUnsafeBufferPointer { dataBuf in
                tex_session_add_file(
                    session,
                    nameBuf.baseAddress,
                    entryBytes.count,
                    dataBuf.baseAddress,
                    sourceBytes.count
                )
            }
        }
        
        if addStatus != 0 {
            let lastErrBytes = tex_session_last_error(session)
            let errString = bytesToString(lastErrBytes)
            return RatexCompilationResult(
                status: RatexStatus(rawValue: addStatus) ?? .invalidInput,
                pdfData: nil,
                log: "",
                diagnostics: errString.isEmpty ? String(localized: "Failed to load input file.") : errString,
                passes: 0,
                durationMs: 0,
                timestamp: Date()
            )
        }
        
        // Add auxiliary files if any
        for (extraName, extraData) in additionalFiles {
            let extraNameBytes = Array(extraName.utf8)
            let extraDataBytes = [UInt8](extraData)
            _ = extraNameBytes.withUnsafeBufferPointer { nameBuf in
                extraDataBytes.withUnsafeBufferPointer { dataBuf in
                    tex_session_add_file(
                        session,
                        nameBuf.baseAddress,
                        extraNameBytes.count,
                        dataBuf.baseAddress,
                        extraDataBytes.count
                    )
                }
            }
        }
        
        // Execute compilation
        let result = entryBytes.withUnsafeBufferPointer { nameBuf in
            tex_compile(session, nameBuf.baseAddress, entryBytes.count)
        }
        
        guard let result = result else {
            return RatexCompilationResult(
                status: .internalError,
                pdfData: nil,
                log: "",
                diagnostics: "Internal crash during compilation.",
                passes: 0,
                durationMs: 0,
                timestamp: Date()
            )
        }
        defer {
            tex_result_free(result)
        }
        
        let endTime = DispatchTime.now()
        let elapsedNanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let durationMs = Double(elapsedNanoseconds) / 1_000_000.0
        
        let rawStatus = tex_result_status(result)
        let status = RatexStatus(rawValue: rawStatus) ?? .internalError
        let passes = Int(tex_result_passes(result))
        let log = bytesToString(tex_result_log(result))
        let diagnostics = bytesToString(tex_result_diagnostics(result))
        
        var pdfData: Data? = nil
        if status == .success {
            let pdfBytes = tex_result_pdf(result)
            if pdfBytes.len > 0, let base = pdfBytes.data {
                pdfData = Data(bytes: base, count: pdfBytes.len)
            }
        }
        
        return RatexCompilationResult(
            status: status,
            pdfData: pdfData,
            log: log,
            diagnostics: diagnostics,
            passes: passes,
            durationMs: durationMs,
            timestamp: Date()
        )
    }
    
    private func bytesToString(_ b: tex_bytes) -> String {
        guard b.len > 0, let ptr = b.data else { return "" }
        let data = Data(bytes: ptr, count: b.len)
        let str = String(data: data, encoding: .utf8) ?? ""
        // Strip ANSI escape codes (e.g. \u{1B}[1;31m) for clean GUI presentation
        return str.replacingOccurrences(of: "\u{1B}\\[[0-9;]*[a-zA-Z]", with: "", options: .regularExpression)
    }
}

