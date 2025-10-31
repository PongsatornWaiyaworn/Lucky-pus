import SwiftUI

struct MainTabView: View {
    @AppStorage("accessToken") var accessToken: String = ""
    
    @State private var showLogoutAlert = false
    @State private var showLogin = false 
    
    var body: some View {
        NavigationStack {
            TabView {
                LatestLottoView()
                    .tabItem {
                        Label("ผลล่าสุด", systemImage: "list.bullet.rectangle")
                    }
                
                LotteryView()
                    .tabItem {
                        Label("ตรวจหวย", systemImage: "magnifyingglass")
                    }
                
                AnalyzeView()
                    .tabItem {
                        Label("วิเคราะห์หวย", systemImage: "chart.bar.doc.horizontal")
                    }
                
                PredictLottoView()
                    .tabItem {
                        Label("คาดการณ์หวย", systemImage: "sparkles")
                    }
            }
            .tint(.purple)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        Image(systemName: "power")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("ยืนยันการออกจากระบบ", isPresented: $showLogoutAlert) {
                Button("ยกเลิก", role: .cancel) {}
                Button("ออกจากระบบ", role: .destructive) {
                    accessToken = ""       
                    showLogin = true         
                }
            }
            .fullScreenCover(isPresented: $showLogin) {
                LoginView()
            }
        }
    }
}
