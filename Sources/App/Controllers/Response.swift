import Foundation

struct Response: Codable {
    let data: DataClass
}

struct DataClass: Codable {
    let id, name, username: String
}
