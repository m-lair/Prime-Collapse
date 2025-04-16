//
//  Prime_CollapseApp.swift
//  Prime Collapse
//
//  Created by Marcus Lair on 4/15/25.
//

import SwiftUI
import SwiftData
import Foundation

@main
struct Prime_CollapseApp: App {
    @State var game = GameState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(game)
        }
        .modelContainer(for: [SavedGameState.self])
    }
}

// MARK: - Schema Versions
// This section defines all schema versions for migration purposes

// V1 is the current schema with endingType
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SavedGameState.self]
    }
}

// When you need to add a new version in the future, do it like this:
/*
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SavedGameStateV2.self]
    }
    
    // Define the updated model structure here
    @Model
    final class SavedGameStateV2 {
        // All your current properties plus new ones
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
        // Add your new properties here
        // var newProperty: String = "default"
        
        // Remember to update the initializer
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
            // self.newProperty = "default"
        }
    }
}
*/

// MARK: - Migration Plans
// This defines how to migrate between schema versions

// For future migrations, you can define a plan like this:
/*
enum SavedGameStateMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    // Migration from V1 to V2
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            // Migration code here to handle setting defaults for new properties
            let descriptor = FetchDescriptor<SchemaV2.SavedGameStateV2>()
            guard let savedGames = try? context.fetch(descriptor) else { return }
            
            for game in savedGames {
                // Set default values for any new properties
                // game.newProperty = "default value"
            }
            
            // Save changes
            try? context.save()
        }
    )
}
*/

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
