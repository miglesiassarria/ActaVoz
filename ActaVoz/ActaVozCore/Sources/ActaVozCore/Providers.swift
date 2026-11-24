import Foundation
import Security

public enum ProviderKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case openAI
    case claude
    case openCodeGo
    case ollama
    case generic

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .claude: return "Claude"
        case .openCodeGo: return "OpenCode Go"
        case .ollama: return "Ollama"
        case .generic: return "Proveedor genérico"
        }
    }

    public var defaultBaseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .claude: return "https://api.anthropic.com"
        case .openCodeGo: return "https://opencode.ai/inference/go/v1"
        case .ollama: return "http://127.0.0.1:11434"
        case .generic: return ""
        }
    }

    public var requiresKey: Bool {
        switch self {
        case .ollama: return false
        default: return true
        }
    }

    /// 0013 confirmó que no hay OAuth público autorizado para esta app.
    public var supportsOAuth: Bool { false }
}

public struct ProviderConnection: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var kind: ProviderKind
    public var baseURL: String
    public var defaultModel: String
    public var models: [String]

    public init(
        id: String = UUID().uuidString,
        name: String,
        kind: ProviderKind,
        baseURL: String? = nil,
        defaultModel: String = "",
        models: [String] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.baseURL = baseURL ?? kind.defaultBaseURL
        self.defaultModel = defaultModel
        self.models = models
    }
}

public struct ModelSelection: Codable, Equatable, Hashable, Sendable {
    public var connectionID: String
    public var model: String

    public init(connectionID: String, model: String) {
        self.connectionID = connectionID
        self.model = model
    }
}

public enum ModelUse: String, Codable, Sendable {
    case chat
    case summary
    case names
}

public struct ProviderConfiguration: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var connections: [ProviderConnection]
    public var activeConnectionID: String?
    public var chatModel: ModelSelection?
    public var summaryModel: ModelSelection?

    public init(
        schemaVersion: Int = ProviderConfiguration.currentSchemaVersion,
        connections: [ProviderConnection] = [],
        activeConnectionID: String? = nil,
        chatModel: ModelSelection? = nil,
        summaryModel: ModelSelection? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.connections = connections
        self.activeConnectionID = activeConnectionID
        self.chatModel = chatModel
        self.summaryModel = summaryModel
    }

    public var activeConnection: ProviderConnection? {
        guard let activeConnectionID else { return nil }
        return connections.first { $0.id == activeConnectionID }
    }

    public var hasProvider: Bool { activeConnection != nil }

    public var primarySelection: ModelSelection? {
        guard let connection = activeConnection, !connection.defaultModel.isEmpty else { return nil }
        return ModelSelection(connectionID: connection.id, model: connection.defaultModel)
    }

    public func selection(for use: ModelUse) -> ModelSelection? {
        switch use {
        case .chat: return chatModel ?? primarySelection
        case .summary: return summaryModel ?? primarySelection
        case .names: return primarySelection
        }
    }

    public func connection(for selection: ModelSelection) -> ProviderConnection? {
        connections.first { $0.id == selection.connectionID }
    }
}

public enum ProviderConfigurationError: Error, LocalizedError, Equatable {
    case cannotRead(URL, reason: String)
    case cannotWrite(URL, reason: String)
    case connectionNotFound(String)
    case missingModel

    public var errorDescription: String? {
        switch self {
        case .cannotRead(let url, let reason): return "No se pudo leer la configuración de proveedores: \(reason)"
        case .cannotWrite(_, let reason): return "No se pudo guardar la configuración de proveedores: \(reason)"
        case .connectionNotFound(let id): return "No se encontró la conexión «\(id)»."
        case .missingModel: return "Selecciona un modelo para esta función."
        }
    }
}

public struct ProviderConfigurationStore {
    public var fileURL: URL
    public var fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func load() throws -> ProviderConfiguration {
        guard fileManager.fileExists(atPath: fileURL.path) else { return ProviderConfiguration() }
        do {
            let data = try Data(contentsOf: fileURL)
            guard !data.isEmpty else { return ProviderConfiguration() }
            return try JSONDecoder().decode(ProviderConfiguration.self, from: data)
        } catch {
            throw ProviderConfigurationError.cannotRead(fileURL, reason: error.localizedDescription)
        }
    }

    public func save(_ configuration: ProviderConfiguration) throws {
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(configuration).write(to: fileURL, options: .atomic)
        } catch {
            throw ProviderConfigurationError.cannotWrite(fileURL, reason: error.localizedDescription)
        }
    }
}

public protocol SecretStore: Sendable {
    func set(_ secret: String, for account: String) throws
    func secret(for account: String) throws -> String?
    func delete(account: String) throws
}

public enum SecretStoreError: Error, LocalizedError, Equatable {
    case keychain(Int32)
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .keychain(let status): return "El Llavero rechazó la operación (código \(status))."
        case .invalidData: return "El secreto guardado no es válido."
        }
    }
}

/// Credenciales exclusivamente en el Llavero; nunca en JSON ni en logs.
public struct KeychainSecretStore: SecretStore {
    public var service: String

    public init(service: String = "app.actavoz.providers") {
        self.service = service
    }

    private func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    public func set(_ secret: String, for account: String) throws {
        let data = Data(secret.utf8)
        let query = baseQuery(account)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw SecretStoreError.keychain(addStatus) }
        } else if status != errSecSuccess {
            throw SecretStoreError.keychain(status)
        }
    }

    public func secret(for account: String) throws -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw SecretStoreError.keychain(status) }
        guard let value = String(data: data, encoding: .utf8) else { throw SecretStoreError.invalidData }
        return value
    }

    public func delete(account: String) throws {
        let status = SecItemDelete(baseQuery(account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretStoreError.keychain(status)
        }
    }
}

public final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: String] = [:]

    public init() {}

    public func set(_ secret: String, for account: String) throws {
        lock.lock(); defer { lock.unlock() }
        values[account] = secret
    }

    public func secret(for account: String) throws -> String? {
        lock.lock(); defer { lock.unlock() }
        return values[account]
    }

    public func delete(account: String) throws {
        lock.lock(); defer { lock.unlock() }
        values[account] = nil
    }
}
