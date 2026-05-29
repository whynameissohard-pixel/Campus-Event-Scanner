import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    // User profile fields
    @Published var studentID: String = ""
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var currentUserRole: String = "user"

    private var auth = Auth.auth()
    private var db   = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    var isLoggedIn: Bool { user != nil }
    var isAdmin: Bool { currentUserRole == "admin" }
    var currentUserID: String? { user?.uid }

    init() {
        // Auto-restore session on app launch
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                if let uid = user?.uid {
                    self?.fetchUserProfile(uid: uid)
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Login
    func login(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "กรุณากรอกอีเมลและรหัสผ่าน"
            return
        }
        isLoading = true
        errorMessage = nil

        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = Self.friendlyError(error)
                    return
                }
                if let user = result?.user {
                    self?.user = user
                    self?.fetchUserProfile(uid: user.uid)
                }
            }
        }
    }

    // MARK: - Register
    func register(email: String, password: String, studentID: String, name: String, completion: @escaping (Bool) -> Void) {
        guard !email.isEmpty, !password.isEmpty, !studentID.isEmpty else {
            self.errorMessage = "กรุณากรอกข้อมูลให้ครบถ้วน"
            completion(false)
            return
        }
        isLoading = true
        errorMessage = nil

        // Check duplicate StudentID first
        checkStudentIDExists(studentID: studentID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "ไม่สามารถตรวจสอบรหัสนักศึกษาได้ กรุณาลองใหม่"
                    print("⚠️ checkStudentIDExists error: \(error.localizedDescription)")
                    completion(false)
                }
                return
            case .success(let exists):
                if exists {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "รหัสนักศึกษานี้ถูกใช้งานแล้ว"
                        completion(false)
                    }
                    return
                }
            }

            // Proceed with Firebase Auth
            self.auth.createUser(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.isLoading = false
                        self.errorMessage = Self.friendlyError(error)
                        completion(false)
                        return
                    }

                    guard let user = result?.user else {
                        self.isLoading = false
                        completion(false)
                        return
                    }

                    // Save user profile to Firestore
                    let userData: [String: Any] = [
                        "email": email,
                        "studentID": studentID,
                        "name": name,
                        "role": "user",
                        "createdAt": Timestamp()
                    ]

                    self.db.collection("users").document(user.uid).setData(userData) { err in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if let err = err {
                                self.errorMessage = err.localizedDescription
                                completion(false)
                            } else {
                                self.user = user
                                self.studentID = studentID
                                self.userName = name
                                self.userEmail = email
                                self.currentUserRole = "user"
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Fetch User Profile
    func fetchUserProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                self.currentUserRole = data["role"] as? String ?? "user"
                self.studentID       = data["studentID"] as? String ?? ""
                self.userName        = data["name"] as? String ?? ""
                self.userEmail       = data["email"] as? String ?? ""
            }
        }
    }

    // MARK: - Update Profile Name
    func updateName(_ name: String, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserID else { completion(false); return }
        db.collection("users").document(uid).updateData(["name": name]) { [weak self] err in
            DispatchQueue.main.async {
                if err == nil { self?.userName = name }
                completion(err == nil)
            }
        }
    }

    // MARK: - Check Duplicate StudentID
    func checkStudentIDExists(studentID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        db.collection("users")
            .whereField("studentID", isEqualTo: studentID)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                let exists = !(snapshot?.documents.isEmpty ?? true)
                DispatchQueue.main.async {
                    completion(.success(exists))
                }
            }
    }

    // MARK: - Logout
    func logout() {
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.currentUserRole = "user"
                self.studentID = ""
                self.userName  = ""
                self.userEmail = ""
                self.errorMessage = nil
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Error Helper
    private static func friendlyError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case 17004: return "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
        case 17007: return "อีเมลนี้ถูกใช้งานแล้ว"
        case 17008: return "รูปแบบอีเมลไม่ถูกต้อง"
        case 17009: return "รหัสผ่านไม่ถูกต้อง"
        case 17011: return "ไม่พบบัญชีผู้ใช้นี้"
        case 17026: return "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร"
        default:    return error.localizedDescription
        }
    }
}
