import Foundation
import FirebaseFirestore

struct Event: Identifiable, Hashable {
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String
    var limit: Int          // max attendees
    var description: String
    var status: String      // pending | approved | rejected
    var category: String
    var attendees: [String] // registered studentIDs
    var attendeeCount: Int
    var attended: [String]  // studentIDs who actually checked in

    var isFull: Bool {
        attendeeCount >= limit
    }

    var spotsRemaining: Int {
        max(0, limit - attendeeCount)
    }

    var isApproved: Bool {
        status == "approved"
    }

    func isRegistered(studentID: String) -> Bool {
        attendees.contains(studentID)
    }

    // MARK: - Firestore Mapping
    static func from(_ doc: DocumentSnapshot) -> Event? {
        guard let data = doc.data() else { return nil }

        let title    = data["title"] as? String ?? ""
        let location = data["location"] as? String ?? ""
        let desc     = data["description"] as? String ?? ""
        let status   = data["status"] as? String ?? "pending"
        let category = data["category"] as? String ?? "อื่นๆ"
        let limit    = data["limit"] as? Int ?? 0
        let attendees = data["attendees"] as? [String] ?? []
        let attendeeCount = data["attendeeCount"] as? Int ?? attendees.count
        let attended  = data["attended"] as? [String] ?? []

        // Support both Timestamp and String for legacy data
        var startDate = Date()
        var endDate   = Date()

        if let ts = data["startDate"] as? Timestamp {
            startDate = ts.dateValue()
        } else if let s = data["startDate"] as? String {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
            startDate = f.date(from: s) ?? Date()
        }

        if let ts = data["endDate"] as? Timestamp {
            endDate = ts.dateValue()
        } else if let s = data["endDate"] as? String {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
            endDate = f.date(from: s) ?? Date()
        }

        return Event(
            id: doc.documentID,
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            limit: limit,
            description: desc,
            status: status,
            category: category,
            attendees: attendees,
            attendeeCount: attendeeCount,
            attended: attended
        )
    }
}
