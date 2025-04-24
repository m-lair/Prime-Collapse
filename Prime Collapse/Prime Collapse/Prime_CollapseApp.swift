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
    
    // Add SaveManager
    @State var saveManager: SaveManager?
    
    init() {
        do {
            // Define the schema using the LATEST version
            let schema = Schema(versionedSchema: SchemaV4.self)
            
            // Diagnose store status before attempting migration
            print("Diagnosing store status before migration...")
            Prime_CollapseApp.diagnoseStoreStatus()
            
            // First try with a lightweight migration approach
            do {
                print("Attempting lightweight migration...")
                let config = ModelConfiguration()
                // Try to create the container without specifying a complex migration plan
                container = try ModelContainer(for: schema, configurations: config)
                print("Successfully created ModelContainer with lightweight migration")
            } catch {
                print("Lightweight migration failed: \(error.localizedDescription)")
                print("Migration error details: \(error)")
                
                // If we detect the specific checksum error, clean up the database
                if error.localizedDescription.contains("Duplicate version checksums") {
                    print("Detected checksum issue - attempting recovery by recreating store...")
                    
                    // Only in case of this specific error, we delete the store
                    Prime_CollapseApp.deleteSwiftDataStores()
                    
                    // After deletion, try with a clean store
                    do {
                        container = try ModelContainer(for: schema)
                        print("Recovery successful: Created fresh ModelContainer")
                    } catch {
                        print("Recovery failed: \(error.localizedDescription)")
                        print("Error details: \(error)")
                        
                        // Last resort - in-memory container
                        print("Creating in-memory container as last resort")
                        do {
                            let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                            container = try ModelContainer(for: schema, configurations: memoryConfig)
                            print("Created in-memory container (progress won't be saved)")
                        } catch {
                            fatalError("Failed to create any container: \(error)")
                        }
                    }
                } else {
                    // For other errors, try one more time with simplified migration
                    do {
                        print("Attempting with simplified migration plan...")
                        container = try ModelContainer(
                            for: schema,
                            migrationPlan: SimplifiedMigrationPlan.self
                        )
                        print("Simplified migration successful")
                    } catch {
                        // If that still fails, use in-memory as last resort
                        print("Simplified migration also failed: \(error)")
                        
                        let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                        container = try ModelContainer(for: schema, configurations: memoryConfig)
                        print("Created in-memory container (progress won't be saved)")
                    }
                }
            }
        } catch {
            fatalError("Fatal error in container setup: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(game)
                .environment(gameCenterManager)
                .environment(eventManager)
                .environment(saveManager ?? SaveManager(modelContext: container.mainContext, gameState: game, gameCenterManager: gameCenterManager))
                .onAppear {
                    // Initialize Game Center authentication when app launches
                    gameCenterManager.authenticatePlayer()
                    
                    // Initialize save manager if not already done
                    if saveManager == nil {
                        let manager = SaveManager(
                            modelContext: container.mainContext,
                            gameState: game,
                            gameCenterManager: gameCenterManager
                        )
                        saveManager = manager
                        
                        // Load game state when app first appears
                        manager.loadGameState()
                    }
                }
                .onChange(of: game.totalPackagesShipped) { oldValue, newValue in
                    // Save on milestone package shipping amounts
                    saveManager?.saveOnEvent(.milestone(newValue))
                }
        }
        // Pass the pre-configured container to the view modifier
        .modelContainer(container)
    }
    
    // MARK: - Static Helper Methods
    
    // Attempt to create a container with migration
    static func createModelContainerWithMigration(schema: Schema) throws -> ModelContainer {
        // Standard configuration with migration plan
        let config = ModelConfiguration()
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: SavedGameStateMigrationPlan.self,
                configurations: config
            )
        } catch {
            // Check specifically for the unknown model version error
            let errorString = error.localizedDescription
            if errorString.contains("unknown model version") ||
               errorString.contains("Cannot use staged migration") {
                print("Detected unknown model version error, forcing clean recovery")
                
                // Force delete the store - this is a specialized case
                _ = Prime_CollapseApp.deleteSwiftDataStores()
                
                // Try to create a fresh container without migration plan
                return try ModelContainer(for: schema, configurations: config)
            }
            
            // Re-throw other errors
            throw error
        }
    }
    
    // Create a fresh container without migration
    static func createFreshModelContainer(schema: Schema) throws -> ModelContainer {
        // Fresh configuration
        let config = ModelConfiguration()
        return try ModelContainer(for: schema, configurations: config)
    }
    
    // Helper function to delete SwiftData stores
    static func deleteSwiftDataStores() -> Bool {
        do {
            var success = false
            let fileManager = FileManager.default
            
            // Get the application support directory
            let appSupportDir = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            
            // Try looking in multiple possible locations
            let possibleStorePaths = [
                // Standard path
                appSupportDir.appendingPathComponent("SwiftData", isDirectory: true)
                            .appendingPathComponent("default.store", isDirectory: true),
                
                // Sometimes might be directly in app support
                appSupportDir.appendingPathComponent("default.store", isDirectory: true),
                
                // App bundle identifier path (more likely on newer iOS)
                appSupportDir.appendingPathComponent("com.primegames.primecollapse", isDirectory: true)
                            .appendingPathComponent("default.store", isDirectory: true),
                            
                // Documents directory version as fallback
                try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                            .appendingPathComponent("default.store", isDirectory: true)
            ]
            
            // Try to delete from each possible location
            for storePath in possibleStorePaths {
                if fileManager.fileExists(atPath: storePath.path) {
                    try fileManager.removeItem(at: storePath)
                    print("✅ Successfully deleted SwiftData store at: \(storePath.path)")
                    success = true
                }
            }
            
            // If we didn't find any standard paths, try to search for any .store directories
            if !success {
                print("⚠️ No standard SwiftData store found, searching for any .store directories...")
                
                // List contents of Application Support directory
                if let contents = try? fileManager.contentsOfDirectory(at: appSupportDir, includingPropertiesForKeys: nil) {
                    for item in contents {
                        if item.lastPathComponent.hasSuffix(".store") ||
                           item.lastPathComponent.contains("SwiftData") {
                            try fileManager.removeItem(at: item)
                            print("🔍 Found and deleted possible store at: \(item.path)")
                            success = true
                        }
                    }
                }
            }
            
            return success
        } catch {
            print("❌ Error deleting SwiftData stores: \(error)")
            return false
        }
    }
    
    // Diagnostic helper to check store status and log information
    static func diagnoseStoreStatus() {
        do {
            let fileManager = FileManager.default
            
            // Get the application support directory
            let appSupportDir = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            
            // Try to list contents
            print("📂 Application Support directory: \(appSupportDir.path)")
            if let contents = try? fileManager.contentsOfDirectory(at: appSupportDir, includingPropertiesForKeys: nil) {
                for item in contents {
                    let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    print("  - \(item.lastPathComponent) \(isDirectory ? "(directory)" : "(file)")")
                    
                    // If it's a directory, try to look inside for .store files
                    if isDirectory {
                        if let subContents = try? fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil) {
                            for subItem in subContents {
                                if subItem.lastPathComponent.hasSuffix(".store") {
                                    print("    - 🔍 Found potential store: \(subItem.lastPathComponent)")
                                }
                            }
                        }
                    }
                }
            } else {
                print("❌ Could not list directory contents")
            }
        } catch {
            print("❌ Error diagnosing store status: \(error)")
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

// V4 adds metadata fields
enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SavedGameState.self]
    }
}

// MARK: - Migration Plans
// We're simplifying the migration plan to avoid checksum conflicts

enum SavedGameStateMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]
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
                newGame.lastUpdate = oldGame.lastUpdate
                newGame.packageAccumulator = oldGame.packageAccumulator
                newGame.ethicalChoicesMade = oldGame.ethicalChoicesMade
                newGame.endingType = oldGame.endingType
                
                // Handle the array migration (V1 array -> V2 string)
                newGame.purchasedUpgradeIDsString = SavedGameState.serializeArray(oldGame.purchasedUpgradeIDs)
                newGame.repeatableUpgradeIDsString = SavedGameState.serializeArray(oldGame.repeatableUpgradeIDs)
                
                // Set default values for fields added between V1 and V2
                newGame.workerEfficiency = 1.0
                newGame.workerMorale = 0.8
                newGame.customerSatisfaction = 0.9
                newGame.packageValue = 1.0
                newGame.automationEfficiency = 1.0
                newGame.automationLevel = 0
                newGame.corporateEthics = 0.5
                
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
    
    // Migration from V3 to V4 - adding metadata fields
    static let migrateV3toV4 = MigrationStage.custom(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self,
        willMigrate: nil,
        didMigrate: { context in
            // Fetch all V3 records
            let descriptor = FetchDescriptor<SavedGameState>()
            guard let savedGames = try? context.fetch(descriptor) else { return }
            
            // Add metadata to all saved games
            for savedGame in savedGames {
                savedGame.saveVersion = 4
                savedGame.savedAt = Date()
                savedGame.appVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            }
            
            // Save changes
            try? context.save()
        }
    )
}

// A simplified migration plan that only does lightweight migrations
enum SimplifiedMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV4.self]
    }
    
    static var stages: [MigrationStage] {
        [directMigration]
    }
    
    // Single stage that tries to go directly from any version to V4
    static let directMigration = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV4.self
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
