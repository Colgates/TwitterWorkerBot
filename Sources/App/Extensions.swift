import Vapor

extension Application {
    static let databaseUrl = Vapor.Environment.get("DB_URL")
    static let botToken = Vapor.Environment.get("BOT_TOKEN")
    static let bearerToken = Vapor.Environment.get("BEARER_TOKEN")
}

extension Date {
    var getStringFromDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateString = dateFormatter.string(from: self)
        return dateString
    }
}
