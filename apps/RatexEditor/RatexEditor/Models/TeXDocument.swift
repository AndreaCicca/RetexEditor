import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    public static var texSource: UTType {
        UTType(importedAs: "org.tug.tex", conformingTo: .plainText)
    }
}

public struct TeXDocument: FileDocument {
    public static var readableContentTypes: [UTType] {
        return [.texSource, .plainText]
    }
    
    public var text: String
    
    public init(text: String = TeXTemplate.defaultArticle.source) {
        self.text = text
    }
    
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return .init(regularFileWithContents: data)
    }
}

