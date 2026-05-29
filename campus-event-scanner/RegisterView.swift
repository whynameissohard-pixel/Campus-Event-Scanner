import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var studentID = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    // Validation states
    @State private var studentIDState: FieldState = .idle
    @State private var studentIDMessage = ""
    @State private var checkTask: Task<Void, Never>? = nil
    @State private var formOpacity: Double = 0
    @State private var formOffset: CGFloat = 30

    enum FieldState { case idle, checking, valid, invalid }

    var passwordsMatch: Bool { password == confirmPassword && !password.isEmpty }

    var canSubmit: Bool {
        !name.isEmpty && !email.isEmpty &&
        password.count >= 6 && passwordsMatch &&
        studentIDState == .valid && !authVM.isLoading
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.orangeGradient)
                                    .frame(width: 70, height: 70)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            Text("สมัครสมาชิก")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.appTextPrimary)
                            Text("กรอกข้อมูลเพื่อสร้างบัญชีใหม่")
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(.top, 20)

                        // Form Card
                        VStack(spacing: 18) {
                            // Name
                            fieldRow(icon: "person.fill", label: "ชื่อ-นามสกุล",
                                     placeholder: "กรอกชื่อของคุณ", text: $name)

                            // StudentID with async check
                            VStack(alignment: .leading, spacing: 6) {
                                Text("รหัสนักศึกษา")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.appTextSecondary)
                                HStack(spacing: 12) {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(.appTextSecondary)
                                        .frame(width: 20)
                                    TextField("เช่น B6700001", text: $studentID)
                                        .textInputAutocapitalization(.characters)
                                        .autocorrectionDisabled()
                                        .onChange(of: studentID) { _ in
                                            debounceStudentIDCheck()
                                        }
                                    // Status icon
                                    Group {
                                        switch studentIDState {
                                        case .idle:     EmptyView()
                                        case .checking: ProgressView().scaleEffect(0.8)
                                        case .valid:
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.appSuccess)
                                        case .invalid:
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.appDanger)
                                        }
                                    }
                                    .frame(width: 22)
                                }
                                .inputFieldStyle(isFocused: studentIDState == .checking)

                                if !studentIDMessage.isEmpty {
                                    Text(studentIDMessage)
                                        .font(.caption)
                                        .foregroundColor(studentIDState == .valid ? .appSuccess : .appDanger)
                                }
                            }

                            // Email
                            fieldRow(icon: "envelope.fill", label: "อีเมล",
                                     placeholder: "กรอกอีเมลของคุณ", text: $email,
                                     keyboardType: .emailAddress)

                            // Password
                            VStack(alignment: .leading, spacing: 6) {
                                Text("รหัสผ่าน (อย่างน้อย 6 ตัว)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.appTextSecondary)
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.appTextSecondary)
                                        .frame(width: 20)
                                    Group {
                                        if showPassword { TextField("รหัสผ่าน", text: $password) }
                                        else { SecureField("รหัสผ่าน", text: $password) }
                                    }
                                    .textInputAutocapitalization(.never)
                                    Button { showPassword.toggle() } label: {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.appTextSecondary)
                                    }
                                }
                                .inputFieldStyle()
                            }

                            // Confirm Password
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ยืนยันรหัสผ่าน")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.appTextSecondary)
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(.appTextSecondary)
                                        .frame(width: 20)
                                    Group {
                                        if showConfirmPassword { TextField("ยืนยันรหัสผ่าน", text: $confirmPassword) }
                                        else { SecureField("ยืนยันรหัสผ่าน", text: $confirmPassword) }
                                    }
                                    .textInputAutocapitalization(.never)
                                    if !confirmPassword.isEmpty {
                                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(passwordsMatch ? .appSuccess : .appDanger)
                                    }
                                    Button { showConfirmPassword.toggle() } label: {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.appTextSecondary)
                                    }
                                }
                                .inputFieldStyle(isFocused: !confirmPassword.isEmpty && !passwordsMatch)
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

                            // Submit Button
                            Button {
                                submitRegistration()
                            } label: {
                                HStack(spacing: 10) {
                                    if authVM.isLoading { ProgressView().tint(.white) }
                                    Text(authVM.isLoading ? "กำลังสมัครสมาชิก..." : "สมัครสมาชิก")
                                        .fontWeight(.semibold)
                                }
                                .orangeButtonStyle(isLoading: authVM.isLoading)
                            }
                            .disabled(!canSubmit)
                            .opacity(canSubmit ? 1 : 0.5)

                            // Already have account
                            Button {
                                dismiss()
                            } label: {
                                HStack {
                                    Text("มีบัญชีอยู่แล้ว?")
                                        .foregroundColor(.appTextSecondary)
                                    Text("เข้าสู่ระบบ")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appOrange)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            authVM.errorMessage = nil
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                formOpacity = 1; formOffset = 0
            }
        }
    }

    // MARK: - Field Row Helper
    @ViewBuilder
    func fieldRow(icon: String, label: String, placeholder: String,
                  text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.appTextSecondary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.appTextSecondary)
                    .frame(width: 20)
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
            }
            .inputFieldStyle()
        }
    }

    // MARK: - Submit
    func submitRegistration() {
        guard passwordsMatch else {
            authVM.errorMessage = "รหัสผ่านไม่ตรงกัน"
            return
        }
        authVM.register(email: email, password: password,
                        studentID: studentID, name: name) { success in
            if success { dismiss() }
        }
    }

    // MARK: - Debounced StudentID Check
    func debounceStudentIDCheck() {
        checkTask?.cancel()
        studentIDState = .idle
        studentIDMessage = ""
        guard studentID.count >= 4 else { return }
        studentIDState = .checking
        checkTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s debounce
            guard !Task.isCancelled else { return }
            authVM.checkStudentIDExists(studentID: studentID) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let exists):
                        if exists {
                            studentIDState = .invalid
                            studentIDMessage = "รหัสนักศึกษานี้ถูกใช้งานแล้ว"
                        } else {
                            studentIDState = .valid
                            studentIDMessage = "รหัสนักศึกษาพร้อมใช้งาน"
                        }
                    case .failure:
                        // Query ล้มเหลว (เช่น ยังไม่ได้อัปเดต rules) → แจ้งให้ลองใหม่
                        studentIDState = .invalid
                        studentIDMessage = "ไม่สามารถตรวจสอบได้ กรุณาลองใหม่"
                    }
                }
            }
        }
    }
}
