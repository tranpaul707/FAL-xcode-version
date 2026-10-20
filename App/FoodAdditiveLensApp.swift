import SwiftUI

@main
@MainActor
struct FoodAdditiveLensApp: App {
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if persistence.loadError != nil {
                ContentUnavailableView(
                    "Local History Unavailable",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text("The app could not open its local storage. Close and reopen the app to try again.")
                )
                .accessibilityIdentifier("persistenceError")
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistence.container.viewContext)
            }
        }
    }
}
