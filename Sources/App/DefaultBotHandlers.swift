import telegram_vapor_bot
import Vapor

final class DefaultBotHandlers {
    
    static func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        checkHandler(app: app, bot: bot)
        startHandler(app: app, bot: bot)
    }
    
    private static func checkHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/check"])) { update, bot in
            guard let message = update.message else { return }
            let chatId: TGChatId = .chat(message.chat.id)
            
            let params:TGSendMessageParams = .init(chatId: chatId, text: "Working...")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func startHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/start"])) { update, bot in
            guard let message = update.message else { return }
            let chatId: TGChatId = .chat(message.chat.id)

            let headers: HTTPHeaders = HTTPHeaders([("Authorization", "Bearer \(Environment.get("BEARER_TOKEN")!)")])
            let uri: URI = URI(string: "https://api.twitter.com/2/users/by/username/elonmusk")
            
            app.client.get(uri, headers: headers).flatMapThrowing { response in
                guard response.status == .ok else { throw Abort(.unauthorized) }
                guard let buffer = response.body else { throw Abort(.badRequest) }
                guard let data = String(buffer: buffer).data(using: .utf8) else { throw Abort(.badRequest) }
                
                do {
                    let data = try JSONDecoder().decode(Response.self, from: data)
                    let params:TGSendMessageParams = .init(chatId: chatId, text: data.data.name)
                    try bot.sendMessage(params: params)
                } catch {
                    let params:TGSendMessageParams = .init(chatId: chatId, text: "Error")
                    try bot.sendMessage(params: params)
                }
            }
        }
        bot.connection.dispatcher.add(handler)
    }
}
