import Vapor

extension Application {
    static let databaseUrl = Vapor.Environment.get("DB_URL")
    static let botToken = Vapor.Environment.get("BOT_TOKEN")
    static let bearerToken = Vapor.Environment.get("BEARER_TOKEN")
    static let publicChatId = Int64(Vapor.Environment.get("CHAT_ID")!)!
}

extension Date {
    var getStringFromDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateString = dateFormatter.string(from: self)
        return dateString
    }
}
