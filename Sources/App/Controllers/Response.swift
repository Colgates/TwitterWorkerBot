import Foundation

// MARK: - UsersResponse

struct UsersResponse: Codable {
    let data: User
}

// MARK: - User

struct User: Codable {
    let id: String
    let name: String
    let username: String
    var lastTweetId: String?
}

// MARK: - TweetsResponse
struct TweetsResponse: Codable {
    let data: [Tweet]
    let meta: Meta
}

// MARK: - Tweet
struct Tweet: Codable {
    let createdAt: Date
    let id: String
    let publicMetrics: PublicMetrics
    let text: String
    let authorId: String
    let editHistoryTweetIDS: [String]

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case id
        case publicMetrics = "public_metrics"
        case text
        case authorId = "author_id"
        case editHistoryTweetIDS = "edit_history_tweet_ids"
    }
}

// MARK: - PublicMetrics
struct PublicMetrics: Codable {
    let retweetCount, replyCount, likeCount, quoteCount: Int

    enum CodingKeys: String, CodingKey {
        case retweetCount = "retweet_count"
        case replyCount = "reply_count"
        case likeCount = "like_count"
        case quoteCount = "quote_count"
    }
}

// MARK: - Meta
struct Meta: Codable {
    let resultCount: Int
    let newestID, oldestID: String

    enum CodingKeys: String, CodingKey {
        case resultCount = "result_count"
        case newestID = "newest_id"
        case oldestID = "oldest_id"
    }
}

