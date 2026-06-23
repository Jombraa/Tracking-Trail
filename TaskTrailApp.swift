import SwiftUI
import SwiftData

@main
struct TaskTrailApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([TaskItem.self, TaskCompletion.self, AppState.self])
        // Try CloudKit; fall back to local-only if the entitlement isn't wired up yet.
        let ckConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        let localConfig = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: [ckConfig]) {
            container = c
        } else {
            container = try! ModelContainer(for: schema, configurations: [localConfig])
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
