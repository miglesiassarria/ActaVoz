import Foundation

public struct SummaryTemplate: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var instructions: String
    public var sections: [String]
    public var isBuiltIn: Bool

    public init(id: String = UUID().uuidString, name: String, instructions: String, sections: [String], isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.sections = sections
        self.isBuiltIn = isBuiltIn
    }
}

public enum SummaryTemplateCatalog {
    public static let builtIns: [SummaryTemplate] = [
        SummaryTemplate(
            id: "general",
            name: "Resumen general",
            instructions: "Resume la reunión de forma neutral y breve. No inventes datos ni atribuciones.",
            sections: ["Síntesis", "Temas tratados", "Conclusiones y próximos pasos"],
            isBuiltIn: true
        ),
        SummaryTemplate(
            id: "trabajo",
            name: "Reunión de trabajo",
            instructions: "Resume una reunión de trabajo. Distingue temas, decisiones, tareas y seguimiento.",
            sections: ["Temas y puntos importantes", "Decisiones y acuerdos", "Tareas y compromisos", "Pendientes y seguimiento"],
            isBuiltIn: true
        ),
        SummaryTemplate(
            id: "individual",
            name: "Reunión individual",
            instructions: "Resume una conversación individual. Conserva acuerdos y compromisos con nombres cuando consten.",
            sections: ["Temas tratados", "Acuerdos y compromisos", "Pendientes y seguimiento"],
            isBuiltIn: true
        ),
        SummaryTemplate(
            id: "reflexion",
            name: "Reflexión personal",
            instructions: "Organiza una reflexión personal sin convertirla en acta de decisiones.",
            sections: ["Ideas y temas principales", "Reflexiones y conclusiones", "Preguntas abiertas", "Posibles acciones"],
            isBuiltIn: true
        ),
    ]
}

public struct SummaryTemplateStore {
    public var fileURL: URL
    public var fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func loadCustom() throws -> [SummaryTemplate] {
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return [] }
        return try JSONDecoder().decode([SummaryTemplate].self, from: data)
    }

    public func loadAll() throws -> [SummaryTemplate] {
        SummaryTemplateCatalog.builtIns + (try loadCustom())
    }

    public func saveCustom(_ templates: [SummaryTemplate]) throws {
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(templates).write(to: fileURL, options: .atomic)
    }

    @discardableResult
    public func create(name: String, instructions: String, sections: [String]) throws -> SummaryTemplate {
        var custom = try loadCustom()
        let template = SummaryTemplate(name: name, instructions: instructions, sections: sections)
        custom.append(template)
        try saveCustom(custom)
        return template
    }

    public func update(_ template: SummaryTemplate) throws {
        guard !template.isBuiltIn else { throw SummaryTemplateError.builtInImmutable }
        var custom = try loadCustom()
        guard let index = custom.firstIndex(where: { $0.id == template.id }) else {
            throw SummaryTemplateError.notFound
        }
        custom[index] = template
        try saveCustom(custom)
    }

    public func delete(id: String) throws {
        var custom = try loadCustom()
        guard let index = custom.firstIndex(where: { $0.id == id }) else {
            throw SummaryTemplateError.notFound
        }
        custom.remove(at: index)
        try saveCustom(custom)
    }

    @discardableResult
    public func duplicateBuiltIn(_ template: SummaryTemplate) throws -> SummaryTemplate {
        guard template.isBuiltIn else { throw SummaryTemplateError.notBuiltIn }
        var custom = try loadCustom()
        var copy = template
        copy.id = UUID().uuidString
        copy.name = "\(template.name) (copia)"
        copy.isBuiltIn = false
        custom.append(copy)
        try saveCustom(custom)
        return copy
    }

    public func search(_ query: String) throws -> [SummaryTemplate] {
        let all = try loadAll()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}

public enum SummaryTemplateError: Error, LocalizedError, Equatable {
    case builtInImmutable
    case notBuiltIn
    case notFound
    case emptyName

    public var errorDescription: String? {
        switch self {
        case .builtInImmutable: return "Las plantillas predefinidas no se pueden modificar; duplícalas para editarlas."
        case .notBuiltIn: return "Solo se pueden duplicar las plantillas predefinidas."
        case .notFound: return "No se encontró la plantilla."
        case .emptyName: return "La plantilla necesita un nombre."
        }
    }
}
