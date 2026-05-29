import SwiftUI

struct MyQRCodeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var qrImage: UIImage? = nil
    @State private var showShareSheet = false
    @State private var cardAppear = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("My QR Code")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("แสดง QR นี้เพื่อยืนยันตัวตน")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(LinearGradient.heroGradient)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // QR Card
                        VStack(spacing: 20) {
                            VStack(spacing: 6) {
                                Text(authVM.userName.isEmpty ? "นักศึกษา" : authVM.userName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.appTextPrimary)
                                Text(authVM.studentID.isEmpty ? "ไม่พบรหัสนักศึกษา" : authVM.studentID)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.appOrange)
                            }

                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .frame(width: 230, height: 230)
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)

                                if let qrImage = qrImage {
                                    Image(uiImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 190, height: 190)
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "qrcode")
                                            .font(.system(size: 48))
                                            .foregroundColor(.gray.opacity(0.3))
                                        Text("ไม่มีรหัสนักศึกษา")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .scaleEffect(cardAppear ? 1 : 0.85)
                            .opacity(cardAppear ? 1 : 0)

                            HStack(spacing: 6) {
                                Image(systemName: "wave.3.forward.circle.fill")
                                    .foregroundColor(.appOrange)
                                Text("สแกนเพื่อยืนยันการเข้าร่วมกิจกรรม")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        .padding(28)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 30)

                        // Info rows
                        VStack(spacing: 0) {
                            infoRow(icon: "envelope.fill", label: "อีเมล", value: authVM.userEmail)
                            Divider().padding(.horizontal, 16)
                            infoRow(icon: "creditcard.fill", label: "รหัสนักศึกษา", value: authVM.studentID)
                            Divider().padding(.horizontal, 16)
                            infoRow(icon: "person.badge.shield.checkmark.fill", label: "สถานะ", value: "นักศึกษา")
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 20)

                        if qrImage != nil {
                            Button { showShareSheet = true } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("แชร์ QR Code").fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appOrange.opacity(0.1))
                                .foregroundColor(.appOrange)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.appOrange.opacity(0.3), lineWidth: 1))
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let img = qrImage { ShareSheet(items: [img]) }
        }
        .onAppear {
            generateQRCode()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                cardAppear = true
            }
        }
        .onChange(of: authVM.studentID) { _ in generateQRCode() }
    }

    @ViewBuilder
    func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.appOrange.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(.appOrange).font(.system(size: 15))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.appTextSecondary)
                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appTextPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    func generateQRCode() {
        guard !authVM.studentID.isEmpty else { qrImage = nil; return }
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(Data(authVM.studentID.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
            qrImage = UIImage(cgImage: cgImage)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
