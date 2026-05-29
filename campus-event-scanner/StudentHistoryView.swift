import SwiftUI

struct StudentHistoryView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    HStack {
                        Text("ประวัติกิจกรรม")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        ZStack {
                            Capsule().fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 32)
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.caption2)
                                Text("\(eventVM.myEvents.count) รายการ")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(LinearGradient.heroGradient)

                if eventVM.myEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 56))
                            .foregroundColor(.appOrange.opacity(0.35))
                        Text("ยังไม่มีกิจกรรมที่เข้าร่วม")
                            .font(.headline)
                            .foregroundColor(.appTextSecondary)
                        Text("ไปดูกิจกรรมที่น่าสนใจในแท็บ กิจกรรม")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(eventVM.myEvents) { event in
                                HistoryCard(
                                    event: event,
                                    studentID: authVM.studentID
                                ) {
                                    cancelRegistration(event: event)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("ตกลง", role: .cancel) {}
        }
        .onAppear {
            if !authVM.studentID.isEmpty {
                eventVM.fetchMyEvents(studentID: authVM.studentID)
            }
        }
    }

    func cancelRegistration(event: Event) {
        eventVM.cancelRegistration(eventID: event.id, studentID: authVM.studentID) { success in
            alertMessage = success ? "✅ ยกเลิกการลงทะเบียนเรียบร้อยแล้ว" : "⚠️ ไม่สามารถยกเลิกได้"
            showAlert = true
        }
    }
}

// MARK: - History Card
struct HistoryCard: View {
    let event: Event
    let studentID: String
    let onCancel: () -> Void
    @State private var showCancelConfirm = false

    var hasCheckedIn: Bool { event.attended.contains(studentID) }

    var statusLabel: (text: String, color: Color, icon: String) {
        switch event.status {
        case "approved": return ("อนุมัติแล้ว", .appSuccess, "checkmark.seal.fill")
        case "rejected": return ("ถูกปฏิเสธ", .appDanger, "xmark.seal.fill")
        default:         return ("รออนุมัติ", .appWarning, "clock.badge.questionmark")
        }
    }

    var isPast: Bool { event.endDate < Date() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top: Title + Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(2)
                    HStack(spacing: 5) {
                        Image(systemName: EventCategory.icon(for: event.category))
                            .font(.caption2)
                        Text(event.category)
                            .font(.caption)
                    }
                    .foregroundColor(EventCategory.color(for: event.category))
                }
                Spacer()
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: statusLabel.icon).font(.caption2)
                    Text(statusLabel.text).font(.caption.weight(.semibold))
                }
                .foregroundColor(statusLabel.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusLabel.color.opacity(0.1))
                .cornerRadius(8)
            }

            Divider().opacity(0.5)

            // Date, Time, Location
            HStack(spacing: 20) {
                Label(formatDate(event.startDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                Label(formatTime(event.startDate), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            Label(event.location, systemImage: "mappin.circle.fill")
                .font(.caption)
                .foregroundColor(.appTextSecondary)

            // Past tag or Cancel button
            if hasCheckedIn {
                // Admin already checked in — hide cancel, show badge
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                    Text("เข้าร่วมแล้ว")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.appSuccess)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.appSuccess.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else if isPast {
                HStack {
                    Spacer()
                    Label("กิจกรรมสิ้นสุดแล้ว", systemImage: "checkmark.circle")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.appTextSecondary)
                }
            } else {
                Button {
                    showCancelConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("ยกเลิกการลงทะเบียน")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.appDanger)
                    .background(Color.appDanger.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.appDanger.opacity(0.2), lineWidth: 1))
                }
                .confirmationDialog("ยืนยันการยกเลิก", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                    Button("ยกเลิกการลงทะเบียน", role: .destructive) { onCancel() }
                    Button("ไม่ยกเลิก", role: .cancel) {}
                } message: {
                    Text("คุณต้องการยกเลิกการลงทะเบียนกิจกรรม \"\(event.title)\" หรือไม่?")
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}
