import telegram_vapor_bot
import Vapor

final class DefaultBotHandlers {
    private var users: [User] = []
    
    private let publicChatId: TGChatId = .chat(-1001804864589)
    
    private let app: Application
    private let bot: TGBot
    private let networkManager: NetworkService
    
    init(app: Application, bot: TGBot, networkManager: NetworkService) {
        self.app = app
        self.bot = bot
        self.networkManager = networkManager
        addHandlers(app: app, bot: bot)
    }
    
    private func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        addUserHandler(app: app, bot: bot)
        checkHandler(app: app, bot: bot)
        deleteUserHandler(app: app, bot: bot)
        getTweetsHandler(app: app, bot: bot)
    }

    private func addUserHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/add"])) { update, bot in
            guard let message = update.message else {
                print(Abort(.custom(code: 5, reasonPhrase: "Message is nil.")))
                return
            }
            let chatId:TGChatId = .chat(message.chat.id)

            guard var username = message.text else {
                print(Abort(.custom(code: 5, reasonPhrase: "Message is empty.")))
                return
            }

            username.replaceSelf("/add ", "")

            let url = TwitterApi.getIdByUsername(username).url

            self.networkManager.getResourceOf(type: UsersResponse.self, for: url, app: app) { result in
                switch result {
                case .success(let response):
                    self.users.append(response.data)
                    self.send("\(response.data.name) succefully added.", chatId, bot)
                case .failure(let error):
                    print(error)
                    self.send("Sorry couldn't find anyone.", chatId, bot)
                }
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private func checkHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/check"])) { update, bot in
            guard let message = update.message else { return }
            let chatId: TGChatId = .chat(message.chat.id)
            
            let params:TGSendMessageParams = .init(chatId: chatId, text: "Working... Users: \(self.users)")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private func deleteUserHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/delete"])) { update, bot in
            guard let message = update.message else {
                print(Abort(.custom(code: 5, reasonPhrase: "Message is nil.")))
                return
            }
            let chatId:TGChatId = .chat(message.chat.id)

            guard var username = message.text else {
                print(Abort(.custom(code: 5, reasonPhrase: "Message is empty.")))
                return
            }

            username.replaceSelf("/delete ", "")
            guard let index = self.users.firstIndex(where: { $0.name == username }) else {
                self.send("Sorry, didn't find any.", chatId, bot)
                return
            }
            
            self.users.remove(at: index)
            
            let yesButton: TGInlineKeyboardButton = .init(text: "Yes", callbackData: "Yes")
            let noButton: TGInlineKeyboardButton = .init(text: "No", callbackData: "No")
            let keyboard:TGInlineKeyboardMarkup = .init(inlineKeyboard: [[yesButton, noButton]])
            let replyMarkup: TGReplyMarkup = .inlineKeyboardMarkup(keyboard)
            
            self.send("Deleted successfully.", chatId, bot, replyMarkup: replyMarkup)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private func getTweetsHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/getTweets"])) { update, bot in

            var tweets:[Tweet] = []
            let group = DispatchGroup()
            for index in 0..<self.users.count {
                group.enter()
                print("enter")
                let user = self.users[index]
                let url = TwitterApi.getTweetsForUserIdSince(user).url
                self.networkManager.getResourceOf(type: TweetsResponse.self, for: url, app: app) { result in
                    switch result {
                    case .success(let data):
                        tweets.append(contentsOf: data.data)
                        let latestTweetId = data.meta.newestID
                        self.users[index].lastTweetId = latestTweetId
                        print(latestTweetId)
                        group.leave()
                        print("leave")
                    case .failure(let error):
                        print(error)
                        group.leave()
                        print("leave")
                    }
                }
                group.wait()
                print("continue")
            }
            
            
            group.notify(queue: .global()) {
                print("notify")
                tweets.sort { $0.createdAt < $1.createdAt }
                tweets.forEach { tweet in
                    let text = self.createHTML(for: tweet)
                    self.send(text, self.publicChatId, bot, parseMode: .html)
                }
            }
            
        }
        bot.connection.dispatcher.add(handler)
    }
    
    func findUser(with id: String) -> User? {
        return users.first { $0.id == id }
    }
    
    private func createHTML(for tweet: Tweet) -> String {
        guard let user = findUser(with: tweet.authorId) else { return "" }
        return """
            \(user.name) @\(user.username) \(tweet.createdAt.formatted(date: .abbreviated, time: .omitted))
            
            \(tweet.text)
            
            """
    }
    
    func send(_ text: String, _ chatId: TGChatId, _ bot: TGBotPrtcl, parseMode: TGParseMode? = nil, disableWebPagePreview: Bool? = false, _ replyToMessageId: Int? = nil, replyMarkup: TGReplyMarkup? = nil) {
        do {
            let params: TGSendMessageParams = .init(chatId: chatId, text: text, parseMode: parseMode, disableWebPagePreview: disableWebPagePreview, replyToMessageId: replyToMessageId, replyMarkup: replyMarkup)
            try bot.sendMessage(params: params)
        } catch {
            print(Abort(.custom(code: 5, reasonPhrase: "Bot failed to send a message. \(error.localizedDescription)")))
        }
    }
    
    private func createButtonsActionHandler(app: Application, bot: TGBotPrtcl) {
        let handler = TGCallbackQueryHandler(pattern: "Yes") { update, bot in
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try bot.answerCallbackQuery(params: params)
        }

        let handler2 = TGCallbackQueryHandler(pattern: "No") { update, bot in
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try bot.answerCallbackQuery(params: params)
        }

        bot.connection.dispatcher.add(handler)
        bot.connection.dispatcher.add(handler2)
    }
}
