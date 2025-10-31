import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var message = ""
    @State private var showingRegister = false
    @State private var showMainTab = false   
    
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("refreshToken") var refreshToken: String = ""
    
    let BASE_URL = Bundle.main.infoDictionary?["BASE_URL"] as? String
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 25) {
                    Spacer()
                    
                    Image("./Image/LOGO.png")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(geo.size.width * 0.6, 300), height: 200)
                        .grayscale(0.1)
                        .brightness(-0.05)
                        .opacity(0.9)
                    
                    VStack(spacing: 15) {
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
                        
                        HStack(spacing: 15) {
                            Button(action: loginWithUsername) {
                                Text("เข้าสู่ระบบ")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { showingRegister = true }) {
                                Text("สมัครสมาชิก")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxWidth: min(500, geo.size.width * 0.8))
                    
                    Divider()
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                    
                    Button(action: loginWithBiometric) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("เข้าสู่ระบบด้วย Face ID / Touch ID")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.gray))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: min(500, geo.size.width * 0.8))
                    
                    Text(message)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: min(500, geo.size.width * 0.8))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            }
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView(showingRegister: $showingRegister)
        }
        .fullScreenCover(isPresented: $showMainTab) {
            MainTabView()
        }
    }
    
    func loginWithUsername() {
        guard !username.isEmpty && !password.isEmpty else {
            message = "กรุณากรอกชื่อผู้ใช้และรหัสผ่าน"
            return
        }
        guard let url = URL(string: "\(BASE_URL)/auth/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let deviceName = UIDevice.current.name
        
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "device_id": deviceID,
            "name": deviceName
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    message = error.localizedDescription
                    return
                }
                guard let data = data else {
                    message = "ไม่มีการตอบกลับจากเซิร์ฟเวอร์"
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let access = json["access_token"] as? String,
                       let refresh = json["refresh_token"] as? String {
                        accessToken = access
                        refreshToken = refresh
                        message = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showMainTab = true
                        }
                    } else if let err = json["error"] as? String {
                        message = err
                    } else {
                        message = "ข้อมูลที่ได้รับไม่ถูกต้อง"
                    }
                }
            }
        }.resume()
    }
    
    func loginWithBiometric() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "เข้าสู่ระบบด้วย Face ID / Touch ID"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success { performBiometricLogin() }
                    else { message = "การยืนยันตัวตนไม่สำเร็จ" }
                }
            }
        } else { message = "อุปกรณ์นี้ไม่รองรับการยืนยันตัวตนแบบไบโอเมตริกซ์" }
    }
    
    func performBiometricLogin() {
        guard let url = URL(string: "\(BASE_URL)/auth/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let deviceName = UIDevice.current.name
        let body: [String: Any] = ["device_id": deviceID, "name": deviceName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { message = error.localizedDescription; return }
                guard let data = data else { message = "ไม่มีการตอบกลับจากเซิร์ฟเวอร์"; return }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let access = json["access_token"] as? String,
                       let refresh = json["refresh_token"] as? String {
                        accessToken = access
                        refreshToken = refresh
                        message = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showMainTab = true
                        }
                    } else if let err = json["error"] as? String {
                        message = err
                    } else {
                        message = "ข้อมูลที่ได้รับไม่ถูกต้อง"
                    }
                }
            }
        }.resume()
    }
}