import SwiftUI
import PhotosUI

let BASE_URL = "https://locky-pus-api.onrender.com"

struct LotteryCardView: View {
    var lottery: Lottery
    var rounds: [String]
    var onEdit: (Lottery) -> Void
    var onDelete: (Lottery) -> Void
    var onOpenEvidence: (Lottery) -> Void   
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            
            Text(lottery.number)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .yellow],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
            
            Text("งวด: \(lottery.round)")
                .font(.subheadline).foregroundColor(.white.opacity(0.9))
            
            Text("จำนวน: \(lottery.quantity)")
                .font(.subheadline).foregroundColor(.white.opacity(0.9))
            
            Text("สถานะ: \(lottery.status)")
                .font(.subheadline).foregroundColor(.white.opacity(0.9))
            
            Button(lottery.image_url == nil ? "เพิ่มหลักฐาน" : "ดูหลักฐาน") {
                onOpenEvidence(lottery)
            }
            .frame(maxWidth: .infinity)
            .padding(😎
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            HStack(spacing: 15) {
                if lottery.status == "ยังไม่ตรวจสอบ" && rounds.contains(lottery.round) {
                    Button("แก้ไข") { onEdit(lottery) }
                        .frame(maxWidth: .infinity)
                        .padding(😎
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button("ลบ") { onDelete(lottery) }
                    .frame(maxWidth: .infinity)
                    .padding(😎
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(cardGradient(for: lottery))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    func cardGradient(for lottery: Lottery) -> LinearGradient {
        if lottery.status.hasPrefix("ถูกรางวัล") {
            return LinearGradient(
                gradient: Gradient(colors: [
                    .green, .green.opacity(0.7), .green.opacity(0.3)
                ]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else if lottery.status.hasPrefix("ไม่ถูกรางวัล") {
            return LinearGradient(
                colors: [.gray, .gray.opacity(0.6), .gray.opacity(0.3)],
                startPoint: .top, endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [.purple, .purple.opacity(0.7), .purple.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}