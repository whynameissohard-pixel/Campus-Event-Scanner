import SwiftUI

struct StudentTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var eventVM = EventViewModel()

    var body: some View {
        TabView {
            NavigationView {
                EventListView()
            }
            .tabItem { Label("กิจกรรม", systemImage: "calendar") }

            NavigationView {
                StudentHistoryView()
            }
            .tabItem { Label("ประวัติ", systemImage: "clock.arrow.circlepath") }

            NavigationView {
                MyQRCodeView()
            }
            .tabItem { Label("My QR", systemImage: "qrcode") }

            NavigationView {
                ProfileView()
            }
            .tabItem { Label("โปรไฟล์", systemImage: "person.circle") }
        }
        .accentColor(.appOrange)
        .environmentObject(eventVM)
        .onAppear {
            eventVM.fetchEvents()
            // studentID may already be loaded (e.g. app relaunch with session)
            if !authVM.studentID.isEmpty {
                eventVM.fetchMyEvents(studentID: authVM.studentID)
            }
            // Style tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        // ✅ Fix: React when studentID loads AFTER login (Firestore profile fetch delay)
        .onChange(of: authVM.studentID) { newID in
            if !newID.isEmpty {
                eventVM.fetchMyEvents(studentID: newID)
            }
        }
    }
}
