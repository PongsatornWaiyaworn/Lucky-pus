import SwiftUI

struct PredictLottoView: View {
    @State private var prediction: PredictResponse? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @AppStorage("accessToken") var accessToken: String = ""
    
    let BASE_URL = Bundle.main.infoDictionary?["BASE_URL"] as? String
    
    var body: some View {
        NavigationStack { 
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(.white), Color(.purple).opacity(0.1)]),
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
                } else if let p = prediction {
                    ScrollView { 
                        VStack(spacing: 30) {
                            Text("คาดการณ์งวดต่อไป")
                                .font(.title)
                                .bold()
                                .foregroundColor(.purple.opacity(0.8))
                            
                            VStack(spacing: 20) {
                                predictedNumberCard(title: "รางวัลที่ 1", number: p.first_prize_prediction, color: .yellow)
                                predictedNumberCard(title: "เลข 3 ตัวหน้า", number: p.three_digit_front, color: .green)
                                predictedNumberCard(title: "เลข 3 ตัวหลัง", number: p.three_digit_back, color: .blue)
                                predictedNumberCard(title: "เลข 2 ตัวท้าย", number: p.two_digit_back, color: .orange)
                            }
                            .padding(.horizontal, 30)
                            
                            Text("หมายเหตุ: การคาดการณ์จากข้อมูล 20 งวดย้อนหลัง")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Spacer()
                        }
                        .padding(.vertical)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationTitle("คาดการณ์หวย")
            .navigationBarTitleDisplayMode(.inline)
            .background(LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 250/255, green: 250/255, blue: 255/255), 
                    Color(red: 240/255, green: 230/255, blue: 255/255) 
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .onAppear { fetchPrediction() }
        }
        .navigationViewStyle(StackNavigationViewStyle()) 
    }
    
    func predictedNumberCard(title: String, number: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.7), color.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 5)
                
                Text(number)
                    .font(.system(size: 50, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .frame(height: 110)
        }
    }
    
    func fetchPrediction() {
        guard let url = URL(string: "\(BASE_URL)/lottery/predict") else {
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
                    let decoded = try JSONDecoder().decode(PredictResponse.self, from: data)
                    self.prediction = decoded
                } catch {
                    self.errorMessage = "ถอดรหัสข้อมูลไม่สำเร็จ: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct PredictResponse: Codable {
    let first_prize_prediction: String
    let three_digit_back: String
    let three_digit_front: String
    let two_digit_back: String
}