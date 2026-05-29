import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showPassword = false
    @State private var emailFocused = false
    @State private var passwordFocused = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var formOffset: CGFloat = 40
    @State private var formOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.appOrange, Color.appOrangeDark, Color(hex: "#991F00")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 300, height: 300)
                .offset(x: -120, y: -260)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 200, height: 200)
                .offset(x: 140, y: -200)
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: 130, y: 320)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - Logo Section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Text("SUT Events")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("ระบบจัดการกิจกรรมมหาวิทยาลัย")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .padding(.top, 70)
                    .padding(.bottom, 40)

                    // MARK: - Glass Card
                    VStack(spacing: 24) {
                        // Title
                        VStack(spacing: 6) {
                            Text("ยินดีต้อนรับ")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.appTextPrimary)
                            Text("เข้าสู่ระบบเพื่อดูกิจกรรม")
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                        }

                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Label("อีเมล", systemImage: "envelope.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.appTextSecondary)
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(emailFocused ? .appOrange : .appTextSecondary)
                                    .frame(width: 20)
                                TextField("กรอกอีเมลของคุณ", text: $email,
                                          onEditingChanged: { emailFocused = $0 })
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .inputFieldStyle(isFocused: emailFocused)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Label("รหัสผ่าน", systemImage: "lock.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.appTextSecondary)
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(passwordFocused ? .appOrange : .appTextSecondary)
                                    .frame(width: 20)
                                Group {
                                    if showPassword {
                                        TextField("รหัสผ่าน", text: $password)
                                    } else {
                                        SecureField("รหัสผ่าน", text: $password)
                                    }
                                }
                                .textInputAutocapitalization(.never)
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                            .inputFieldStyle(isFocused: passwordFocused)
                        }

                        // Error Banner
                        if let error = authVM.errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.appDanger)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.appDanger)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.appDanger.opacity(0.08))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appDanger.opacity(0.2), lineWidth: 1))
                        }

                        // Login Button
                        Button {
                            authVM.login(email: email, password: password)
                        } label: {
                            HStack(spacing: 10) {
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                }
                                Text(authVM.isLoading ? "กำลังเข้าสู่ระบบ..." : "เข้าสู่ระบบ")
                                    .fontWeight(.semibold)
                            }
                            .orangeButtonStyle(isLoading: authVM.isLoading)
                        }
                        .disabled(authVM.isLoading)
                        .scaleEffect(authVM.isLoading ? 0.97 : 1)
                        .animation(.spring(response: 0.3), value: authVM.isLoading)

                        // Divider
                        HStack {
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                            Text("หรือ").font(.caption).foregroundColor(.appTextSecondary).padding(.horizontal, 8)
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                        }

                        // Register Button
                        Button {
                            authVM.errorMessage = nil
                            showRegister = true
                        } label: {
                            HStack {
                                Text("ยังไม่มีบัญชี?")
                                    .foregroundColor(.appTextSecondary)
                                Text("สมัครสมาชิก")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appOrange)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    .offset(y: formOffset)
                    .opacity(formOpacity)

                    Spacer(minLength: 60)
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView().environmentObject(authVM)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                formOffset = 0
                formOpacity = 1.0
            }
        }
    }
}
