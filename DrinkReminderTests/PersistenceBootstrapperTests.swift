import CoreData
import XCTest
@testable import DrinkReminder

@MainActor
final class PersistenceBootstrapperTests: XCTestCase {
    func testBootstrapIsIdempotentAndCreatesRequiredDefaults() throws {
        let persistence = try PersistenceController(inMemory: true)
        let bootstrapper = PersistenceBootstrapper(context: persistence.viewContext)

        try bootstrapper.prepareDefaults()
        try bootstrapper.prepareDefaults()

        XCTAssertEqual(try count("UserProfileEntity", in: persistence.viewContext), 1)
        XCTAssertEqual(try count("AppPreferencesEntity", in: persistence.viewContext), 1)
        XCTAssertEqual(try count("ReminderPreferencesEntity", in: persistence.viewContext), 1)
        XCTAssertEqual(try count("PetProfileEntity", in: persistence.viewContext), 1)
        XCTAssertEqual(try count("ContainerPresetEntity", in: persistence.viewContext), 4)

        let presetRequest = NSFetchRequest<ContainerPresetEntity>(entityName: "ContainerPresetEntity")
        let presets = try persistence.viewContext.fetch(presetRequest)
        XCTAssertEqual(presets.filter(\.isDefault).count, 1)
    }

    private func count(_ entityName: String, in context: NSManagedObjectContext) throws -> Int {
        try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: entityName))
    }
}
