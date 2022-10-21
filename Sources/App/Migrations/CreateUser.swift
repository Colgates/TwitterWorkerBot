import Foundation
import Fluent
import FluentPostgresDriver

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .string)
            .field("name", .string)
            .field("username", .string)
            .field("lastTweetId", .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

final class UserDB: Model {
    
    static let schema: String = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "userId")
    var userId:String
    @Field(key: "name")
    var name:String
    @Field(key: "username")
    var username:String
    @Field(key: "lastTweetId")
    var lastTweetId:String
    
    init() {}
    
    init(userId: String, name: String, username: String, lastTweetId: String) {
        self.userId = userId
        self.name = name
        self.username = username
        self.lastTweetId = lastTweetId
    }
}
