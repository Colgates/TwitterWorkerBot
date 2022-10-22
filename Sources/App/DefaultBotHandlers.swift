import telegram_vapor_bot
import Vapor

final class DefaultBotHandlers {
//    private var users: [User] = []
    
    private let publicChatId: TGChatId = .chat(-1001804864589)
    
    private let app: Application
    private let bot: TGBot
    private let networkManager: NetworkService
    private let databaseManager: DatabaseService
    
    init(app: Application, bot: TGBot, _ networkManager: NetworkService, _ databaseManager: DatabaseService) {
        self.app = app
        self.bot = bot
        self.networkManager = networkManager
        self.databaseManager = databaseManager
        addHandlers(app: app, bot: bot)
    }
    
    private func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        addUserHandler(app: app, bot: bot)
        checkHandler(app: app, bot: bot)
        deleteUserHandler(app: app, bot: bot)
        getTweetsHandler(app: app, bot: bot)
        refreshHandler(app: app, bot: bot)
        deleteAllHandler(app: app, bot: bot)
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

            self.networkManager.getResourceOf(type: UsersResponse.self, for: url) { result in
                switch result {
                case .success(let response):
                    self.databaseManager.addUser(response.data) { self.send($0, chatId, bot) }
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
            
            var text: String = "Working..."
            for index in 0..<self.databaseManager.users.count {
                text += "\n\(index + 1). \(self.databaseManager.users[index].name)"
            }
             
            let params:TGSendMessageParams = .init(chatId: chatId, text: text)
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
            
            self.databaseManager.deleteUser(with: username) { self.send($0, chatId, bot)}
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private func getTweetsHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/getTweets"])) { update, bot in

            var tweets:[Tweet] = []
            let group = DispatchGroup()
            for index in 0..<self.databaseManager.users.count {
                group.enter()
                print("enter")
                let user = self.databaseManager.users[index]
                let url = TwitterApi.getTweetsForUserIdSince(user).url
                self.networkManager.getResourceOf(type: TweetsResponse.self, for: url) { result in
                    switch result {
                    case .success(let response):
                        
                        tweets.append(contentsOf: response.data)
                        let newestID = response.meta.newestID
                        
                        self.databaseManager.users[index].lastTweetId = newestID
                        self.databaseManager.updateLastTweet(user, id: newestID)

                        sleep(5)
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
                self.publish(tweets)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private func refreshHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/refresh"])) { update, bot in

            guard let message = update.message else {
                print(Abort(.custom(code: 5, reasonPhrase: "Message is nil.")))
                return
            }
            let chatId:TGChatId = .chat(message.chat.id)
            
            self.databaseManager.refresh()
            
            self.databaseManager.users.forEach { self.send($0.lastTweetId ?? "nil", chatId, bot) }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private func deleteAllHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/deleteAll"])) { update, bot in
            guard let message = update.message else {
                print(Abort(.custom(code: 5, reasonPhrase: "Message is nil.")))
                return
            }
            let chatId:TGChatId = .chat(message.chat.id)

            self.databaseManager.deleteAll { self.send($0, chatId, bot)}
        }
        bot.connection.dispatcher.add(handler)
    }
}

// MARK: - Helpers
extension DefaultBotHandlers {
    private func createHTML(for tweet: Tweet) -> String {
        guard let user = databaseManager.findUserWith(id: tweet.authorId) else { return "" }
        return """
            \(user.name) @\(user.username) \(tweet.createdAt.getStringFromDate)
            
            \(tweet.text)
            
            """
    }
    
    private func publish(_ tweets: [Tweet]) {
        var tweets = tweets.sorted { $0.createdAt < $1.createdAt }
        print(tweets.count)
        tweets.forEach { tweet in
            sleep(2)
            let text = self.createHTML(for: tweet)
            self.send(text, self.publicChatId, bot, parseMode: .html)
        }
    }
    
    private func send(_ text: String, _ chatId: TGChatId, _ bot: TGBotPrtcl, parseMode: TGParseMode? = nil, disableWebPagePreview: Bool? = false, _ replyToMessageId: Int? = nil, replyMarkup: TGReplyMarkup? = nil) {
        do {
            let params: TGSendMessageParams = .init(chatId: chatId, text: text, parseMode: parseMode, disableWebPagePreview: disableWebPagePreview, replyToMessageId: replyToMessageId, replyMarkup: replyMarkup)
            try bot.sendMessage(params: params)
        } catch {
            print(Abort(.custom(code: 5, reasonPhrase: "Bot failed to send a message. \(error.localizedDescription)")))
        }
        
        //            let yesButton: TGInlineKeyboardButton = .init(text: "Yes", callbackData: "Yes")
        //            let noButton: TGInlineKeyboardButton = .init(text: "No", callbackData: "No")
        //            let keyboard:TGInlineKeyboardMarkup = .init(inlineKeyboard: [[yesButton, noButton]])
        //            let replyMarkup: TGReplyMarkup = .inlineKeyboardMarkup(keyboard)
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
