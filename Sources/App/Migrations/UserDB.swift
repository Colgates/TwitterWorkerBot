import Foundation
import Fluent
import FluentPostgresDriver
import Vapor

//struct CreateUser: Migration {
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("usersdb")
//            .field("id", .string)
//            .field("name", .string)
//            .field("username", .string)
//            .field("lastTweetId", .string)
//            .create()
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("usersdb").delete()
//    }
//}

final class UserDB: Model, Content {
    
    static let schema: String = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "userid")
    var userId: String
    @Field(key: "name")
    var name: String
    @Field(key: "username")
    var username: String
    @Field(key: "lasttweetid")
    var lastTweetId: String?
    
    init() {}
    
    init(id: UUID? = nil, userId: String, name: String, username: String, lastTweetId: String? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.username = username
        self.lastTweetId = lastTweetId
    }
}
