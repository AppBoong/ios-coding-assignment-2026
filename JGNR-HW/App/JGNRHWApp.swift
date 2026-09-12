import SwiftUI

@main
struct JGNRHWApp: App {
    @State private var dependencies: AppDependencies
    @State private var coordinator: AppCoordinator

    init() {
        let dependencies = AppDependencies()
        _dependencies = State(initialValue: dependencies)
        _coordinator = State(initialValue: AppCoordinator(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                coordinator.rootView()
                    .navigationDestination(for: Route.self) { route in
                        coordinator.destination(for: route)
                    }
            }
            .environment(\.imageLoader, dependencies.imageLoader)
        }
    }
}
