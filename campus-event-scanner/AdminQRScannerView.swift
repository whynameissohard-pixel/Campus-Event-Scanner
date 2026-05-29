import SwiftUI
import AVFoundation
import Combine

// MARK: - AVFoundation Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Scanner ViewModel
class QRAdminScannerVM: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedID: String? = nil
    @Published var cameraPermission: Bool = false
    let session = AVCaptureSession()
    private var isRunning = false

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setupSession(); cameraPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermission = granted
                    if granted { self?.setupSession() }
                }
            }
        default: cameraPermission = false
        }
    }

    func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
    }

    func startScanning() {
        guard !isRunning else { return }
        isRunning = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stopScanning() {
        isRunning = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func resetScan() {
        DispatchQueue.main.async { self.scannedID = nil }
        startScanning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue, scannedID == nil else { return }
        scannedID = value
        stopScanning()
    }
}

// MARK: - Admin QR Scanner View
struct AdminQRScannerView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @StateObject private var scannerVM = QRAdminScannerVM()

    @State private var registeredEvents: [Event] = []
    @State private var isLoadingEvents = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var processingEventID: String? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !scannerVM.cameraPermission {
                noCameraView
            } else if let studentID = scannerVM.scannedID {
                scannedResultView(studentID: studentID)
            } else {
                scannerView
            }
        }
        .navigationBarHidden(true)
        .onAppear { scannerVM.startScanning() }
        .onDisappear { scannerVM.stopScanning() }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("ตกลง", role: .cancel) {}
        } message: { Text(alertMessage) }
    }

    // MARK: - Camera Scanner
    var scannerView: some View {
        ZStack {
            CameraPreviewView(session: scannerVM.session).ignoresSafeArea()
            // Overlay
            VStack {
                // Header
                VStack(spacing: 4) {
                    Text("Admin QR Scanner")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Text("สแกน QR Code ของนักศึกษาเพื่อ Check-in")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
                .background(LinearGradient.heroGradient)

                Spacer()

                // Scan frame
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appOrange, lineWidth: 3)
                        .frame(width: 240, height: 240)
                    // Corner decorations
                    ForEach(0..<4, id: \.self) { i in
                        CornerMark(position: i)
                    }
                }

                Spacer()

                Text("เล็งกล้องไปที่ QR Code ของนักศึกษา")
                    .font(.subheadline).foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Scanned Result View
    func scannedResultView(studentID: String) -> some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { scannerVM.resetScan(); registeredEvents = [] } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left").font(.system(size: 14, weight: .semibold))
                            Text("สแกนใหม่")
                        }
                        .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.white.opacity(0.2)).cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(LinearGradient.heroGradient)

                // Student ID card
                VStack(spacing: 6) {
                    Image(systemName: "person.fill.checkmark")
                        .font(.system(size: 36)).foregroundColor(.appOrange)
                    Text("นักศึกษา")
                        .font(.caption).foregroundColor(.appTextSecondary)
                    Text(studentID)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.appTextPrimary)
                }
                .frame(maxWidth: .infinity).padding(20)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                if isLoadingEvents {
                    Spacer()
                    ProgressView("กำลังโหลดกิจกรรม...")
                        .foregroundColor(.appTextSecondary)
                    Spacer()
                } else if registeredEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48)).foregroundColor(.appOrange.opacity(0.4))
                        Text("ไม่มีกิจกรรมที่ลงทะเบียนไว้")
                            .font(.headline).foregroundColor(.appTextSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            HStack {
                                Text("กิจกรรมที่ลงทะเบียน (\(registeredEvents.count))")
                                    .font(.subheadline.weight(.bold)).foregroundColor(.appTextPrimary)
                                Spacer()
                            }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)

                            ForEach(registeredEvents) { event in
                                AttendanceEventRow(
                                    event: event,
                                    studentID: studentID,
                                    isProcessing: processingEventID == event.id
                                ) {
                                    checkIn(event: event, studentID: studentID)
                                }
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear { loadEvents(for: studentID) }
    }

    var noCameraView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill.badge.ellipsis")
                .font(.system(size: 60)).foregroundColor(.white.opacity(0.5))
            Text("ต้องการสิทธิ์กล้อง")
                .font(.title2.weight(.bold)).foregroundColor(.white)
            Text("กรุณาเปิดสิทธิ์กล้องใน Settings เพื่อสแกน QR Code")
                .font(.subheadline).foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button("เปิด Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(.appOrange).padding(.horizontal, 24).padding(.vertical, 12)
            .background(Color.white).cornerRadius(12)
        }
    }

    // MARK: - Actions
    func loadEvents(for studentID: String) {
        isLoadingEvents = true
        eventVM.fetchRegisteredEventsForStudent(studentID: studentID) { events in
            isLoadingEvents = false
            registeredEvents = events
        }
    }

    func checkIn(event: Event, studentID: String) {
        processingEventID = event.id
        eventVM.markAttendance(eventID: event.id, studentID: studentID) { result in
            processingEventID = nil
            switch result {
            case .success:
                alertTitle = "✅ Check-in สำเร็จ"
                alertMessage = "\(studentID) เข้าร่วม \"\(event.title)\" แล้ว"
                // Refresh
                loadEvents(for: studentID)
            case .failure(let err):
                alertTitle = "❌ ไม่สามารถ Check-in ได้"
                alertMessage = err.localizedDescription ?? "เกิดข้อผิดพลาด"
            }
            showAlert = true
        }
    }
}

// MARK: - Attendance Event Row
struct AttendanceEventRow: View {
    let event: Event
    let studentID: String
    let isProcessing: Bool
    let onCheckIn: () -> Void

    var hasCheckedIn: Bool { event.attended.contains(studentID) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(EventCategory.color(for: event.category).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: EventCategory.icon(for: event.category))
                    .foregroundColor(EventCategory.color(for: event.category))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.subheadline.weight(.semibold))
                    .foregroundColor(.appTextPrimary).lineLimit(1)
                HStack(spacing: 8) {
                    Label(formatDate(event.startDate), systemImage: "calendar")
                    Label(event.location, systemImage: "mappin")
                }
                .font(.caption).foregroundColor(.appTextSecondary).lineLimit(1)
            }
            Spacer()
            if hasCheckedIn {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.appSuccess).font(.system(size: 22))
                    Text("Check-in\nแล้ว").font(.caption2.weight(.semibold))
                        .foregroundColor(.appSuccess).multilineTextAlignment(.center)
                }
            } else {
                Button { onCheckIn() } label: {
                    VStack(spacing: 4) {
                        if isProcessing {
                            ProgressView().scaleEffect(0.8).tint(.white)
                        } else {
                            Image(systemName: "qrcode.viewfinder").font(.system(size: 16))
                            Text("Check-in").font(.caption2.weight(.bold))
                        }
                    }
                    .foregroundColor(.white).frame(width: 64, height: 48)
                    .background(LinearGradient.orangeGradient).cornerRadius(10)
                }
                .disabled(isProcessing)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider().padding(.leading, 72), alignment: .bottom)
    }
}

// MARK: - Corner Mark for scanner overlay
struct CornerMark: View {
    let position: Int
    var body: some View {
        let x: CGFloat = position < 2 ? -110 : 110
        let y: CGFloat = position % 2 == 0 ? -110 : 110
        let rotation: Double = Double(position) * 90
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 20))
                path.addLine(to: .zero)
                path.addLine(to: CGPoint(x: 20, y: 0))
            }
            .stroke(Color.appOrange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
        .frame(width: 20, height: 20)
        .rotationEffect(.degrees(rotation))
        .offset(x: x, y: y)
    }
}
