import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @State private var showEditProfile = false
    @State private var showLogoutConfirm = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - Orange Header
                    ZStack(alignment: .bottom) {
                        LinearGradient.heroGradient.frame(height: 170)
                        // Decorative circles
                        Circle().fill(Color.white.opacity(0.07)).frame(width: 180).offset(x: 120, y: -80)
                        Circle().fill(Color.white.opacity(0.05)).frame(width: 120).offset(x: -100, y: -50)

                        // Avatar + Name
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 88, height: 88)
                                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                                Circle()
                                    .fill(LinearGradient.orangeGradient)
                                    .frame(width: 80, height: 80)
                                Text(String(authVM.userName.prefix(1)).uppercased().isEmpty ? "S" :
                                     String(authVM.userName.prefix(1)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(y: 44)
                        }
                        .padding(.bottom, 10)
                    }

                    // Name + StudentID (below avatar)
                    VStack(spacing: 4) {
                        Text(authVM.userName.isEmpty ? "นักศึกษา" : authVM.userName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                        Text(authVM.studentID.isEmpty ? "" : authVM.studentID)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.appOrange)
                        Text(authVM.userEmail)
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.top, 54)
                    .padding(.bottom, 20)

                    // Edit Profile Button
                    Button {
                        showEditProfile = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle.fill")
                            Text("แก้ไขโปรไฟล์")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.appOrange)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 28)
                        .background(Color.appOrange.opacity(0.1))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.appOrange.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.bottom, 24)

                    // Stats Row
                    HStack(spacing: 0) {
                        statBox(value: "\(eventVM.myEvents.count)", label: "กิจกรรมทั้งหมด", icon: "calendar.badge.checkmark")
                        Divider().frame(height: 50)
                        statBox(value: "\(eventVM.myEvents.filter { $0.endDate < Date() }.count)",
                                label: "ผ่านมาแล้ว", icon: "clock.badge.checkmark")
                        Divider().frame(height: 50)
                        statBox(value: "\(eventVM.myEvents.filter { $0.endDate >= Date() }.count)",
                                label: "ที่กำลังมา", icon: "clock.fill")
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    // MARK: - Interest Analytics
                    let attendedEvents = eventVM.myEvents.filter { $0.attended.contains(authVM.studentID) }
                    if !attendedEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            // Section header
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(.appOrange)
                                        .font(.subheadline)
                                    Text("วิเคราะห์ความสนใจ")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.appTextPrimary)
                                }
                                Spacer()
                                // Participation rate badge
                                let rate = eventVM.myEvents.count > 0
                                    ? Int(Double(attendedEvents.count) / Double(eventVM.myEvents.count) * 100)
                                    : 0
                                Text("เข้าร่วม \(rate)%")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(rate >= 70 ? .appSuccess : rate >= 40 ? .appWarning : .appDanger)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background((rate >= 70 ? Color.appSuccess : rate >= 40 ? Color.appWarning : Color.appDanger).opacity(0.12))
                                    .cornerRadius(8)
                            }

                            // Attended vs Registered mini-stat
                            HStack(spacing: 0) {
                                VStack(spacing: 4) {
                                    Text("\(attendedEvents.count)")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.appSuccess)
                                    Text("เข้าร่วมจริง")
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                Divider().frame(height: 40)
                                VStack(spacing: 4) {
                                    Text("\(eventVM.myEvents.count - attendedEvents.count)")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.appOrange)
                                    Text("ยังไม่ได้ไป")
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                Divider().frame(height: 40)
                                VStack(spacing: 4) {
                                    Text("\(eventVM.myEvents.count)")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.appTextPrimary)
                                    Text("ลงทะเบียนทั้งหมด")
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)

                            Divider()

                            // Category breakdown
                            let catCounts = Dictionary(grouping: attendedEvents, by: \.category)
                                .mapValues(\.count)
                                .sorted { $0.value > $1.value }
                            let maxCount = catCounts.first?.value ?? 1

                            if !catCounts.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("หมวดกิจกรรมที่เข้าร่วม")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.appTextSecondary)

                                    ForEach(catCounts.prefix(5), id: \.key) { cat, count in
                                        HStack(spacing: 10) {
                                            Image(systemName: EventCategory.icon(for: cat))
                                                .font(.caption)
                                                .foregroundColor(EventCategory.color(for: cat))
                                                .frame(width: 18)
                                            Text(cat)
                                                .font(.caption)
                                                .foregroundColor(.appTextPrimary)
                                                .frame(width: 80, alignment: .leading)
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.gray.opacity(0.1))
                                                        .frame(height: 8)
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(EventCategory.color(for: cat).opacity(0.8))
                                                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount),
                                                               height: 8)
                                                }
                                            }
                                            .frame(height: 8)
                                            Text("\(count)")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(.appTextSecondary)
                                                .frame(width: 20, alignment: .trailing)
                                        }
                                    }
                                }
                            }

                            // Top interest badges
                            if !catCounts.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ความสนใจหลัก")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.appTextSecondary)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(catCounts.prefix(3), id: \.key) { cat, count in
                                                HStack(spacing: 6) {
                                                    Image(systemName: EventCategory.icon(for: cat))
                                                        .font(.caption2)
                                                    Text(cat)
                                                        .font(.caption.weight(.semibold))
                                                }
                                                .foregroundColor(EventCategory.color(for: cat))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(EventCategory.color(for: cat).opacity(0.12))
                                                .cornerRadius(20)
                                                .overlay(RoundedRectangle(cornerRadius: 20)
                                                    .stroke(EventCategory.color(for: cat).opacity(0.3), lineWidth: 1))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }

                    // MARK: - Menu Section
                    VStack(spacing: 0) {
                        NavigationLink(destination: MyQRCodeView().environmentObject(authVM)) {
                            menuRow(icon: "qrcode.viewfinder", iconColor: .appOrange,
                                    title: "My QR Code", subtitle: "แสดง QR สำหรับยืนยันตัวตน")
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider().padding(.leading, 64)

                        NavigationLink(destination: StudentHistoryView()
                            .environmentObject(authVM)
                            .environmentObject(eventVM)) {
                            menuRow(icon: "clock.arrow.circlepath", iconColor: Color(hex: "#3B82F6"),
                                    title: "ประวัติกิจกรรม", subtitle: "กิจกรรมที่คุณเข้าร่วม")
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider().padding(.leading, 64)

                        menuRow(icon: "app.badge.fill", iconColor: Color(hex: "#A855F7"),
                                title: "เวอร์ชัน", subtitle: "1.0.0")
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Logout
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.square.fill")
                            Text("ออกจากระบบ")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.appDanger)
                        .background(Color.appDanger.opacity(0.08))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.appDanger.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView().environmentObject(authVM)
        }
        .confirmationDialog("ออกจากระบบ", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("ออกจากระบบ", role: .destructive) { authVM.logout() }
            Button("ยกเลิก", role: .cancel) {}
        } message: {
            Text("คุณต้องการออกจากระบบหรือไม่?")
        }
    }

    @ViewBuilder
    func statBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.appOrange)
                .font(.system(size: 16))
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    func menuRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appTextPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
