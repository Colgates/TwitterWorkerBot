import telegram_vapor_bot
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    guard let tgApi: String = Environment.get("BOT_TOKEN") else { throw Abort(.custom(code: 1, reasonPhrase: "No Token Variable")) }
//    WebHook
//    let connection: TGConnectionPrtcl = TGWebHookConnection(webHookURL: "https://test-production-acc8.up.railway.app/webhook")
//    TGBot.configure(connection: connection, botId: tgApi, vaporClient: app.client)
    
    let connection: TGConnectionPrtcl = TGLongPollingConnection()
    TGBot.configure(connection: connection, botId: tgApi, vaporClient: app.client)
    try TGBot.shared.start()
    
    TGBot.log.logLevel = .error
    
    DefaultBotHandlers.addHandlers(app: app, bot: TGBot.shared)
    
    // register routes
//    try routes(app)
}
