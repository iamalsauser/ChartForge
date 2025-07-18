import SwiftUI

struct SkeletonLoaderView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.25))
                .frame(width: 48, height: 48)
                .shimmering(active: isAnimating)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 120, height: 16)
                    .shimmering(active: isAnimating)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 80, height: 12)
                    .shimmering(active: isAnimating)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(radius: 1))
        .listRowBackground(Color(.systemGroupedBackground))
        .accessibilityLabel("Loading asset data")
        .onAppear { isAnimating = true }
    }
}

// Shimmer effect modifier
extension View {
    func shimmering(active: Bool) -> some View {
        self.modifier(ShimmerModifier(isActive: active))
    }
}

struct ShimmerModifier: ViewModifier {
    var isActive: Bool
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.6), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(20))
                        .offset(x: isActive ? phase * geometry.size.width : -geometry.size.width)
                        .animation(isActive ? Animation.linear(duration: 1.2).repeatForever(autoreverses: false) : .default, value: phase)
                }
                .clipped()
            )
            .onAppear {
                if isActive {
                    phase = 1.5
                }
            }
    }
}

struct SkeletonLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        SkeletonLoaderView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
