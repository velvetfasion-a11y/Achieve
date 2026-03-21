import SwiftUI

struct RadialProgressView: View {
    let percentage: Double
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.15), lineWidth: 14)

            Circle()
                .trim(from: 0, to: max(0, min(percentage, 1)))
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: percentage)

            Text("\(Int((percentage * 100).rounded()))%")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
        }
        .frame(width: 180, height: 180)
    }
}

#Preview {
    RadialProgressView(percentage: 0.72, accent: .indigo)
}
