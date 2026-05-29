import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var splashVisible = true

    var body: some View {
        Group {
            if splashVisible {
                SplashView()
                    .onAppear {
                        // Give Firebase Auth listener ~0.8s to resolve
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                splashVisible = false
                            }
                        }
                    }
            } else if !authVM.isLoggedIn {
                LoginView()
            } else {
                if authVM.isAdmin {
                    AdminTabView()
                        .environmentObject(authVM)
                } else {
                    StudentTabView()
                        .environmentObject(authVM)
                }
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appOrange, Color.appOrangeDark, Color(hex: "#991F00")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.15)).frame(width: 110, height: 110)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                }
                Text("SUT Events")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("ระบบจัดการกิจกรรมมหาวิทยาลัย")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1; opacity = 1
                }
            }
        }
    }
}
