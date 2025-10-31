import SwiftUI

struct AddLotteryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var number = ""
    @State private var selectedRound = ""
    @State private var quantity = 1 
    var onSave: () -> Void
    
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
        
        return [nextRound, lastRound]
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("เพิ่มหวยใหม่")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Picker("เลือกงวด", selection: $selectedRound) {
                        ForEach(rounds, id: \.self) { round in
                            Text(round).tag(round)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onAppear {
                        selectedRound = rounds.first ?? ""
                    }
                    
                    TextField("เลขหวย (6 หลัก)", text: $number)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: geo.size.width * 0.7)
                    
                    VStack(spacing: 5) {
                        Text("จำนวน: \(quantity)")
                            .font(.headline)
                        Picker("จำนวน", selection: $quantity) {
                            ForEach(1...100, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                    }
                    .frame(maxWidth: geo.size.width * 0.7)
                    .padding(.vertical, 5)
                    
                    Button(action: addLottery) {
                        Text("บันทึกหวย")
                            .bold()
                            .frame(maxWidth: geo.size.width * 0.7)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 250/255, green: 250/255, blue: 255/255),
                    Color(red: 240/255, green: 230/255, blue: 255/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea())
        }
    }
    
    func addLottery() {
        guard !number.isEmpty else { return }
        guard let url = URL(string: "\(BASE_URL)/lottery/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "round": selectedRound,
            "number": number,
            "quantity": quantity
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                number = ""
                quantity = 1
                onSave()
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }
}