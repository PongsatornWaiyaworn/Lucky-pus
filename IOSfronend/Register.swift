import SwiftUI

struct RegisterView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var message = ""
    @State private var isSuccess = false  
    @Binding var showingRegister: Bool
    
    let BASE_URL = Bundle.main.infoDictionary?["BASE_URL"] as? String
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("สมัครสมาชิกใหม่")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 3)
                        .padding(.bottom, 10)
                    
                    TextField("ชื่อผู้ใช้", text: $username)
                        .padding(.horizontal)
                        .frame(height: 45)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .autocapitalization(.none)
                    
                    SecureField("รหัสผ่าน", text: $password)
                        .padding(.horizontal)
                        .frame(height: 45)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    
                    SecureField("ยืนยันรหัสผ่าน", text: $confirmPassword)
                        .padding(.horizontal)
                        .frame(height: 45)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    
                    Button(action: registerUser) {
                        Text("สมัครสมาชิก")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    // ✅ เปลี่ยนสีข้อความตามสถานะ isSuccess
                    Text(message)
                        .foregroundColor(isSuccess ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                        .animation(.easeInOut, value: message)
                    
                    Spacer()
                }
                .frame(maxWidth: min(500, geo.size.width * 0.8))
                .frame(width: geo.size.width, height: geo.size.height)
                .background(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 250/255, green: 250/255, blue: 255/255),
                        Color(red: 240/255, green: 230/255, blue: 255/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("ปิด") { showingRegister = false }
                    }
                }
            }
        }
    }
    
    func registerUser() {
        guard !username.isEmpty && !password.isEmpty else {
            message = "กรุณากรอกชื่อผู้ใช้และรหัสผ่าน"
            isSuccess = false
            return
        }
        guard password == confirmPassword else {
            message = "รหัสผ่านไม่ตรงกัน"
            isSuccess = false
            return
        }
        guard let url = URL(string: "\(BASE_URL)/auth/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    message = error.localizedDescription
                    isSuccess = false
                    return
                }
                guard let data = data else {
                    message = "ไม่มีการตอบกลับจากเซิร์ฟเวอร์"
                    isSuccess = false
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let msg = json["message"] as? String {
                        message = msg
                        isSuccess = true  
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showingRegister = false
                        }
                    } else if let err = json["error"] as? String {
                        message = err
                        isSuccess = false
                    } else {
                        message = "ข้อมูลที่ได้รับไม่ถูกต้อง"
                        isSuccess = false
                    }
                }
            }
        }.resume()
    }
}