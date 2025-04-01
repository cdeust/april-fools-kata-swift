import Foundation

// MARK: - Role Enum
enum Role: String, CaseIterable {
    case employee
    case manager
    case developer
    case corporatePlayer
    case hr
    case uxui

    static func random() -> Role {
        let allCases = Role.allCases
        let randomIndex = Int.random(in: 0..<allCases.count)
        return allCases[randomIndex]
    }
}

// MARK: - Strategy Factory Interface
protocol StrategyFactory {
    associatedtype StrategyType
    static func createStrategy(for identifier: AnyHashable) -> StrategyType?
}

// MARK: - Strategy Registry Interface
protocol StrategyRegistry {
    associatedtype StrategyType
    func register<Factory: StrategyFactory>(factory: Factory.Type) where Factory.StrategyType == StrategyType
    func strategy(for identifier: AnyHashable) -> StrategyType?
}

// MARK: - Generic Strategy Registry
class GenericStrategyRegistry<T>: StrategyRegistry {
    typealias StrategyType = T

    private var factories: [ObjectIdentifier: (AnyHashable) -> T?] = [:]

    func register<Factory: StrategyFactory>(factory: Factory.Type) where Factory.StrategyType == T {
        let key = ObjectIdentifier(factory)
        factories[key] = { identifier in
            return factory.createStrategy(for: identifier)
        }
    }

    func strategy(for identifier: AnyHashable) -> T? {
        for factory in factories.values {
            if let strategy = factory(identifier) {
                return strategy
            }
        }
        return nil
    }
}

// MARK: - Prank Strategy Interface
protocol PrankStrategy {
    var supportedRole: Role { get }
    func generatePrank(for name: String) -> String
}

// MARK: - Prank Strategy Factory
class PrankStrategyFactory: StrategyFactory {
    typealias StrategyType = PrankStrategy

    static func createStrategy(for identifier: AnyHashable) -> PrankStrategy? {
        guard let role = identifier as? Role else { return nil }

        switch role {
            case .employee:
                return EmployeePrankStrategy()
            case .manager:
                return ManagerPrankStrategy()
            case .developer:
                return DeveloperPrankStrategy()
            case .corporatePlayer:
                return CorporatePlayerPrankStrategy()
            case .hr:
                return HRPrankStrategy()
            case .uxui:
                return UXUIPrankStrategy()
        }
    }
}

// MARK: - Different Strategies
struct EmployeePrankStrategy: PrankStrategy {
    var supportedRole: Role = .employee

    func generatePrank(for name: String) -> String {
        return "Congratulations \(name)! You have been promoted to Chief Joke Officer!"
    }
}

struct ManagerPrankStrategy: PrankStrategy {
    var supportedRole: Role = .manager

    func generatePrank(for name: String) -> String {
        return "URGENT: Surprise meeting with the CEO in 5 minutes. Prepare a presentation!"
    }
}

struct DeveloperPrankStrategy: PrankStrategy {
    var supportedRole: Role = .developer

    func generatePrank(for name: String) -> String {
        return "[CRITICAL ALERT] A fatal error has been detected in your IDE! Error code: APR-001."
    }
}

struct CorporatePlayerPrankStrategy: PrankStrategy {
    var supportedRole: Role = .corporatePlayer

    func generatePrank(for name: String) -> String {
        return "URGENT Circle meeting about objectives in 3 min"
    }
}

struct HRPrankStrategy: PrankStrategy {
    var supportedRole: Role = .hr

    func generatePrank(for name: String) -> String {
        return "You're demoted to Standardist!"
    }
}

struct UXUIPrankStrategy: PrankStrategy {
    var supportedRole: Role = .uxui

    func generatePrank(for name: String) -> String {
        return "The figma files disappeared and we have a meeting in 5 min."
    }
}

// MARK: - Strategy that will be injected

struct InternPrankStrategy: PrankStrategy {
    var supportedRole: Role = .employee // Can reuse existing roles

    func generatePrank(for name: String) -> String {
        return "Hey \(name), the CEO wants you to get coffee for the entire department!"
    }
}

// MARK: - Factory for Strategy that will be injected (could handle more)

class InternPrankFactory: StrategyFactory {
    typealias StrategyType = PrankStrategy

    static func createStrategy(for identifier: AnyHashable) -> PrankStrategy? {
        guard let role = identifier as? Role, role == .employee else { return nil }
        return InternPrankStrategy()
    }
}

// MARK: - Prank Generator
class PrankGenerator {
    private let registry: GenericStrategyRegistry<PrankStrategy>
    private let defaultPrank: String

    init(defaultPrank: String = "April Fools!") {
        self.registry = GenericStrategyRegistry<PrankStrategy>()
        self.defaultPrank = defaultPrank

        registry.register(factory: PrankStrategyFactory.self)
    }

    func registerStrategyFactory<Factory: StrategyFactory>(factory: Factory.Type) where Factory.StrategyType == PrankStrategy {
        registry.register(factory: factory)
    }

    func generatePrank(for name: String, with role: Role) -> String {
        if let strategy = registry.strategy(for: role) {
            return strategy.generatePrank(for: name)
        }
        return defaultPrank
    }
}

// MARK: - Main App
class AprilFoolsApp {
    static func main() {
        // Create generator with default strategies
        let generator = PrankGenerator()

        // Generate pranks for standard examples
        print("\nStandard examples:")
        print(generator.generatePrank(for: "Alice", with: .employee))
        print(generator.generatePrank(for: "Bob", with: .manager))
        print(generator.generatePrank(for: "Charlie", with: .developer))
        print(generator.generatePrank(for: "Dave", with: .corporatePlayer))
        print(generator.generatePrank(for: "Samantha", with: .hr))
        print(generator.generatePrank(for: "John", with: .uxui))

        // Generate pranks with random roles
        print("\nRandom role examples:")
        for i in 1...10 {
            let randomRole = Role.random()
            let name = "Person \(i)"
            print("[\(name)][\(randomRole)] \(generator.generatePrank(for: name, with: randomRole))")
        }

        // Generate pranks for injected roles
        print("\nExtended strategies example:")
        let extendedGenerator = PrankGenerator()
        extendedGenerator.registerStrategyFactory(factory: InternPrankFactory.self)

        print(extendedGenerator.generatePrank(for: "Intern Alice", with: .employee))
    }
}

AprilFoolsApp.main()

print("===================================================================================================")

import XCTest

// MARK: - Unit Tests
class PrankGeneratorTests: XCTestCase {

    func testDefaultStrategies() {
        // Given
        let generator = PrankGenerator()

        // When & Then
        XCTAssertEqual(
            generator.generatePrank(for: "Alice", with: .employee),
            "Congratulations Alice! You have been promoted to Chief Joke Officer!"
        )

        XCTAssertEqual(
            generator.generatePrank(for: "Bob", with: .manager),
            "URGENT: Surprise meeting with the CEO in 5 minutes. Prepare a presentation!"
        )

        XCTAssertEqual(
            generator.generatePrank(for: "Charlie", with: .developer),
            "[CRITICAL ALERT] A fatal error has been detected in your IDE! Error code: APR-001."
        )

        XCTAssertEqual(
            generator.generatePrank(for: "Dave", with: .corporatePlayer),
            "April Fools, Corporate player!"
        )
    }

    func testExtendingWithNewFactory() {
        // Given
        let generator = PrankGenerator()

        // When
        let beforeExtending = generator.generatePrank(for: "Intern", with: .employee)

        // Then
        XCTAssertEqual(beforeExtending, "Congratulations Intern! You have been promoted to Chief Joke Officer!")

        // When - Add a custom factory for interns
        generator.registerStrategyFactory(factory: InternPrankFactory.self)
        let afterExtending = generator.generatePrank(for: "Intern", with: .employee)

        // Then - Now we should get the intern prank
        XCTAssertEqual(afterExtending, "Hey Intern, the CEO wants you to get coffee for the entire department!")
    }
}

// MARK: - Run tests
func runTests() {
    let testCase = PrankGeneratorTests()
    testCase.testDefaultStrategies()
    testCase.testExtendingWithNewFactory()
    print("All tests passed!")
}

runTests()
