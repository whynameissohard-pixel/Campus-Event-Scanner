import SwiftUI

struct EventListView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedCategory: String = "ทั้งหมด"
    @State private var searchText: String = ""
    @State private var showCreateEvent = false

    var filteredEvents: [Event] {
        let base = selectedCategory == "ทั้งหมด"
            ? eventVM.events
            : eventVM.events.filter { $0.category == selectedCategory }
        if searchText.isEmpty { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Orange Header
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("สวัสดี, \(authVM.userName.isEmpty ? "นักศึกษา" : authVM.userName) 👋")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                            Text("กิจกรรมทั้งหมด")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                            Image(systemName: "bell.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        }
                    }

                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appTextSecondary)
                        TextField("ค้นหากิจกรรม...", text: $searchText)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .background(LinearGradient.heroGradient)

                // MARK: - Category Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(EventCategory.all, id: \.name) { cat in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = cat.name
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 12))
                                    Text(cat.name)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(
                                    selectedCategory == cat.name
                                    ? cat.color
                                    : Color.white
                                )
                                .foregroundColor(
                                    selectedCategory == cat.name ? .white : .appTextSecondary
                                )
                                .cornerRadius(20)
                                .shadow(color: selectedCategory == cat.name
                                        ? cat.color.opacity(0.4) : Color.clear,
                                        radius: 5, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                // MARK: - Event Cards
                if eventVM.isLoading {
                    Spacer()
                    ProgressView("กำลังโหลด...")
                        .foregroundColor(.appTextSecondary)
                    Spacer()
                } else if filteredEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 52))
                            .foregroundColor(.appOrange.opacity(0.4))
                        Text("ไม่มีกิจกรรมในหมวดหมู่นี้")
                            .font(.headline)
                            .foregroundColor(.appTextSecondary)
                        Text("ลองเลือกหมวดหมู่อื่นดูนะ")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { showCreateEvent = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus").font(.system(size: 18, weight: .bold))
                            Text("เสนอกิจกรรม").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(LinearGradient.orangeGradient)
                        .cornerRadius(30)
                        .shadow(color: Color.appOrange.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20).padding(.bottom, 24)
                }
            }
        )
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateEvent) {
            UserCreateEventView()
                .environmentObject(eventVM)
                .environmentObject(authVM)
        }
    }
}

// MARK: - Event Card Component
struct EventCard: View {
    let event: Event
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category color accent bar
            HStack(spacing: 0) {
                Rectangle()
                    .fill(EventCategory.color(for: event.category))
                    .frame(width: 5)
                    .cornerRadius(3)

                VStack(alignment: .leading, spacing: 10) {
                    // Top row: category badge + seats
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: EventCategory.icon(for: event.category))
                                .font(.caption)
                                .foregroundColor(EventCategory.color(for: event.category))
                            Text(event.category)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(EventCategory.color(for: event.category))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(EventCategory.color(for: event.category).opacity(0.12))
                        .cornerRadius(8)

                        Spacer()

                        // Seats badge
                        HStack(spacing: 4) {
                            Image(systemName: event.isFull ? "person.fill.xmark" : "person.fill.checkmark")
                                .font(.caption2)
                            Text(event.isFull ? "เต็มแล้ว" : "\(event.spotsRemaining) ที่นั่ง")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(event.isFull ? .appDanger : .appSuccess)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background((event.isFull ? Color.appDanger : Color.appSuccess).opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Title
                    Text(event.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(2)

                    // Date & Time
                    HStack(spacing: 16) {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.appOrange)
                            Text(formatDate(event.startDate))
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.appOrange)
                            Text(formatTime(event.startDate))
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    }

                    // Location
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.appOrange)
                        Text(event.location)
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(16)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appear = true
            }
        }
    }
}
