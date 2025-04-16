//
//  Prime_CollapseApp.swift
//  Prime Collapse
//
//  Created by Marcus Lair on 4/15/25.
//

import SwiftUI
import SwiftData
import Foundation
import GameKit

@main
struct Prime_CollapseApp: App {
    @State var game = GameState()
    @State var gameCenterManager = GameCenterManager()
    @State var eventManager = EventManager()
    
    // Manually create the ModelContainer with the migration plan
    let container: ModelContainer
    
    init() {
        do {
            // Define the schema using the LATEST version
            let schema = Schema(versionedSchema: SchemaV4.self)
            // Create the container using the initializer that accepts a migration plan
            container = try ModelContainer(for: schema, migrationPlan: SavedGameStateMigrationPlan.self)
        } catch {
            // Handle error appropriately - perhaps fatalError for now, or more robust error handling
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(game)
                .environment(gameCenterManager)
                .environment(eventManager)
                .onChange(of: game.totalPackagesShipped) {
                    // Update Game Center scores and achievements when game state changes
                    gameCenterManager.updateFromGameState(game)
                }
        }
        // Pass the pre-configured container to the view modifier
        .modelContainer(container)
    }
    
    // Create a model container with error handling
    // NOTE: This function is no longer directly used when a migration plan is active,
    // but keep it for potential future use or fallback logic.
    private func createModelContainer() -> ModelContainer {
        do {
            // Try the simplest form first
            let container = try ModelContainer(for: SavedGameState.self)
            print("Successfully created model container")
            return container
        } catch {
            print("❌ Error creating model container: \(error)")
            
            // Try with memory-only configuration as an emergency fallback
            print("⚠️ Attempting with memory-only configuration...")
            do {
                let memoryOnlyConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: SavedGameState.self, configurations: memoryOnlyConfig)
                print("✅ Created memory-only container (data won't be saved)")
                return container
            } catch {
                print("❌ Memory-only container also failed: \(error)")
                
                // Last resort: delete the database files and start fresh
                print("🔥 EMERGENCY RECOVERY: Deleting database files and starting fresh...")
                if deleteSwiftDataStores() {
                    do {
                        // Try again with default configuration after deleting files
                        let container = try ModelContainer(for: SavedGameState.self)
                        print("✅ Successfully created container after deleting database")
                        return container
                    } catch {
                        print("❌❌ Complete failure even after deleting database: \(error)")
                    }
                }
                
                // If we reach this point, nothing worked - create an in-memory container
                print("⚠️ Last resort: Creating minimal in-memory container")
                do {
                    let memConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                    return try ModelContainer(for: Schema([]), configurations: memConfig)
                } catch {
                    fatalError("Catastrophic failure: \(error)")
                }
            }
        }
    }
    
    // Helper function to delete SwiftData stores
    private func deleteSwiftDataStores() -> Bool {
        do {
            // Get the application support directory
            let appSupportDir = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            
            // Look for SwiftData/default.store directory
            let storeDir = appSupportDir.appendingPathComponent("SwiftData", isDirectory: true)
                                        .appendingPathComponent("default.store", isDirectory: true)
            
            if FileManager.default.fileExists(atPath: storeDir.path) {
                try FileManager.default.removeItem(at: storeDir)
                print("✅ Successfully deleted SwiftData store directory")
                return true
            } else {
                print("⚠️ SwiftData store directory not found at expected path: \(storeDir.path)")
                
                // Try to find and list all directories in Application Support
                let contents = try? FileManager.default.contentsOfDirectory(
                    at: appSupportDir,
                    includingPropertiesForKeys: nil
                )
                print("📂 App Support contents: \(contents?.map { $0.lastPathComponent } ?? [])")
                
                return false
            }
        } catch {
            print("❌ Error deleting SwiftData stores: \(error)")
            return false
        }
    }
}

// MARK: - Schema Versions
// This section defines all schema versions for migration purposes

// V1 is the original schema
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SavedGameStateV1.self]
    }
    
    // Define the original model structure
    @Model
    final class SavedGameStateV1 {
        var totalPackagesShipped: Int
        var money: Double
        var workers: Int
        var automationRate: Double
        var moralDecay: Double
        var isCollapsing: Bool
        var lastUpdate: Date
        var packageAccumulator: Double
        var ethicalChoicesMade: Int
        var endingType: String
        var purchasedUpgradeIDs: [String]
        var repeatableUpgradeIDs: [String]
        
        init() {
            self.totalPackagesShipped = 0
            self.money = 0.0
            self.workers = 0
            self.automationRate = 0.0
            self.moralDecay = 0.0
            self.isCollapsing = false
            self.lastUpdate = Date()
            self.packageAccumulator = 0.0
            self.ethicalChoicesMade = 0
            self.endingType = "collapse"
            self.purchasedUpgradeIDs = []
            self.repeatableUpgradeIDs = []
        }
    }
}

// V2 fixed array materialization
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        // Point to the explicit V2 model definition below
        [SavedGameStateV2.self]
    }
    
    // Define the model structure AS IT WAS IN V2
    @Model
    final class SavedGameStateV2 {
        var totalPackagesShipped: Int
        var money: Double
        var workers: Int
        var automationRate: Double
        var moralDecay: Double
        var isCollapsing: Bool
        var lastUpdate: Date
        var packageAccumulator: Double
        var ethicalChoicesMade: Int
        var endingType: String
        
        // Worker-related stats (already present in V2)
        var workerEfficiency: Double
        var workerMorale: Double
        var customerSatisfaction: Double
        
        // Package and automation stats (already present in V2)
        var packageValue: Double
        var automationEfficiency: Double
        var automationLevel: Int
        
        // Corporate metrics (already present in V2)
        var corporateEthics: Double
        
        // String-based arrays (from V1->V2 migration)
        var purchasedUpgradeIDsString: String
        var repeatableUpgradeIDsString: String
        
        // V2 did not have publicPerception or environmentalImpact
        
        // Need an init or default values for SwiftData
        init() {
            self.totalPackagesShipped = 0
            self.money = 0.0
            self.workers = 0
            self.automationRate = 0.0
            self.moralDecay = 0.0
            self.isCollapsing = false
            self.lastUpdate = Date()
            self.packageAccumulator = 0.0
            self.ethicalChoicesMade = 0
            self.endingType = "collapse"
            self.workerEfficiency = 1.0
            self.workerMorale = 0.8
            self.customerSatisfaction = 0.9
            self.packageValue = 1.0
            self.automationEfficiency = 1.0
            self.automationLevel = 0
            self.corporateEthics = 0.5
            self.purchasedUpgradeIDsString = "[]"
            self.repeatableUpgradeIDsString = "[]"
        }
    }
}

// V3 adds new metrics (publicPerception, environmentalImpact)
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SavedGameStateV3.self] // Point to the explicit V3 model definition below
    }
    
    // Define the model structure AS IT WAS IN V3
    // This is crucial for the V3 -> V4 migration
    @Model
    final class SavedGameStateV3 {
        var totalPackagesShipped: Int
        var money: Double
        var workers: Int
        var automationRate: Double
        var moralDecay: Double // Still moralDecay in V3
        var isCollapsing: Bool
        var lastUpdate: Date
        var packageAccumulator: Double
        var ethicalChoicesMade: Int
        var endingType: String
        var workerEfficiency: Double
        var workerMorale: Double
        var customerSatisfaction: Double
        var packageValue: Double
        var automationEfficiency: Double
        var automationLevel: Int
        var corporateEthics: Double
        var publicPerception: Double
        var environmentalImpact: Double
        var purchasedUpgradeIDsString: String
        var repeatableUpgradeIDsString: String
        
        init() {
            // Default values reflecting the state in V3
            self.totalPackagesShipped = 0
            self.money = 0.0
            self.workers = 0
            self.automationRate = 0.0
            self.moralDecay = 0.0 // Default V3 value
            self.isCollapsing = false
            self.lastUpdate = Date()
            self.packageAccumulator = 0.0
            self.ethicalChoicesMade = 0
            self.endingType = "collapse"
            self.workerEfficiency = 1.0
            self.workerMorale = 0.8
            self.customerSatisfaction = 0.9
            self.packageValue = 1.0
            self.automationEfficiency = 1.0
            self.automationLevel = 0
            self.corporateEthics = 0.5
            self.publicPerception = 50.0 // Default V3 value
            self.environmentalImpact = 0.0 // Default V3 value
            self.purchasedUpgradeIDsString = "[]"
            self.repeatableUpgradeIDsString = "[]"
        }
    }
}

// V4 renames moralDecay to ethicsScore and inverts its logic
enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SavedGameState.self] // References the latest model definition (with ethicsScore)
    }
}

// MARK: - Migration Plans
// This defines how to migrate between schema versions

enum SavedGameStateMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self] // Add V4
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4] // Add V3 -> V4 stage
    }
    
    // Migration from V1 to V2 - converting array properties to serialized strings
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            // Fetch all V1 records (original schema)
            let descriptorV1 = FetchDescriptor<SchemaV1.SavedGameStateV1>()
            guard let oldGames = try? context.fetch(descriptorV1) else { return }
            
            for oldGame in oldGames {
                // Create a new SavedGameStateV2 instance, mapping V1 data
                let newGame = SchemaV2.SavedGameStateV2()
                
                // Manually map fields from V1 to V2
                newGame.totalPackagesShipped = oldGame.totalPackagesShipped
                newGame.money = oldGame.money
                newGame.workers = oldGame.workers
                newGame.automationRate = oldGame.automationRate
                newGame.moralDecay = oldGame.moralDecay
                newGame.isCollapsing = oldGame.isCollapsing
                newGame.lastUpdate = oldGame.lastUpdate // Keep original date?
                newGame.packageAccumulator = oldGame.packageAccumulator
                newGame.ethicalChoicesMade = oldGame.ethicalChoicesMade
                newGame.endingType = oldGame.endingType
                
                // Handle the array migration (V1 array -> V2 string)
                // We need the serializeArray helper - might need to make it accessible
                // For now, assume it's accessible or redefine it locally if needed.
                // Let's assume SavedGameState.serializeArray is usable for now.
                newGame.purchasedUpgradeIDsString = SavedGameState.serializeArray(oldGame.purchasedUpgradeIDs)
                newGame.repeatableUpgradeIDsString = SavedGameState.serializeArray(oldGame.repeatableUpgradeIDs)
                
                // Set default values for fields added between V1 and V2 (if any)
                // Based on SavedGameStateV2 definition, these were added:
                newGame.workerEfficiency = 1.0 // Default value
                newGame.workerMorale = 0.8 // Default value
                newGame.customerSatisfaction = 0.9 // Default value
                newGame.packageValue = 1.0 // Default value
                newGame.automationEfficiency = 1.0 // Default value
                newGame.automationLevel = 0 // Default value
                newGame.corporateEthics = 0.5 // Default value
                
                // Add new record
                context.insert(newGame)
                
                // Delete the old record
                context.delete(oldGame)
            }
            
            // Save changes
            try? context.save()
        }
    )
    
    // Migration from V2 to V3 - Adding new metrics with default values
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )
    // NOTE: Lightweight migration works here because we are only *adding*
    // new properties, and the SavedGameState.init() provides default values.
    // If we were renaming or deleting properties, a custom migration like V1->V2
    // might be needed.
    
    // Migration from V3 to V4 - Renaming moralDecay to ethicsScore and inverting value
    static let migrateV3toV4 = MigrationStage.custom(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self,
        willMigrate: nil,
        didMigrate: { context in
            // Fetch all V3 records (schema before rename)
            let descriptorV3 = FetchDescriptor<SchemaV3.SavedGameStateV3>()
            guard let oldGames = try? context.fetch(descriptorV3) else { return }
            
            for oldGame in oldGames {
                // Create a new SavedGameState instance (V4 schema with ethicsScore)
                let newGame = SavedGameState() // Use the default init of the latest model
                
                // Manually map fields from V3 to V4
                newGame.totalPackagesShipped = oldGame.totalPackagesShipped
                newGame.money = oldGame.money
                newGame.workers = oldGame.workers
                newGame.automationRate = oldGame.automationRate
                // *** Invert the moralDecay to ethicsScore ***
                newGame.ethicsScore = max(0, min(100, 100.0 - oldGame.moralDecay))
                newGame.isCollapsing = oldGame.isCollapsing // Or recalculate: newGame.ethicsScore <= 0
                newGame.lastUpdate = oldGame.lastUpdate
                newGame.packageAccumulator = oldGame.packageAccumulator
                newGame.ethicalChoicesMade = oldGame.ethicalChoicesMade
                newGame.endingType = oldGame.endingType
                newGame.workerEfficiency = oldGame.workerEfficiency
                newGame.workerMorale = oldGame.workerMorale
                newGame.customerSatisfaction = oldGame.customerSatisfaction
                newGame.packageValue = oldGame.packageValue
                newGame.automationEfficiency = oldGame.automationEfficiency
                newGame.automationLevel = oldGame.automationLevel
                newGame.corporateEthics = oldGame.corporateEthics
                newGame.publicPerception = oldGame.publicPerception
                newGame.environmentalImpact = oldGame.environmentalImpact
                newGame.purchasedUpgradeIDsString = oldGame.purchasedUpgradeIDsString
                newGame.repeatableUpgradeIDsString = oldGame.repeatableUpgradeIDsString
                
                // Add new record
                context.insert(newGame)
                
                // Delete the old record
                context.delete(oldGame)
            }
            
            // Save changes
            try? context.save()
        }
    )
}

// MARK: - Migration Helper Functions

/// This function helps determine if a migration is needed or in progress
/// You can expand this for debugging purposes
func printMigrationInfo() {
    print("Current schema version: \(SchemaV1.versionIdentifier)")
    // When you add more versions, you can print more info here
}

// MARK: - How To Add a New Schema Version
/*
 When you need to add a new property to SavedGameState, follow these steps:
 
 1. Define the new property in the `SavedGameState.swift` model class.
    Make sure to provide a default value in the `init` method.
 2. Create a new schema version enum (e.g., `SchemaV3`) in `Prime_CollapseApp.swift`.
    - Increment the version number (e.g., `Schema.Version(3, 0, 0)`).
    - Set `models` to `[SavedGameState.self]`.
 3. Add the new schema enum to `SavedGameStateMigrationPlan.schemas`.
 4. Define a new migration stage (e.g., `migrateV2toV3`).
    - Use `MigrationStage.lightweight` if you only added new properties with defaults.
    - Use `MigrationStage.custom` for complex changes (renaming, data transformation).
 5. Add the new migration stage to `SavedGameStateMigrationPlan.stages`.
 6. Ensure the `.modelContainer` modifier in the App's `body` is using the migration plan:
    `.modelContainer(for: Schema([SavedGameState.self]), migrationPlan: SavedGameStateMigrationPlan.self)`
 
 IMPORTANT TIPS:
 - Lightweight migration relies on default values in your model's `init`.
 - Test migrations thoroughly, especially after clearing app data or using older builds.
 - Custom migrations require defining the model structure for the `fromVersion` explicitly.
 */
