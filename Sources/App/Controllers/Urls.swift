import Vapor

enum TwitterApi {
    case getIdByUsername(String)
    case getTweetsForUserIdSince(User)
    
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.twitter.com"
        components.path = path
        components.percentEncodedQueryItems = queryItems
        return components.url
    }
    
    private var path: String {
        switch self {
        case .getIdByUsername(let username):
            return "/2/users/by/username/\(username)"
        case .getTweetsForUserIdSince(let user):
            return "/2/users/\(user.id)/tweets"
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case .getIdByUsername:
            return []
        case .getTweetsForUserIdSince(let user):
            var queryItems = [
                    URLQueryItem(name: "exclude", value: "replies,retweets"),
                    URLQueryItem(name: "tweet.fields", value: "created_at,public_metrics,attachments,author_id"),
                    URLQueryItem(name: "expansions", value: "attachments.media_keys,referenced_tweets.id"),
                    URLQueryItem(name: "media.fields", value: "url"),
//                     URLQueryItem(name: "max_results", value: "5"),
                ].customPercentEncoded()
            guard let lastTweet = user.lastTweetId else { return queryItems }
            queryItems.append(URLQueryItem(name: "since_id", value: lastTweet))
            return queryItems
        }
    }
}

// MARK: - Extensions
// There were commas in url after adding queryitems, it's fine server get it, but it looks strange. Myabe I will find more elegant way to set it up 
extension URLQueryItem {
    func customPercentEncoded() -> URLQueryItem {
        var newQueryItem = self
        newQueryItem.value = value?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: ",", with: "%2C")
        return newQueryItem
    }
}

extension Array where Element == URLQueryItem {
    func customPercentEncoded() -> Array<Element> {
        return map { $0.customPercentEncoded() }
    }
}
