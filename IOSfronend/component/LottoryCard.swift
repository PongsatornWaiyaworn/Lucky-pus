import SwiftUI

struct LotteryCardView: View {
    var lottery: Lottery
    var rounds: [String]
    var onEdit: (Lottery) -> Void
    var onDelete: (Lottery) -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(lottery.number)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .yellow],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .padding(.vertical, 5)
            
            Text("งวด: \(lottery.round)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.95))
            
            Text("จำนวน: \(lottery.quantity)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Text("สถานะ: \(lottery.status)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 15) {
                if lottery.status == "ยังไม่ตรวจสอบ" && rounds.contains(lottery.round) {
                    Button("แก้ไข") { onEdit(lottery) }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button("ลบ") { onDelete(lottery) }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
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
                    Color(red: 34/255, green: 139/255, blue: 34/255),
                    Color(red: 50/255, green: 205/255, blue: 50/255),
                    Color(red: 144/255, green: 238/255, blue: 144/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lottery.status.hasPrefix("ไม่ถูกรางวัล") {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 105/255, green: 105/255, blue: 105/255),
                    Color(red: 169/255, green: 169/255, blue: 169/255),
                    Color(red: 211/255, green: 211/255, blue: 211/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 72/255, green: 61/255, blue: 139/255),
                    Color(red: 123/255, green: 104/255, blue: 238/255),
                    Color(red: 147/255, green: 112/255, blue: 219/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}