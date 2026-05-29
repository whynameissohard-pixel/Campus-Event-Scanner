import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var eventVM: EventViewModel

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Admin Dashboard")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Text("ภาพรวมระบบกิจกรรม")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(Color.white.opacity(0.2)).frame(width: 46, height: 46)
                                Image(systemName: "shield.lefthalf.filled")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    }
                    .background(LinearGradient.heroGradient)

                    // Stat Cards Row 1
                    HStack(spacing: 14) {
                        adminStatCard(
                            value: "\(eventVM.events.count)",
                            label: "กิจกรรมที่อนุมัติ",
                            icon: "calendar.badge.checkmark",
                            color: .appSuccess
                        )
                        adminStatCard(
                            value: "\(eventVM.pendingEvents.count)",
                            label: "รออนุมัติ",
                            icon: "clock.badge.questionmark",
                            color: .appWarning
                        )
                    }
                    .padding(.horizontal, 20)

                    // Stat Cards Row 2
                    HStack(spacing: 14) {
                        adminStatCard(
                            value: "\(eventVM.totalAttendees)",
                            label: "ผู้เข้าร่วมทั้งหมด",
                            icon: "person.3.fill",
                            color: .appOrange
                        )
                        adminStatCard(
                            value: "\(eventVM.events.count + eventVM.pendingEvents.count)",
                            label: "กิจกรรมทั้งหมด",
                            icon: "square.stack.fill",
                            color: Color(hex: "#3B82F6")
                        )
                    }
                    .padding(.horizontal, 20)

                    // Recent Approved Events
                    if !eventVM.events.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("กิจกรรมล่าสุด")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                Text("ทั้งหมด \(eventVM.events.count)")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }

                            ForEach(eventVM.events.prefix(5)) { event in
                                NavigationLink(destination:
                                    AdminEventDetailView(event: event)
                                        .environmentObject(eventVM)
                                ) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(EventCategory.color(for: event.category).opacity(0.12))
                                                .frame(width: 42, height: 42)
                                            Image(systemName: EventCategory.icon(for: event.category))
                                                .foregroundColor(EventCategory.color(for: event.category))
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(event.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.appTextPrimary)
                                                .lineLimit(1)
                                            Text("\(formatDate(event.startDate)) • \(event.location)")
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(event.attendeeCount)")
                                                .font(.headline.weight(.bold))
                                                .foregroundColor(.appOrange)
                                            Text("คน")
                                                .font(.caption2)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Pending Events Preview
                    if !eventVM.pendingEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundColor(.appWarning)
                                Text("รออนุมัติ (\(eventVM.pendingEvents.count))")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.appTextPrimary)
                            }

                            ForEach(eventVM.pendingEvents.prefix(3)) { event in
                                NavigationLink(destination:
                                    AdminEventDetailView(event: event)
                                        .environmentObject(eventVM)
                                ) {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.appWarning.opacity(0.15))
                                            .frame(width: 8, height: 8)
                                        Text(event.title)
                                            .font(.subheadline)
                                            .foregroundColor(.appTextPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(formatDate(event.startDate))
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.appWarning.opacity(0.06))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear { eventVM.fetchEvents() }
    }

    @ViewBuilder
    func adminStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 50, height: 50)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 22))
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
