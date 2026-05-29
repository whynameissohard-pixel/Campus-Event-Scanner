import SwiftUI
import FirebaseFirestore
import Combine

class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var myEvents: [Event] = []
    @Published var pendingEvents: [Event] = []
    @Published var totalAttendees: Int = 0
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()
    private var eventsListener: ListenerRegistration?
    private var myEventsListener: ListenerRegistration?

    // MARK: - Fetch All Events (real-time)
    func fetchEvents() {
        isLoading = true
        eventsListener?.remove()
        eventsListener = db.collection("events")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    guard let docs = snapshot?.documents else { return }
                    let all = docs.compactMap { Event.from($0) }
                    self.events        = all.filter { $0.status == "approved" }
                        .sorted { $0.startDate < $1.startDate }
                    self.pendingEvents = all.filter { $0.status == "pending" }
                        .sorted { $0.startDate < $1.startDate }
                    self.totalAttendees = all.reduce(0) { $0 + $1.attendeeCount }
                }
            }
    }

    // MARK: - Fetch Student Registered Events (real-time)
    func fetchMyEvents(studentID: String) {
        guard !studentID.isEmpty else { return }
        myEventsListener?.remove()
        myEventsListener = db.collection("events")
            .whereField("attendees", arrayContains: studentID)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    guard let docs = snapshot?.documents else { return }
                    self.myEvents = docs.compactMap { Event.from($0) }
                        .sorted { $0.startDate < $1.startDate }
                }
            }
    }

    func stopListening() {
        eventsListener?.remove()
        myEventsListener?.remove()
    }

    // MARK: - Create Event
    func createEvent(title: String, startDate: Date, endDate: Date,
                     location: String, description: String,
                     limit: Int, category: String,
                     completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "title": title,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "location": location,
            "description": description,
            "limit": limit,
            "status": "pending",
            "category": category,
            "attendees": [String](),
            "attendeeCount": 0,
            "attended": [String]()
        ]
        db.collection("events").addDocument(data: data) { err in
            DispatchQueue.main.async { completion(err == nil) }
        }
    }

    // MARK: - Edit Event (Admin)
    func editEvent(eventID: String, title: String, startDate: Date, endDate: Date,
                   location: String, description: String,
                   limit: Int, category: String, status: String,
                   completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "title": title,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "location": location,
            "description": description,
            "limit": limit,
            "category": category,
            "status": status
        ]
        db.collection("events").document(eventID).updateData(data) { err in
            DispatchQueue.main.async { completion(err == nil) }
        }
    }

    // MARK: - Delete Event (Admin)
    func deleteEvent(eventID: String, completion: @escaping (Bool) -> Void) {
        db.collection("events").document(eventID).delete { err in
            DispatchQueue.main.async { completion(err == nil) }
        }
    }

    // MARK: - Admin Approve / Reject
    func approveEvent(_ id: String) {
        db.collection("events").document(id).updateData(["status": "approved"])
    }
    func rejectEvent(_ id: String) {
        db.collection("events").document(id).updateData(["status": "rejected"])
    }

    // MARK: - Register for Event
    func registerForEvent(eventID: String, studentID: String,
                          completion: @escaping (Result<Void, RegistrationError>) -> Void) {
        let docRef = db.collection("events").document(eventID)
        docRef.getDocument { snapshot, _ in
            guard let data = snapshot?.data() else {
                completion(.failure(.unknown("ไม่พบกิจกรรม"))); return
            }
            let attendees = data["attendees"] as? [String] ?? []
            let limit = data["limit"] as? Int ?? 0
            if attendees.contains(studentID) { completion(.failure(.alreadyRegistered)); return }
            if attendees.count >= limit { completion(.failure(.eventFull)); return }
            docRef.updateData([
                "attendees": FieldValue.arrayUnion([studentID]),
                "attendeeCount": FieldValue.increment(Int64(1))
            ]) { err in
                DispatchQueue.main.async {
                    completion(err == nil ? .success(()) : .failure(.unknown(err!.localizedDescription)))
                }
            }
        }
    }

    // MARK: - Cancel Registration
    func cancelRegistration(eventID: String, studentID: String,
                            completion: @escaping (Bool) -> Void) {
        db.collection("events").document(eventID).updateData([
            "attendees": FieldValue.arrayRemove([studentID]),
            "attendeeCount": FieldValue.increment(Int64(-1))
        ]) { err in
            DispatchQueue.main.async { completion(err == nil) }
        }
    }

    // MARK: - Mark Attendance (Admin QR Scan)
    func markAttendance(eventID: String, studentID: String,
                        completion: @escaping (Result<Void, AttendanceError>) -> Void) {
        let docRef = db.collection("events").document(eventID)
        docRef.getDocument { snapshot, _ in
            guard let data = snapshot?.data() else {
                completion(.failure(.eventNotFound)); return
            }
            let attendees = data["attendees"] as? [String] ?? []
            let attended  = data["attended"]  as? [String] ?? []
            guard attendees.contains(studentID) else {
                completion(.failure(.notRegistered)); return
            }
            if attended.contains(studentID) {
                completion(.failure(.alreadyCheckedIn)); return
            }
            docRef.updateData(["attended": FieldValue.arrayUnion([studentID])]) { err in
                DispatchQueue.main.async {
                    completion(err == nil ? .success(()) : .failure(.unknown))
                }
            }
        }
    }

    // MARK: - Fetch Registered Events for a Student (Admin QR)
    func fetchRegisteredEventsForStudent(studentID: String,
                                         completion: @escaping ([Event]) -> Void) {
        db.collection("events")
            .whereField("attendees", arrayContains: studentID)
            .whereField("status", isEqualTo: "approved")
            .getDocuments { snapshot, _ in
                let evs = snapshot?.documents.compactMap { Event.from($0) }
                    .sorted { $0.startDate < $1.startDate } ?? []
                DispatchQueue.main.async { completion(evs) }
            }
    }
}

// MARK: - Registration Error
enum RegistrationError: LocalizedError {
    case alreadyRegistered, eventFull
    case unknown(String)
    var errorDescription: String? {
        switch self {
        case .alreadyRegistered: return "คุณได้ลงทะเบียนกิจกรรมนี้แล้ว"
        case .eventFull:         return "ที่นั่งเต็มแล้ว ไม่สามารถลงทะเบียนได้"
        case .unknown(let msg):  return msg
        }
    }
}

// MARK: - Attendance Error
enum AttendanceError: LocalizedError {
    case notRegistered, alreadyCheckedIn, eventNotFound, unknown
    var errorDescription: String? {
        switch self {
        case .notRegistered:    return "นักศึกษาไม่ได้ลงทะเบียนกิจกรรมนี้"
        case .alreadyCheckedIn: return "Check-in แล้ว"
        case .eventNotFound:    return "ไม่พบกิจกรรม"
        case .unknown:          return "เกิดข้อผิดพลาด"
        }
    }
}
