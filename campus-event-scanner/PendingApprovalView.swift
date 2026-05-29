import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @State private var processingID: String? = nil

    var pendingEvents: [Event] { eventVM.pendingEvents }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("กิจกรรมรออนุมัติ")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(pendingEvents.count) รายการ")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                        Image(systemName: "clock.badge.questionmark")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(LinearGradient.heroGradient)

                if pendingEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.appSuccess.opacity(0.5))
                        Text("ไม่มีกิจกรรมรออนุมัติ")
                            .font(.headline)
                            .foregroundColor(.appTextSecondary)
                        Text("กิจกรรมทั้งหมดได้รับการพิจารณาแล้ว")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(pendingEvents) { event in
                                NavigationLink(destination:
                                    AdminEventDetailView(event: event)
                                        .environmentObject(eventVM)
                                ) {
                                    PendingEventCard(
                                        event: event,
                                        isProcessing: processingID == event.id
                                    ) {
                                        processingID = event.id
                                        eventVM.approveEvent(event.id)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            processingID = nil
                                        }
                                    } onReject: {
                                        processingID = event.id
                                        eventVM.rejectEvent(event.id)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            processingID = nil
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Pending Event Card
struct PendingEventCard: View {
    let event: Event
    let isProcessing: Bool
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: EventCategory.icon(for: event.category))
                            .font(.caption2)
                        Text(event.category)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(EventCategory.color(for: event.category))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(EventCategory.color(for: event.category).opacity(0.1))
                    .cornerRadius(8)

                    Text(event.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(2)
                }
                Spacer()
                // Pending badge
                Text("รออนุมัติ")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.appWarning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.appWarning.opacity(0.12))
                    .cornerRadius(8)
            }

            // Info grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoChip(icon: "calendar", text: formatDate(event.startDate))
                infoChip(icon: "clock", text: formatTime(event.startDate))
                infoChip(icon: "mappin.circle", text: event.location)
                infoChip(icon: "person.3", text: "\(event.limit) ที่นั่ง")
            }

            if !event.description.isEmpty {
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(2)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.appBackground)
                    .cornerRadius(8)
            }

            // Action Buttons
            HStack(spacing: 12) {
                // Reject
                Button { onReject() } label: {
                    HStack(spacing: 6) {
                        if isProcessing {
                            ProgressView().scaleEffect(0.8).tint(.appDanger)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                        }
                        Text("ปฏิเสธ").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.appDanger)
                    .background(Color.appDanger.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appDanger.opacity(0.25), lineWidth: 1))
                }
                .disabled(isProcessing)

                // Approve
                Button { onApprove() } label: {
                    HStack(spacing: 6) {
                        if isProcessing {
                            ProgressView().scaleEffect(0.8).tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("อนุมัติ").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(LinearGradient(colors: [.appSuccess, Color(hex: "#16A34A")],
                                               startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                    .shadow(color: Color.appSuccess.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .cardStyle()
    }

    @ViewBuilder
    func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.appOrange)
            Text(text)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appBackground)
        .cornerRadius(8)
    }
}
