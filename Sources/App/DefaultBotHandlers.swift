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
            
            let params:TGSendMessageParams = .init(chatId: chatId, text: "Working... \(chatId)")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func startHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/start"])) { update, bot in
            guard let message = update.message else { return }
            let chatId: TGChatId = .chat(message.chat.id)
            let url = TwitterApi.getIdByUsername("elonmusk").url
            
            do {
                let response = try getResourceOf(type: Response.self, for: url, app: app).flatMapThrowing { result in
                    let params:TGSendMessageParams = .init(chatId: chatId, text: "\(result.data.name)")
                    try bot.sendMessage(params: params)
                }
            } catch {
                throw Abort(.custom(code: 3, reasonPhrase: "Failed to get resource"))
            }
        }
        bot.connection.dispatcher.add(handler)
    }
}

extension DefaultBotHandlers {
    private static func getResourceOf<T:Codable>(type: T.Type, for url: URL?, app: Vapor.Application) throws -> EventLoopFuture<T> {
        
        guard let urlString = url?.absoluteString else {
            throw Abort(.custom(code: 1, reasonPhrase: "Couldn't convert url to string"))
        }
        
        guard let token = Environment.get("BEARER_TOKEN") else {
            throw Abort(.custom(code: 1, reasonPhrase: "No Bearer Token Variable"))
        }

        let headers: HTTPHeaders = HTTPHeaders([("Authorization", "Bearer \(token)")])
        
        return app.client.get(URI(string: urlString), headers: headers).flatMapThrowing { response in
            guard response.status == .ok else { throw Abort(.unauthorized) }
            guard let buffer = response.body else { throw Abort(.badRequest) }
            guard let data = String(buffer: buffer).data(using: .utf8) else { throw Abort(.badRequest) }
            
            do {
                let data = try JSONDecoder().decode(type.self, from: data)
                return data
            } catch {
                throw Abort(.custom(code: 3, reasonPhrase: "Failed decoding JSON"))
            }
        }
    }
}
