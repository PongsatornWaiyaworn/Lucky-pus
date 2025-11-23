import SwiftUI
import PhotosUI

struct EvidenceView: View {
    var lottery: Lottery
    var onUpdated: () -> Void
    var onClose: (() -> Void)? = nil 
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showUploadConfirm = false
    @State private var showUploadResult = false
    @State private var uploadMessage = ""
    @State private var showDeleteConfirm = false
    
    let BASE_URL = "https://locky-pus-api.onrender.com"
    
    var body: some View {
        VStack(spacing: 20) {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            } else if let urlStr = lottery.image_url, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 300)
            } else {
                Text("ยังไม่มีหลักฐาน")
                    .foregroundColor(.gray)
                    .frame(maxHeight: 300)
            }
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("เพิ่ม / เปลี่ยนรูปหลักฐาน")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        showUploadConfirm = true
                    }
                }
            }
            
            if lottery.image_url != nil || selectedImage != nil {
                Button("ลบรูปหลักฐาน") {
                    showDeleteConfirm = true
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .alert("ยืนยันการอัพโหลดรูป?", isPresented: $showUploadConfirm) {
            Button("ยืนยัน") {
                if let img = selectedImage {
                    uploadImage(img)
                }
            }
            Button("ยกเลิก", role: .cancel) {
                selectedImage = nil
            }
        }
        .alert(uploadMessage, isPresented: $showUploadResult) {
            Button("OK") {
                uploadMessage = ""
                onUpdated()
                onClose?() 
            }
        }
        .alert("คุณต้องการลบหลักฐานจริงหรือไม่?", isPresented: $showDeleteConfirm) {
            Button("ลบ", role: .destructive) {
                deleteImage()
            }
            Button("ยกเลิก", role: .cancel) {}
        }
    }
    
    func uploadImage(_ img: UIImage) {
        guard let url = URL(string: "\(BASE_URL)/lottery/upload-image") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"lottery_id\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(lottery.id)\r\n".data(using: .utf8)!)
        
        let imgData = img.jpegData(compressionQuality: 0.😎!
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image\"; filename=\"lottery.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(imgData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    uploadMessage = "เกิดข้อผิดพลาด: \(error.localizedDescription)"
                } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    uploadMessage = "อัพโหลดสำเร็จ!"
                    selectedImage = nil
                } else {
                    uploadMessage = "ไม่สามารถอัพโหลดได้"
                }
                showUploadResult = true
            }
        }.resume()
    }
    
    func deleteImage() {
        guard let url = URL(string: "\(BASE_URL)/lottery/delete-image/\(lottery.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                selectedImage = nil
                onUpdated()
                onClose?() 
            }
        }.resume()
    }
}