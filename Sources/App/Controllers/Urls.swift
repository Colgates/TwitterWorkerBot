import Vapor

enum TwitterApi {
    case getTweets(Int)
    case getIdByUsername(String)
    
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.twitter.com"
        components.path = path
        return components.url
    }
    
    private var path: String {
        switch self {
        case .getTweets(let id):
            return "/2/users/\(id)/tweets"
        case .getIdByUsername(let username):
            return "/2/users/by/username/\(username)"
        }
    }
}
