import SwiftUI

struct EditLotteryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var lottery: Lottery
    var rounds: [String]
    @State private var selectedRound = ""
    @State private var number = ""
    @State private var quantity = 1
    @State private var message = ""
    var onSave: () -> Void
    
    let BASE_URL = Bundle.main.infoDictionary?["BASE_URL"] as? String
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("แก้ไขหวย")
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
                    
                    TextField("เลขหวย (6 หลัก)", text: $number)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: geo.size.width * 0.7)
                    
                    VStack(spacing: 5) {
                        Text("จำนวน")
                            .font(.subheadline)
                        Picker("จำนวน", selection: $quantity) {
                            ForEach(1...100, id: \.self) { i in
                                Text("\(i) ใบ").tag(i)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: geo.size.width * 0.4)
                        .clipped()
                    }
                    
                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: saveLottery) {
                        Text("บันทึกการแก้ไข")
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
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 250/255, green: 250/255, blue: 255/255), 
                        Color(red: 240/255, green: 230/255, blue: 255/255)  
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .onAppear {
                number = lottery.number
                selectedRound = lottery.round
                quantity = lottery.quantity
            }
        }
    }
    
    func saveLottery() {
        guard !number.isEmpty else {
            message = "กรุณากรอกเลขหวย"
            return
        }
        
        guard let url = URL(string: "\(BASE_URL)/lottery/\(lottery.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
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
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    message = "เกิดข้อผิดพลาด: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    message = "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                } else {
                    message = "อัปเดตไม่สำเร็จ (รหัส: \(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
}