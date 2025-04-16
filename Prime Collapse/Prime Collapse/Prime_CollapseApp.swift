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
        // Use a simpler approach with a separate modelContainer creation method
        .modelContainer(createModelContainer())
    }
    
    // Create a model container with error handling
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

// V1 is the current schema with endingType
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

// Updated schema that fixes the array materialization issue
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SavedGameState.self]
    }
}

// MARK: - Migration Plans
// This defines how to migrate between schema versions

enum SavedGameStateMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
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
                // Create a new SavedGameState with serialized arrays
                let newGame = SavedGameState(
                    totalPackagesShipped: oldGame.totalPackagesShipped,
                    money: oldGame.money,
                    workers: oldGame.workers,
                    automationRate: oldGame.automationRate,
                    moralDecay: oldGame.moralDecay,
                    isCollapsing: oldGame.isCollapsing,
                    purchasedUpgradeIDs: oldGame.purchasedUpgradeIDs,
                    repeatableUpgradeIDs: oldGame.repeatableUpgradeIDs,
                    packageAccumulator: oldGame.packageAccumulator,
                    ethicalChoicesMade: oldGame.ethicalChoicesMade,
                    endingType: oldGame.endingType
                )
                
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
 
 1. Create a new schema version (SchemaV2) by uncommenting and modifying the template above
 2. In that schema version, declare a new model class (SavedGameStateV2) with all existing properties 
    plus your new properties
 3. Uncomment and update the SavedGameStateMigrationPlan to include the migration
 4. In the App's scene builder, update the modelContainer line to:
    .modelContainer(for: Schema([SavedGameState.self]), migrationPlan: SavedGameStateMigrationPlan.self)
 5. Once the migration is complete, update your actual SavedGameState model to match SavedGameStateV2
 
 IMPORTANT TIPS:
 - Always make new properties optional or provide default values during migration
 - If renaming properties, use @Attribute(originalName: "oldName") on the new property
 - Test migrations thoroughly before releasing
 */
