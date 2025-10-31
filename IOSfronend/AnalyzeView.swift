import SwiftUI

struct AnalyzeResponse: Codable {
    let lucky_number: String
    let total_checked: Int
    let total_prize: Int
    let total_win: Int
    let win_rate: Double
}

struct AnalyzeView: View {
    @State private var analyzeData: AnalyzeResponse? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @AppStorage("accessToken") var accessToken: String = ""
    
    let BASE_URL = Bundle.main.infoDictionary?["BASE_URL"] as? String
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 250/255, green: 250/255, blue: 255/255),
                        Color(red: 240/255, green: 230/255, blue: 255/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("กำลังโหลดข้อมูล…")
                        .font(.title3)
                        .foregroundColor(.gray)
                } else if let err = errorMessage {
                    Text("เกิดข้อผิดพลาด: \(err)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if let data = analyzeData {
                    VStack(spacing: 30) {
                        VStack(spacing: 12) {
                            Text("เลขนำโชคของคุณคือ")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.purple.opacity(0.8))
                            
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 250/255, green: 215/255, blue: 0/255), 
                                                Color(red: 255/255, green: 240/255, blue: 180/255) 
                                            ]),
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 120
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    .shadow(color: .yellow.opacity(0.6), radius: 20, x: 0, y: 5)
                                    .overlay(
                                        Circle()
                                            .stroke(LinearGradient(
                                                colors: [.yellow, .orange, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing),
                                                    lineWidth: 4)
                                    )
                                    .blur(radius: 0.5)
                                
                                Text(data.lucky_number)
                                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 255/255, green: 80/255, blue: 0/255),
                                                Color(red: 200/255, green: 0/255, blue: 200/255)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: .yellow.opacity(0.9), radius: 15, x: 0, y: 4)
                                    .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 3)
                            }
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 16) {
                            infoRow(title: "จำนวนหวยทั้งหมด:", value: "\(data.total_checked)")
                            infoRow(title: "จำนวนครั้งที่ถูกรางวัล:", value: "\(data.total_win)", color: .green)
                            infoRow(title: "อัตราการถูกรางวัล:", value: String(format: "%.2f%%", data.win_rate), color: .blue)
                            infoRow(title: "รางวัลรวมทั้งหมด:", value: "\(data.total_prize.formattedWithSeparator()) บาท", color: .orange)
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationTitle("วิเคราะห์หวยของฉัน")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchAnalyze()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func infoRow(title: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(color)
        }
        .font(.title3)
    }
    
    func fetchAnalyze() {
        guard let url = URL(string: "\(BASE_URL)/lottery/analyze") else {
            self.errorMessage = "URL ไม่ถูกต้อง"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if !accessToken.isEmpty {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = "ไม่มีข้อมูลจากเซิร์ฟเวอร์"
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(AnalyzeResponse.self, from: data)
                    self.analyzeData = decoded
                } catch {
                    self.errorMessage = "ถอดรหัสข้อมูลไม่สำเร็จ: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

extension Int {
    func formattedWithSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
