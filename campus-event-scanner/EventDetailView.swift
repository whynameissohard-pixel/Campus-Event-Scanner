import SwiftUI
import FirebaseFirestore

struct EventDetailView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel

    var event: Event

    @State private var currentAttendees: [String] = []
    @State private var currentAttended: [String] = []
    @State private var currentLimit: Int = 0
    @State private var listener: ListenerRegistration? = nil
    @State private var isRegistering = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var heroAppear = false

    var isRegistered: Bool {
        currentAttendees.contains(authVM.studentID)
    }
    var hasCheckedIn: Bool {
        currentAttended.contains(authVM.studentID)
    }
    var isFull: Bool { currentAttendees.count >= currentLimit && !isRegistered }
    var spotsRemaining: Int { max(0, currentLimit - currentAttendees.count) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - Hero Header
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient.heroGradient
                            .frame(height: 220)

                        // Decorative
                        Circle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 180)
                            .offset(x: 200, y: -60)
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 120)
                            .offset(x: -30, y: -100)

                        VStack(alignment: .leading, spacing: 10) {
                            // Category badge
                            HStack(spacing: 6) {
                                Image(systemName: EventCategory.icon(for: event.category))
                                    .font(.caption)
                                Text(event.category)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)

                            Text(event.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(3)
                        }
                        .padding(24)
                        .scaleEffect(heroAppear ? 1 : 0.95)
                        .opacity(heroAppear ? 1 : 0)
                    }

                    // MARK: - Info Cards
                    VStack(spacing: 14) {
                        // Date & Time card
                        HStack(spacing: 16) {
                            infoBox(icon: "calendar", color: .appOrange,
                                    title: "วันเริ่มต้น",
                                    value: formatDate(event.startDate))
                            infoBox(icon: "calendar.badge.checkmark", color: Color(hex: "#A855F7"),
                                    title: "วันสิ้นสุด",
                                    value: formatDate(event.endDate))
                        }

                        HStack(spacing: 16) {
                            infoBox(icon: "clock.fill", color: Color(hex: "#3B82F6"),
                                    title: "เวลา",
                                    value: "\(formatTime(event.startDate)) - \(formatTime(event.endDate))")
                            infoBox(icon: "mappin.circle.fill", color: Color(hex: "#EF4444"),
                                    title: "สถานที่",
                                    value: event.location)
                        }

                        // Attendee progress card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.appOrange)
                                Text("จำนวนผู้เข้าร่วม")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                Text("\(currentAttendees.count)/\(currentLimit)")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(isFull ? .appDanger : .appSuccess)
                            }

                            // Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.12))
                                        .frame(height: 10)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            isFull
                                            ? LinearGradient(colors: [.appDanger, .appDanger.opacity(0.7)],
                                                             startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(colors: [.appOrange, .appOrangeLight],
                                                             startPoint: .leading, endPoint: .trailing)
                                        )
                                        .frame(width: currentLimit > 0
                                               ? geo.size.width * CGFloat(currentAttendees.count) / CGFloat(currentLimit)
                                               : 0,
                                               height: 10)
                                }
                            }
                            .frame(height: 10)

                            Text(isFull ? "ที่นั่งเต็มแล้ว" : "เหลือที่นั่ง \(spotsRemaining) จาก \(currentLimit) ที่")
                                .font(.caption)
                                .foregroundColor(isFull ? .appDanger : .appTextSecondary)
                        }
                        .padding(16)
                        .cardStyle()

                        // Description
                        if !event.description.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.appOrange)
                                    Text("รายละเอียด")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.appTextPrimary)
                                }
                                Text(event.description)
                                    .font(.body)
                                    .foregroundColor(.appTextSecondary)
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .cardStyle()
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }

            // MARK: - Bottom Action Button
            VStack {
                Divider()
                Group {
                    if authVM.studentID.isEmpty {
                        Text("กรุณาลงทะเบียนบัญชีด้วย StudentID เพื่อลงทะเบียนกิจกรรม")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else if hasCheckedIn {
                        // ✅ Already checked-in — show badge, hide cancel
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.appSuccess.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.appSuccess)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("เข้าร่วมแล้ว")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.appSuccess)
                                Text("Admin ยืนยันการเข้าร่วมกิจกรรมแล้ว")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.appSuccess.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.appSuccess.opacity(0.3), lineWidth: 1))
                        )
                        .padding(.horizontal, 20)
                    } else if isRegistered {
                        Button {
                            cancelRegistration()
                        } label: {
                            HStack(spacing: 10) {
                                if isRegistering { ProgressView().tint(.white) }
                                Image(systemName: "xmark.circle.fill")
                                Text(isRegistering ? "กำลังยกเลิก..." : "ยกเลิกการจอง")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appDanger)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.appDanger.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isRegistering)
                    } else {
                        Button {
                            registerForEvent()
                        } label: {
                            HStack(spacing: 10) {
                                if isRegistering { ProgressView().tint(.white) }
                                Image(systemName: "checkmark.circle.fill")
                                Text(isRegistering ? "กำลังลงทะเบียน..." :
                                     isFull ? "ที่นั่งเต็มแล้ว" : "ลงทะเบียนเข้าร่วม")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isFull
                                ? LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient.orangeGradient)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: isFull ? .clear : Color.appOrange.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isFull || isRegistering)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
            }
        }
        .navigationTitle("รายละเอียดกิจกรรม")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("ตกลง", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            setupLiveListener()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                heroAppear = true
            }
        }
        .onDisappear {
            listener?.remove()
        }
    }

    // MARK: - Info Box Helper
    @ViewBuilder
    func infoBox(icon: String, color: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardStyle()
    }

    // MARK: - Real-time Listener
    func setupLiveListener() {
        currentAttendees = event.attendees
        currentAttended  = event.attended
        currentLimit = event.limit

        let db = Firestore.firestore()
        listener = db.collection("events").document(event.id)
            .addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                DispatchQueue.main.async {
                    self.currentAttendees = data["attendees"] as? [String] ?? []
                    self.currentAttended  = data["attended"]  as? [String] ?? []
                    self.currentLimit = data["limit"] as? Int ?? self.event.limit
                }
            }
    }

    // MARK: - Actions
    func registerForEvent() {
        isRegistering = true
        eventVM.registerForEvent(eventID: event.id, studentID: authVM.studentID) { result in
            isRegistering = false
            switch result {
            case .success:
                alertTitle = "✅ ลงทะเบียนสำเร็จ"
                alertMessage = "คุณได้ลงทะเบียนกิจกรรม \"\(event.title)\" เรียบร้อยแล้ว"
            case .failure(let err):
                alertTitle = "❌ ไม่สามารถลงทะเบียนได้"
                alertMessage = err.localizedDescription ?? "เกิดข้อผิดพลาด"
            }
            showAlert = true
        }
    }

    func cancelRegistration() {
        isRegistering = true
        eventVM.cancelRegistration(eventID: event.id, studentID: authVM.studentID) { success in
            isRegistering = false
            alertTitle = success ? "✅ ยกเลิกสำเร็จ" : "❌ เกิดข้อผิดพลาด"
            alertMessage = success ? "ยกเลิกการจองเรียบร้อยแล้ว" : "ไม่สามารถยกเลิกได้ กรุณาลองใหม่"
            showAlert = true
        }
    }
}
