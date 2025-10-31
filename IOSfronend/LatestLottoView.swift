import SwiftUI

struct LatestLottoView: View {
    @State private var lottoData: LottoResponse? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
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
                    VStack(spacing: 15) {
                        ProgressView()
                        Text("กำลังโหลดข้อมูล…")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                    .transition(.opacity.combined(with: .scale))
                } else if let error = errorMessage {
                    Text("เกิดข้อผิดพลาด: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .transition(.opacity)
                } else if let lottoDetail = lottoData?.response {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("งวดวันที่ \(lottoDetail.date)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.purple.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 25)
                            
                            if let firstPrize = lottoDetail.prizes.first(where: { $0.id == "prizeFirst" }) {
                                FirstPrizeCard(numbers: firstPrize.number, reward: firstPrize.reward)
                            }
                            
                            PrizeCard(title: "เลขหน้า 3 ตัว",
                                      reward: "4,000 บาท",
                                      numbers: lottoDetail.runningNumbers.first(where: { $0.id == "runningNumberFrontThree" })?.number ?? [])
                            
                            PrizeCard(title: "เลขท้าย 3 ตัว",
                                      reward: "4,000 บาท",
                                      numbers: lottoDetail.runningNumbers.first(where: { $0.id == "runningNumberBackThree" })?.number ?? [])
                            
                            PrizeCard(title: "เลขท้าย 2 ตัว",
                                      reward: "2,000 บาท",
                                      numbers: lottoDetail.runningNumbers.first(where: { $0.id == "runningNumberBackTwo" })?.number ?? [])
                            
                            if let endpoint = lottoDetail.endpoint, let url = URL(string: endpoint) {
                                Link(destination: url) {
                                    Text("ดูรายละเอียดเพิ่มเติมที่ Sanook")
                                        .font(.headline)
                                        .padding()
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(colors: [.blue, .purple],
                                                           startPoint: .leading,
                                                           endPoint: .trailing)
                                        )
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .navigationTitle("หวยล่าสุด")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { fetchLottoData() }
        }
    }
    
    func fetchLottoData() {
        guard let url = URL(string: "https://lotto.api.rayriffy.com/latest") else {
            self.errorMessage = "URL ไม่ถูกต้อง"
            self.isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "เกิดข้อผิดพลาด: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    self.errorMessage = "ไม่พบข้อมูลจากเซิร์ฟเวอร์"
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(LottoResponse.self, from: data)
                    self.lottoData = decoded
                } catch {
                    self.errorMessage = "ไม่สามารถแปลงข้อมูลได้: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct FirstPrizeCard: View {
    var numbers: [String]
    var reward: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("รางวัลที่ 1")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .red],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
            
            if let number = numbers.first {
                Text(number)
                    .font(.system(size: 48, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(15)
                    .shadow(radius: 5)
            } else {
                Text("ไม่มีข้อมูล")
                    .foregroundColor(.gray)
            }
            
            Text("รางวัลละ \(reward)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 3)
    }
}

struct PrizeCard: View {
    var title: String
    var reward: String
    var numbers: [String]
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
            
            if !numbers.isEmpty {
                let columns = [GridItem(.flexible(), spacing: 20)]
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(numbers, id: \.self) { num in
                        Text(num)
                            .font(.system(size: 24, weight: .semibold, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(maxWidth: 400) 
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .center) 
            } else {
                Text("ไม่มีข้อมูล")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
            
            Text("รางวัลละ \(reward)")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 3)
        .frame(maxWidth: 450)
        .frame(maxWidth: .infinity, alignment: .center) 
    }
}

struct LottoResponse: Codable {
    let status: String
    let response: LottoDetail
}

struct LottoDetail: Codable {
    let date: String
    let endpoint: String?
    let prizes: [Prize]
    let runningNumbers: [Prize]
}

struct Prize: Codable, Identifiable {
    let id: String
    let name: String
    let reward: String
    let amount: Int
    let number: [String]
}