//======================================================================
// MARK: - DependencyContainer
// Purpose: Simple dependency injection container
// Usage: DependencyContainer.shared.register(...) and resolve(...)
//======================================================================
import Foundation

/// Simple dependency injection container for managing app dependencies
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    private var dependencies: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.couleur.di", attributes: .concurrent)
    
    private init() {
        registerDefaults()
    }
    
    /// Register a dependency
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        queue.async(flags: .barrier) {
            let key = String(describing: type)
            self.dependencies[key] = factory
        }
    }
    
    /// Register a singleton dependency
    func registerSingleton<T>(_ type: T.Type, instance: T) {
        queue.async(flags: .barrier) {
            let key = String(describing: type)
            self.dependencies[key] = instance
        }
    }
    
    /// Resolve a dependency
    func resolve<T>(_ type: T.Type) -> T? {
        queue.sync {
            let key = String(describing: type)
            
            if let instance = dependencies[key] as? T {
                return instance
            }
            
            if let factory = dependencies[key] as? () -> T {
                return factory()
            }
            
            return nil
        }
    }
    
    /// Resolve a dependency (force unwrapped)
    func resolve<T>(_ type: T.Type) -> T {
        guard let dependency = resolve(type) as T? else {
            fatalError("Dependency \(T.self) not registered")
        }
        return dependency
    }
    
    /// Register default dependencies
    private func registerDefaults() {
        // Repositories
        register(UserRepositoryProtocol.self) {
            UserRepository()
        }
        
        // Register AuthManager as protocol
        register((any AuthManagerProtocol).self) {
            AuthManager.shared as any AuthManagerProtocol
        }
        register(SupabaseManager.self) {
            SupabaseManager.shared
        }
        
        // Add more default registrations as needed
    }
    
    /// Register test dependencies for testing
    /// This method should be called from test code with actual mock instances
    func registerTestDependencies(
        userRepository: UserRepositoryProtocol? = nil,
        authManager: (any AuthManagerProtocol)? = nil
    ) {
        // Register test repositories if provided
        if let userRepository = userRepository {
            register(UserRepositoryProtocol.self) {
                userRepository
            }
        }
        
        // Register test auth manager if provided
        if let authManager = authManager {
            register((any AuthManagerProtocol).self) {
                authManager
            }
        }
    }
    
    /// Clear all dependencies (useful for testing)
    func clear() {
        queue.async(flags: .barrier) {
            self.dependencies.removeAll()
        }
    }
}

// MARK: - Property Wrapper for Dependency Injection

/// Property wrapper for injecting dependencies
@propertyWrapper
struct Injected<T> {
    private let dependency: T
    
    init() {
        guard let resolved = DependencyContainer.shared.resolve(T.self) as T? else {
            fatalError("Dependency \(T.self) not registered")
        }
        self.dependency = resolved
    }
    
    var wrappedValue: T {
        dependency
    }
}