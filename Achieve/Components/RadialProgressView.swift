import SwiftUI

struct RadialProgressView: View {
    var percentage: Double
    var accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

            Circle()
                .trim(from: 0, to: max(0, min(percentage, 1)))
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.25), value: percentage)

            Text("\(Int((percentage * 100).rounded()))%")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
        }
        .frame(width: 160, height: 160)
    }
}

#Preview {
    RadialProgressView(percentage: 0.73, accent: Color(hex: "#3F2A6B"))
}
