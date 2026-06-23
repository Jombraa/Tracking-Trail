import SwiftUI

// A lightweight confetti burst that spreads 60 coloured pieces from the
// screen centre, then fades them out over ~1.4 seconds.
// All random values are computed once in onAppear and stored in @State
// so they don't change on subsequent renders.

struct ConfettiView: View {

    struct Piece: Identifiable {
        let id: Int
        let color: Color
        let targetX: CGFloat
        let targetY: CGFloat
        let targetRotation: Double
        let width: CGFloat
        let height: CGFloat
    }

    @State private var pieces: [Piece] = []
    @State private var spread = false
    @State private var faded = false

    private let palette: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint
    ]

    var body: some View {
        ZStack {
            ForEach(pieces) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.width, height: p.height)
                    .rotationEffect(.degrees(spread ? p.targetRotation : 0))
                    .offset(
                        x: spread ? p.targetX : 0,
                        y: spread ? p.targetY : 0
                    )
                    .opacity(faded ? 0 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            buildPieces()
            // Burst outward
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                spread = true
            }
            // Fade after a brief pause
            withAnimation(.easeIn(duration: 0.45).delay(0.95)) {
                faded = true
            }
        }
    }

    private func buildPieces() {
        pieces = (0..<60).map { i in
            // Spread evenly around a circle with a small random jitter.
            let baseAngle = Double(i) / 60.0 * 2 * .pi
            let jitter    = Double.random(in: -0.18...0.18)
            let angle     = baseAngle + jitter
            let radius    = CGFloat.random(in: 90...270)

            return Piece(
                id: i,
                color: palette[i % palette.count],
                targetX: CGFloat(cos(angle)) * radius,
                targetY: CGFloat(sin(angle)) * radius - 30,  // bias upward
                targetRotation: Double.random(in: -480...480),
                width:  CGFloat.random(in: 6...10),
                height: CGFloat.random(in: 10...16)
            )
        }
    }
}
