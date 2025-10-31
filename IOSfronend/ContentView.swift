import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            LoginView()
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}