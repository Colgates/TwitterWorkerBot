import Fluent
import FluentPostgresDriver
import telegram_vapor_bot
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.databases.use(.postgres(url: "postgres://users_q3jw_user:cAYB07ASH4zJp4uuNuu7MgilVgV808fv@dpg-cd94ibun6mpi3erjcomg-a.frankfurt-postgres.render.com/users_q3jw"), as: .psql)
    app.migrations.add(CreateUser())
    guard let tgApi: String = Environment.get("BOT_TOKEN") else { throw Abort(.custom(code: 1, reasonPhrase: "No Token Variable")) }
 
    let connection: TGConnectionPrtcl = TGLongPollingConnection()
    TGBot.configure(connection: connection, botId: tgApi, vaporClient: app.client)
    try TGBot.shared.start()
    
    TGBot.log.logLevel = .error
    
    let _ = DefaultBotHandlers(app: app, bot: TGBot.shared, networkManager: NetworkManager())
}
