import SwiftUI

// MARK: - App Color Palette
extension Color {
    static let appOrange      = Color(hex: "#FF6600")
    static let appOrangeLight = Color(hex: "#FF8533")
    static let appOrangeDark  = Color(hex: "#CC5200")
    static let appBackground  = Color(hex: "#F9F5F0")
    static let appCard        = Color.white
    static let appTextPrimary = Color(hex: "#1A1A1A")
    static let appTextSecondary = Color(hex: "#6B7280")
    static let appSuccess     = Color(hex: "#22C55E")
    static let appDanger      = Color(hex: "#EF4444")
    static let appWarning     = Color(hex: "#F59E0B")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Gradient Presets
extension LinearGradient {
    static let orangeGradient = LinearGradient(
        colors: [Color.appOrange, Color.appOrangeDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let orangeLightGradient = LinearGradient(
        colors: [Color.appOrangeLight, Color.appOrange],
        startPoint: .top,
        endPoint: .bottom
    )
    static let heroGradient = LinearGradient(
        colors: [Color.appOrange.opacity(0.9), Color.appOrangeDark.opacity(0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Category Helpers
struct EventCategory {
    let name: String
    let icon: String
    let color: Color

    static let all: [EventCategory] = [
        EventCategory(name: "ทั้งหมด",    icon: "square.grid.2x2.fill",    color: .appOrange),
        EventCategory(name: "วิชาการ",    icon: "book.fill",                 color: Color(hex: "#3B82F6")),
        EventCategory(name: "กีฬา",       icon: "sportscourt.fill",          color: Color(hex: "#22C55E")),
        EventCategory(name: "มหาวิทยาลัย", icon: "building.columns.fill",    color: Color(hex: "#A855F7")),
        EventCategory(name: "วัฒนธรรม",   icon: "theatermasks.fill",         color: Color(hex: "#EC4899")),
        EventCategory(name: "อื่นๆ",      icon: "ellipsis.circle.fill",      color: Color(hex: "#6B7280"))
    ]

    static func color(for name: String) -> Color {
        all.first { $0.name == name }?.color ?? .appOrange
    }

    static func icon(for name: String) -> String {
        all.first { $0.name == name }?.icon ?? "tag.fill"
    }
}

// MARK: - Reusable View Modifiers
struct OrangeButtonStyle: ViewModifier {
    var isLoading: Bool = false
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isLoading
                ? LinearGradient(colors: [Color.appOrange.opacity(0.6), Color.appOrange.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                : LinearGradient.orangeGradient)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(14)
            .shadow(color: Color.appOrange.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

struct InputFieldStyle: ViewModifier {
    var isFocused: Bool = false
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.appOrange : Color.gray.opacity(0.25), lineWidth: isFocused ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func orangeButtonStyle(isLoading: Bool = false) -> some View {
        modifier(OrangeButtonStyle(isLoading: isLoading))
    }
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    func inputFieldStyle(isFocused: Bool = false) -> some View {
        modifier(InputFieldStyle(isFocused: isFocused))
    }
}

// MARK: - Date Formatter Helper
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "th_TH")
    formatter.dateFormat = "d MMM yyyy"
    return formatter.string(from: date)
}

func formatDateTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "th_TH")
    formatter.dateFormat = "d MMM yyyy, HH:mm"
    return formatter.string(from: date)
}

func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}
