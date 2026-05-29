import SwiftUI

struct AdminEventDetailView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss

    let event: Event

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient.heroGradient.frame(height: 180)
                        Circle().fill(Color.white.opacity(0.07)).frame(width: 160).offset(x: 200, y: -50)

                        VStack(alignment: .leading, spacing: 8) {
                            // Status badge
                            statusBadge(event.status)
                            Text(event.title)
                                .font(.system(size: 20, weight: .bold)).foregroundColor(.white).lineLimit(3)
                        }.padding(24)
                    }

                    VStack(spacing: 14) {
                        // Info grid
                        HStack(spacing: 14) {
                            infoBox(icon: "calendar", color: .appOrange, title: "วันเริ่ม",
                                    value: formatDate(event.startDate))
                            infoBox(icon: "calendar.badge.checkmark", color: Color(hex: "#A855F7"),
                                    title: "วันสิ้นสุด", value: formatDate(event.endDate))
                        }
                        HStack(spacing: 14) {
                            infoBox(icon: "clock.fill", color: Color(hex: "#3B82F6"), title: "เวลา",
                                    value: "\(formatTime(event.startDate)) - \(formatTime(event.endDate))")
                            infoBox(icon: "mappin.circle.fill", color: Color(hex: "#EF4444"),
                                    title: "สถานที่", value: event.location)
                        }
                        HStack(spacing: 14) {
                            infoBox(icon: "person.3.fill", color: .appSuccess,
                                    title: "ผู้ลงทะเบียน", value: "\(event.attendeeCount)/\(event.limit)")
                            infoBox(icon: "checkmark.seal.fill", color: .appOrange,
                                    title: "Check-in แล้ว", value: "\(event.attended.count) คน")
                        }

                        // Category
                        HStack(spacing: 10) {
                            Image(systemName: EventCategory.icon(for: event.category))
                                .foregroundColor(EventCategory.color(for: event.category))
                            Text(event.category)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(EventCategory.color(for: event.category))
                            Spacer()
                        }
                        .padding(14)
                        .background(EventCategory.color(for: event.category).opacity(0.08))
                        .cornerRadius(12)

                        // Description
                        if !event.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("รายละเอียด", systemImage: "doc.text.fill")
                                    .font(.subheadline.weight(.semibold)).foregroundColor(.appOrange)
                                Text(event.description)
                                    .font(.body).foregroundColor(.appTextSecondary).lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16).cardStyle()
                        }

                        // Attendees list
                        if !event.attendees.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("รายชื่อผู้ลงทะเบียน (\(event.attendees.count))",
                                      systemImage: "person.3.fill")
                                    .font(.subheadline.weight(.semibold)).foregroundColor(.appOrange)
                                ForEach(event.attendees, id: \.self) { sid in
                                    HStack(spacing: 10) {
                                        Circle().fill(Color.appOrange.opacity(0.12)).frame(width: 32, height: 32)
                                            .overlay(Image(systemName: "person.fill")
                                                .font(.caption).foregroundColor(.appOrange))
                                        Text(sid).font(.system(.subheadline, design: .monospaced))
                                            .foregroundColor(.appTextPrimary)
                                        Spacer()
                                        if event.attended.contains(sid) {
                                            Label("Check-in", systemImage: "checkmark.seal.fill")
                                                .font(.caption.weight(.semibold)).foregroundColor(.appSuccess)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    Divider()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16).cardStyle()
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(16)
                }
            }

            // Bottom action bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    // Delete
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("ลบ").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .foregroundColor(.appDanger)
                        .background(Color.appDanger.opacity(0.1)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appDanger.opacity(0.3), lineWidth: 1))
                    }
                    // Edit
                    Button { showEditSheet = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.circle.fill")
                            Text("แก้ไข").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(LinearGradient.orangeGradient).cornerRadius(12)
                        .shadow(color: Color.appOrange.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.white)
            }
        }
        .navigationTitle("รายละเอียดกิจกรรม")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            EditEventSheet(event: event).environmentObject(eventVM)
        }
        .confirmationDialog("ลบกิจกรรม", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("ลบกิจกรรม", role: .destructive) { deleteEvent() }
            Button("ยกเลิก", role: .cancel) {}
        } message: {
            Text("คุณต้องการลบกิจกรรม \"\(event.title)\" หรือไม่? ไม่สามารถย้อนกลับได้")
        }
    }

    func deleteEvent() {
        isDeleting = true
        eventVM.deleteEvent(eventID: event.id) { _ in
            dismiss()
        }
    }

    @ViewBuilder func statusBadge(_ status: String) -> some View {
        let config: (String, Color) = {
            switch status {
            case "approved": return ("✅ อนุมัติแล้ว", .appSuccess)
            case "rejected": return ("❌ ถูกปฏิเสธ", .appDanger)
            default:         return ("⏳ รออนุมัติ", .appWarning)
            }
        }()
        Text(config.0).font(.caption.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(config.1.opacity(0.85)).cornerRadius(20)
    }

    @ViewBuilder func infoBox(icon: String, color: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon).foregroundColor(color).font(.caption)
                Text(title).font(.caption).foregroundColor(.appTextSecondary)
            }
            Text(value).font(.subheadline.weight(.semibold)).foregroundColor(.appTextPrimary).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12).cardStyle()
    }
}

// MARK: - Edit Event Sheet
struct EditEventSheet: View {
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss

    let event: Event

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var location = ""
    @State private var description = ""
    @State private var limit = 50
    @State private var category = "วิชาการ"
    @State private var status = "pending"
    @State private var isSaving = false
    @State private var showSuccess = false

    let categories = ["วิชาการ", "กีฬา", "มหาวิทยาลัย", "วัฒนธรรม", "อื่นๆ"]
    let statuses = ["pending", "approved", "rejected"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        VStack(spacing: 14) {
                            editField(label: "ชื่อกิจกรรม", icon: "textformat") {
                                TextField("ชื่อกิจกรรม", text: $title).autocorrectionDisabled()
                            }
                            editField(label: "รายละเอียด", icon: "doc.text") {
                                TextField("รายละเอียด", text: $description, axis: .vertical)
                                    .lineLimit(3, reservesSpace: true)
                            }
                            editField(label: "วันเริ่มต้น", icon: "calendar") {
                                DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                            }
                            editField(label: "วันสิ้นสุด", icon: "calendar.badge.checkmark") {
                                DatePicker("", selection: $endDate, in: startDate...,
                                           displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                            }
                            editField(label: "สถานที่", icon: "mappin.circle.fill") {
                                TextField("สถานที่", text: $location).autocorrectionDisabled()
                            }
                            editField(label: "จำนวนที่นั่ง", icon: "person.3.fill") {
                                Stepper("\(limit) คน", value: $limit, in: 1...9999)
                            }
                            editField(label: "หมวดหมู่", icon: "tag.fill") {
                                Picker("หมวดหมู่", selection: $category) {
                                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                                }.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            editField(label: "สถานะ", icon: "checkmark.seal.fill") {
                                Picker("สถานะ", selection: $status) {
                                    Text("รออนุมัติ").tag("pending")
                                    Text("อนุมัติ").tag("approved")
                                    Text("ปฏิเสธ").tag("rejected")
                                }.pickerStyle(.segmented)
                            }
                        }
                        .padding(16).background(Color.white).cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)

                        Button { saveChanges() } label: {
                            HStack(spacing: 10) {
                                if isSaving { ProgressView().tint(.white) }
                                Text(isSaving ? "กำลังบันทึก..." : "บันทึกการแก้ไข").fontWeight(.semibold)
                            }
                            .orangeButtonStyle(isLoading: isSaving)
                        }
                        .disabled(isSaving || title.isEmpty || location.isEmpty)
                        .opacity(title.isEmpty || location.isEmpty ? 0.5 : 1)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("แก้ไขกิจกรรม")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") { dismiss() }.foregroundColor(.appOrange)
                }
            }
            .alert("✅ บันทึกสำเร็จ", isPresented: $showSuccess) {
                Button("ตกลง") { dismiss() }
            }
        }
        .onAppear {
            title = event.title; startDate = event.startDate; endDate = event.endDate
            location = event.location; description = event.description
            limit = event.limit; category = event.category; status = event.status
        }
    }

    @ViewBuilder func editField<C: View>(label: String, icon: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon).font(.caption.weight(.semibold)).foregroundColor(.appTextSecondary)
            content().padding(.horizontal, 10).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appBackground).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
        }
    }

    func saveChanges() {
        isSaving = true
        eventVM.editEvent(eventID: event.id, title: title, startDate: startDate, endDate: endDate,
                          location: location, description: description,
                          limit: limit, category: category, status: status) { success in
            isSaving = false
            if success { showSuccess = true }
        }
    }
}
