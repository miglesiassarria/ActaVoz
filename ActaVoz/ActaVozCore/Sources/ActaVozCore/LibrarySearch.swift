import Foundation

/// Coincidencia de texto para la biblioteca. Insensible a mayúsculas y acentos.
public struct LibrarySearch {
    public init() {}

    public func matches(_ query: String, in fields: [String]) -> Bool {
        let needle = normalize(query)
        guard !needle.isEmpty else { return true }
        return fields.contains { normalize($0).contains(needle) }
    }

    private func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_ES"))
    }
}
