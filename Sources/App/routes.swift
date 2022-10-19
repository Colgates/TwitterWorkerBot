//import telegram_vapor_bot
//import Vapor
//
//struct Response: Codable, Content {
//  let data: DataClass
//}
//
//// MARK: - DataClass
//struct DataClass: Codable {
//    let id, name, username: String
//}
//
//func routes(_ app: Application) throws {
//    app.get { req async in
//        "It works!"
//    }
//
//    app.get("hello") { req -> EventLoopFuture<Response> in
//        try getUser(request: req)
//    }
//
//    func getUser(request: Request) throws -> EventLoopFuture<Response> {
//        guard let bearerToken: String = Environment.get("BEARER_TOKEN") else { throw Abort(.custom(code: 1, reasonPhrase: "No Bearer Token Variable")) }
//        let headers: HTTPHeaders = HTTPHeaders([("Authorization", "Bearer \(bearerToken)")])
//
//        let uri: URI = URI(string: "https://api.twitter.com/2/users/by/username/elonmusk")
//
//        return request.client.get(uri, headers: headers).flatMapThrowing { response in
//            guard response.status == .ok else { throw Abort(.unauthorized) }
//            guard let buffer = response.body else { throw Abort(.badRequest) }
//            guard let data = String(buffer: buffer).data(using: .utf8) else { throw Abort(.badRequest) }
//
//            do {
//                let data = try JSONDecoder().decode(Response.self, from: data)
//                print(data)
//                return data
//            } catch {
//                throw Abort(.badRequest)
//            }
//        }
//    }
//}
