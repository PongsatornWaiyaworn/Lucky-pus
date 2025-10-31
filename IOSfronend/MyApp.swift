import SwiftUI

@main
struct MyApp: App {
    @AppStorage("accessToken") var accessToken: String = ""

    var body: some Scene {
        WindowGroup {
            if accessToken.isEmpty {
                LoginView()  
            } else {
                MainTabView() 
            }
        }
    }
}