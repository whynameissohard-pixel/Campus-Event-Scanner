import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var isSaving = false
    @State private var successMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Avatar preview
                    ZStack {
                        Circle()
                            .fill(LinearGradient.orangeGradient)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.appOrange.opacity(0.4), radius: 10, x: 0, y: 4)
                        Text(String(name.prefix(1)).uppercased().isEmpty ? "S" :
                             String(name.prefix(1)).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    // Form card
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ชื่อ-นามสกุล")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.appTextSecondary)
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.appOrange)
                                    .frame(width: 20)
                                TextField("กรอกชื่อ-นามสกุล", text: $name)
                                    .autocorrectionDisabled()
                            }
                            .inputFieldStyle()
                        }

                        // Read-only fields
                        readOnlyField(label: "รหัสนักศึกษา", value: authVM.studentID,
                                      icon: "creditcard.fill")
                        readOnlyField(label: "อีเมล", value: authVM.userEmail,
                                      icon: "envelope.fill")

                        // Save Button
                        Button {
                            saveProfile()
                        } label: {
                            HStack(spacing: 10) {
                                if isSaving { ProgressView().tint(.white) }
                                Text(isSaving ? "กำลังบันทึก..." : "บันทึกข้อมูล")
                                    .fontWeight(.semibold)
                            }
                            .orangeButtonStyle(isLoading: isSaving)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("แก้ไขโปรไฟล์")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") { dismiss() }
                        .foregroundColor(.appOrange)
                }
            }
            .alert("✅ บันทึกสำเร็จ", isPresented: $showSuccess) {
                Button("ตกลง") { dismiss() }
            } message: {
                Text("อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว")
            }
        }
        .onAppear { name = authVM.userName }
    }

    @ViewBuilder
    func readOnlyField(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.appTextSecondary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.gray.opacity(0.5))
                    .frame(width: 20)
                Text(value.isEmpty ? "-" : value)
                    .foregroundColor(.gray)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.4))
            }
            .inputFieldStyle()
        }
    }

    func saveProfile() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        authVM.updateName(trimmed) { success in
            isSaving = false
            if success { showSuccess = true }
        }
    }
}
