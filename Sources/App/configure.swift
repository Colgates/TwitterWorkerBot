import Fluent
import FluentPostgresDriver
import telegram_vapor_bot
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    guard let dbUrl = Environment.get("DB_URL") else { throw Abort(.custom(code: 1, reasonPhrase: "No DB URL Variable")) }
    try app.databases.use(.postgres(url: dbUrl), as: .psql)

    guard let tgApi: String = Environment.get("BOT_TOKEN") else { throw Abort(.custom(code: 1, reasonPhrase: "No Token Variable")) }
 
    let connection: TGConnectionPrtcl = TGLongPollingConnection()
    TGBot.configure(connection: connection, botId: tgApi, vaporClient: app.client)
    try TGBot.shared.start()
    
    TGBot.log.logLevel = .error
    
    let networkManager = NetworkManager(app: app)
    let databaseManager = DatabaseManager(app: app)
    let _ = DefaultBotHandlers(app: app, bot: TGBot.shared, networkManager, databaseManager)
}
