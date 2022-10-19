import telegram_vapor_bot
import Vapor
import Queues

struct CleanupJob: AsyncScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    let bot: TGBot
    
    func run(context: QueueContext) async throws {
        // Do some work here, perhaps queue up another job.
        let chatId: TGChatId = .chat(-1001804864589)
        let params:TGSendMessageParams = .init(chatId: chatId, text: "This is scheduled message")
        try bot.sendMessage(params: params)
    }
}

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    guard let tgApi: String = Environment.get("BOT_TOKEN") else { throw Abort(.custom(code: 1, reasonPhrase: "No Token Variable")) }
 
    let connection: TGConnectionPrtcl = TGLongPollingConnection()
    TGBot.configure(connection: connection, botId: tgApi, vaporClient: app.client)
    try TGBot.shared.start()
    
    TGBot.log.logLevel = .error
    
    DefaultBotHandlers.addHandlers(app: app, bot: TGBot.shared)
    
    app.queues.schedule(CleanupJob(bot: TGBot.shared)).daily().at(18, 30)
}
