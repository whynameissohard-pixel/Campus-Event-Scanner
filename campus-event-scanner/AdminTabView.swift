import SwiftUI

struct AdminTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var eventVM = EventViewModel()

    var body: some View {
        TabView {
            NavigationView { AdminDashboardView() }
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            NavigationView { PendingApprovalView() }
                .tabItem { Label("อนุมัติ", systemImage: "checkmark.seal.fill") }

            NavigationView { CreateEventView() }
                .tabItem { Label("สร้าง", systemImage: "plus.circle.fill") }

            NavigationView { AdminQRScannerView() }
                .tabItem { Label("QR Scan", systemImage: "qrcode.viewfinder") }

            NavigationView { ProfileView() }
                .tabItem { Label("โปรไฟล์", systemImage: "person.circle") }
        }
        .accentColor(.appOrange)
        .environmentObject(eventVM)
        .onAppear {
            eventVM.fetchEvents()
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
