import SwiftUI

struct LaunchView: View {
    @Binding var isPresented: Bool
    
    @State private var circleScale: CGFloat = 0.9
    @State private var circleOpacity: Double = 0.35
    @State private var contentOpacity: Double = 1.0
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("dashboard.language") private var languageRawValue = AppLanguage.system.rawValue
    
    private var isDark: Bool {
        colorScheme == .dark
    }
    
    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    private var copy: Copybook {
        Copybook(language: selectedLanguage.resolvedLanguage)
    }
    
    var body: some View {
        ZStack {
            // Background matched to UILaunchScreen color
            Color("LaunchBackground")
                .ignoresSafeArea()
            
            // Animated background elements (similar to AtmosphereBackground)
            ZStack {
                Circle()
                    .fill(Color(red: 0.99, green: 0.65, blue: 0.27).opacity(0.18))
                    .frame(width: 220, height: 220)
                    .offset(x: 160, y: -250)
                    .scaleEffect(circleScale)
                    .opacity(circleOpacity)

                Circle()
                    .fill(Color(red: 0.21, green: 0.71, blue: 0.88).opacity(0.14))
                    .frame(width: 260, height: 260)
                    .offset(x: -170, y: 260)
                    .scaleEffect(circleScale)
                    .opacity(circleOpacity)
            }
            
            // Content
            VStack(spacing: 8) {
                // Reuse the same logo as the static native launch screen
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                .padding(.bottom, 16)
                
                Text(copy.shortTitle)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15))
                
                Text(copy.dashboardTitle)
                    .font(.system(.headline, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            // 1. Initial fade-in of elements
            withAnimation(.easeOut(duration: 0.8)) {
                circleScale = 1.0
                circleOpacity = 1.0
            }
            
            // 2. Pulse effect on the circles
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.8)) {
                circleScale = 1.15
            }
            
            // 3. Dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    LaunchView(isPresented: .constant(true))
}
