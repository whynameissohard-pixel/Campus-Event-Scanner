import SwiftUI

/// หน้าสร้างกิจกรรมสำหรับ User ทั่วไป
/// เหมือน Admin แต่จะส่งเป็น "pending" รออนุมัติ
struct UserCreateEventView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var location = ""
    @State private var description = ""
    @State private var limit: Int = 50
    @State private var category = "วิชาการ"
    @State private var isCreating = false
    @State private var showSuccess = false

    let categories = ["วิชาการ", "กีฬา", "มหาวิทยาลัย", "วัฒนธรรม", "อื่นๆ"]

    var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty &&
        limit > 0 && endDate > startDate && !isCreating
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Info banner
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.appOrange)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("กิจกรรมจะถูกส่งเพื่อรออนุมัติ")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.appTextPrimary)
                                Text("Admin จะตรวจสอบและอนุมัติก่อนแสดงในรายการ")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.appOrange.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appOrange.opacity(0.2), lineWidth: 1))

                        // Form Card
                        VStack(spacing: 18) {
                            sectionHeader("ข้อมูลกิจกรรม", icon: "info.circle.fill")

                            formField(label: "ชื่อกิจกรรม *", icon: "textformat") {
                                TextField("ระบุชื่อกิจกรรม", text: $title).autocorrectionDisabled()
                            }

                            // Category pills
                            VStack(alignment: .leading, spacing: 6) {
                                Label("หมวดหมู่", systemImage: "tag.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.appTextSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(categories, id: \.self) { cat in
                                            Button {
                                                withAnimation(.spring(response: 0.3)) { category = cat }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: EventCategory.icon(for: cat)).font(.caption)
                                                    Text(cat).font(.caption.weight(.medium))
                                                }
                                                .padding(.vertical, 8).padding(.horizontal, 12)
                                                .background(category == cat
                                                    ? EventCategory.color(for: cat) : Color.white)
                                                .foregroundColor(category == cat ? .white : .appTextSecondary)
                                                .cornerRadius(20)
                                                .overlay(RoundedRectangle(cornerRadius: 20)
                                                    .stroke(category == cat ? Color.clear : Color.gray.opacity(0.2)))
                                            }
                                        }
                                    }.padding(.vertical, 4)
                                }
                            }

                            formField(label: "รายละเอียด", icon: "doc.text") {
                                TextField("รายละเอียด (ไม่บังคับ)", text: $description, axis: .vertical)
                                    .lineLimit(3, reservesSpace: true).autocorrectionDisabled()
                            }

                            Divider()
                            sectionHeader("วันเวลาและสถานที่", icon: "calendar.badge.clock")

                            formField(label: "วันเริ่มต้น *", icon: "calendar") {
                                DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                            }
                            formField(label: "วันสิ้นสุด *", icon: "calendar.badge.checkmark") {
                                DatePicker("", selection: $endDate, in: startDate...,
                                           displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                            }
                            formField(label: "สถานที่ *", icon: "mappin.circle.fill") {
                                TextField("ระบุสถานที่จัดงาน", text: $location).autocorrectionDisabled()
                            }

                            Divider()
                            sectionHeader("จำนวนที่นั่ง", icon: "person.3.fill")

                            // Stepper
                            VStack(alignment: .leading, spacing: 6) {
                                Label("จำนวนผู้เข้าร่วมสูงสุด *", systemImage: "person.3.fill")
                                    .font(.caption.weight(.semibold)).foregroundColor(.appTextSecondary)
                                HStack {
                                    Button { if limit > 1 { limit -= 1 } } label: {
                                        Image(systemName: "minus.circle.fill").font(.system(size: 28))
                                            .foregroundColor(limit > 1 ? .appOrange : .gray.opacity(0.3))
                                    }.disabled(limit <= 1)
                                    Spacer()
                                    VStack(spacing: 2) {
                                        Text("\(limit)").font(.system(size: 32, weight: .bold)).foregroundColor(.appTextPrimary)
                                        Text("คน").font(.caption).foregroundColor(.appTextSecondary)
                                    }
                                    Spacer()
                                    Button { if limit < 9999 { limit += 1 } } label: {
                                        Image(systemName: "plus.circle.fill").font(.system(size: 28)).foregroundColor(.appOrange)
                                    }
                                }
                                .padding(.horizontal, 20).padding(.vertical, 12)
                                .background(Color.appBackground).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                                HStack(spacing: 8) {
                                    Text("ด่วน:").font(.caption).foregroundColor(.appTextSecondary)
                                    ForEach([25, 50, 100, 200], id: \.self) { p in
                                        Button("\(p)") { limit = p }
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 10).padding(.vertical, 4)
                                            .background(limit == p ? Color.appOrange : Color.gray.opacity(0.08))
                                            .foregroundColor(limit == p ? .white : .appTextSecondary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(20).background(Color.white).cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)

                        // Submit
                        Button { createEvent() } label: {
                            HStack(spacing: 10) {
                                if isCreating { ProgressView().tint(.white) }
                                Image(systemName: "paperplane.fill")
                                Text(isCreating ? "กำลังส่ง..." : "ส่งคำขอสร้างกิจกรรม")
                                    .fontWeight(.semibold)
                            }
                            .orangeButtonStyle(isLoading: isCreating)
                        }
                        .disabled(!canCreate).opacity(canCreate ? 1 : 0.5)

                        Spacer(minLength: 30)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("เสนอกิจกรรม")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") { dismiss() }.foregroundColor(.appOrange)
                }
            }
            .alert("✅ ส่งคำขอสำเร็จ", isPresented: $showSuccess) {
                Button("ตกลง") { dismiss() }
            } message: {
                Text("กิจกรรม \"\(title)\" ถูกส่งเพื่อรออนุมัติจาก Admin แล้ว")
            }
        }
    }

    @ViewBuilder func sectionHeader(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.appOrange).font(.system(size: 14))
            Text(text).font(.subheadline.weight(.bold)).foregroundColor(.appTextPrimary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder func formField<C: View>(label: String, icon: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon).font(.caption.weight(.semibold)).foregroundColor(.appTextSecondary)
            content().padding(.horizontal, 12).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appBackground).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        }
    }

    func createEvent() {
        isCreating = true
        eventVM.createEvent(title: title, startDate: startDate, endDate: endDate,
                            location: location, description: description,
                            limit: limit, category: category) { success in
            isCreating = false
            if success { showSuccess = true }
        }
    }
}
