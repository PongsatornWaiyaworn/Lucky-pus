import SwiftUI

struct Lottery: Identifiable, Codable {
    let id: String
    let user_id: String
    var round: String
    var number: String
    var quantity: Int
    var status: String
    var image_url: String?
    var created_at: String
    var updated_at: String
}

struct LotteryView: View {
    @State private var lotteries: [Lottery] = []
    @State private var selectedRound = ""
    @State private var showCongrats = false
    @State private var showEditLottery: Lottery? = nil
    
    @State private var lotteryToDelete: Lottery? = nil
    @State private var showDeleteAlert = false
    
    @State private var selectedLotteryForEvidence: Lottery? = nil
    @State private var showEvidenceSheet = false
    
    let BASE_URL = Bundle.main.infoDictionary?["BASE_URL"] as? String
    
    var rounds: [String] {
        let calendar = Calendar.current
        let today = Date()
        let day = calendar.component(.day, from: today)
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)
        
        let lastDay = day >= 16 ? 16 : 1
        let lastRound = String(format: "%02d/%02d/%d", lastDay, month, year)
        
        var nextMonth = month
        var nextYear = year
        let nextDay: Int
        
        if day >= 16 {
            nextDay = 1
            nextMonth += 1
            if nextMonth > 12 {
                nextMonth = 1
                nextYear += 1
            }
        } else {
            nextDay = 16
        }
        
        let nextRound = String(format: "%02d/%02d/%d", nextDay, nextMonth, nextYear)
        return [lastRound, nextRound]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("เลือกงวด", selection: $selectedRound) {
                    ForEach(uniqueRounds().sorted { lhs, rhs in
                        
                        let fmt = DateFormatter()
                        fmt.dateFormat = "dd/MM/yyyy"
                        fmt.locale = Locale(identifier: "th_TH")
                        
                        func convertToAD(_ dateString: String) -> String {
                            let parts = dateString.split(separator: "/").map { String($0) }
                            if parts.count == 3, let buddhistYear = Int(parts[2]) {
                                return "\(parts[0])/\(parts[1])/\(buddhistYear - 543)"
                            }
                            return dateString
                        }
                        
                        let dateLHS = fmt.date(from: convertToAD(lhs)) ?? Date.distantPast
                        let dateRHS = fmt.date(from: convertToAD(rhs)) ?? Date.distantPast
                        
                        return dateLHS > dateRHS
                    }, id: \.self) { round in
                        Text(round).tag(round)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(filteredLotteries()) { lottery in
                            LotteryCardView(
                                lottery: lottery,
                                rounds: rounds,
                                onEdit: { showEditLottery = $0 },
                                onDelete: confirmDeleteLottery,
                                onOpenEvidence: { lot in
                                    selectedLotteryForEvidence = lot
                                    showEvidenceSheet = true
                                }
                            )
                        }
                    }
                }
                .padding(.vertical)
                
                HStack(spacing: 15) {
                    NavigationLink(destination: AddLotteryView(onSave: fetchLotteries)) {
                        Text("➕ เพิ่มหวย")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: checkLatestLottery) {
                        Text("ตรวจสอบ")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("หวยของฉัน")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 250/255, green: 250/255, blue: 255/255),
                        Color(red: 240/255, green: 230/255, blue: 255/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear(perform: fetchLotteries)
            .alert(isPresented: $showCongrats) {
                Alert(title: Text("🎉 ยินดีด้วย!"),
                      message: Text("คุณถูกรางวัล"),
                      dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("ยืนยันการลบ"),
                    message: Text("คุณต้องการลบหวยหมายเลข \(lotteryToDelete?.number ?? "") จริงหรือไม่?"),
                    primaryButton: .destructive(Text("ลบ")) {
                        if let lottery = lotteryToDelete { deleteLottery(lottery) }
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(item: $showEditLottery) { lottery in
                EditLotteryView(lottery: lottery, rounds: rounds, onSave: fetchLotteries)
            }
            
            .sheet(isPresented: $showEvidenceSheet) {
                if let selected = selectedLotteryForEvidence {
                    EvidenceView(lottery: selected, onUpdated: fetchLotteries)
                }
            }
        }
    }
    
    func filteredLotteries() -> [Lottery] {
        if selectedRound.isEmpty, let latest = uniqueRounds().sorted(by: >).first {
            DispatchQueue.main.async { selectedRound = latest }
        }
        return lotteries.filter { $0.round == selectedRound }
    }
    
    func uniqueRounds() -> [String] {
        Array(Set(lotteries.map { $0.round })).sorted(by: >)
    }
    
    func fetchLotteries() {
        guard let url = URL(string: "\(BASE_URL)/lottery/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, var decoded = try? JSONDecoder().decode([Lottery].self, from: data) {
                    decoded = decoded.map { lottery in
                        var l = lottery
                        l.round = convertToBuddhistYear(l.round)
                        return l
                    }
                    self.lotteries = decoded.sorted { $0.round > $1.round }
                }
            }
        }.resume()
    }
    
    func checkLatestLottery() {
        guard let url = URL(string: "\(BASE_URL)/lottery/check") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data,
                   let decoded = try? JSONDecoder().decode([Lottery].self, from: data) {
                    
                    for updated in decoded {
                        if let index = lotteries.firstIndex(where: { $0.id == updated.id }) {
                            lotteries[index].status = updated.status
                        }
                    }
                    
                    if decoded.contains(where: { $0.status.hasPrefix("ถูกรางวัล") }) {
                        showCongrats = true
                    }
                }
            }
        }.resume()
    }
    
    func confirmDeleteLottery(_ lottery: Lottery) {
        lotteryToDelete = lottery
        showDeleteAlert = true
    }
    
    func deleteLottery(_ lottery: Lottery) {
        guard let url = URL(string: "\(BASE_URL)/lottery/\(lottery.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async { fetchLotteries() }
        }.resume()
    }
    
    func convertToBuddhistYear(_ round: String) -> String {
        let components = round.split(separator: "/")
        guard components.count == 3, let year = Int(components[2]) else { return round }
        if year < 2500 {
            return "\(components[0])/\(components[1])/\(year + 543)"
        }
        return round
    }
}