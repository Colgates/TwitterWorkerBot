import Vapor

protocol DatabaseService {
    var users: [UserDB] { get set }
    func getAllUsers()
    func addUser(_ user: User, completion: @escaping (String) -> Void)
    func deleteUser(with username: String, completion: @escaping (String) -> Void)
    func updateLastTweet(_ user: UserDB, id: String?)
    func findUser(with username: String) -> UserDB?
    func findUserWith(id: String) -> UserDB?
    func refresh()
    func deleteAll(completion: @escaping (String) -> Void)
}

final class DatabaseManager: DatabaseService {
    
    private let app: Application
    
    var users: [UserDB] = []
    
    init(app: Application) {
        self.app = app
        getAllUsers()
    }
    
    func getAllUsers() {
        UserDB.query(on: app.db).all().whenComplete { result in
            switch result {
            case .success(let users):
                self.users = users
                print("Successfully got users: \(self.users.count)")
            case .failure(let error):
                print("error getting users.\(error)")
            }
        }
    }
    
    func addUser(_ user: User, completion: @escaping (String) -> Void) {
        
        if let user = findUserWith(id: user.id) {
            completion("\(user.name) already in the list.")
            
        } else {
            let userdb = UserDB(userId: user.id, name: user.name, username: user.username)
            
            userdb.create(on: app.db).whenComplete { result in
                switch result {
                case .success:
                    completion("\(user.name) successfully added.")
                    self.users.append(userdb)
                case .failure(let error):
                    completion("Failed to add \(user.name) to the list, error: \(error)")
                }
            }
        }
    }
    
    func deleteUser(with username: String, completion: @escaping (String) -> Void) {
        guard let index = users.firstIndex(where: { $0.username == username }) else {
            completion("Couldn't find anyone with username: \(username)")
            return
        }
        let user = users[index]
        user.delete(on: app.db).whenComplete { result in
            switch result {
            case .success:
                self.users.remove(at: index)
                completion("\(user.name) deleted.")
            case .failure(let error):
                completion("Failed to delete \(user.name), error: \(error)")
            }
        }
    }
    
    func updateLastTweet(_ user: UserDB, id: String?) {
        
        _ = UserDB.find(user.id, on: app.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user -> EventLoopFuture<Void> in
                user.lastTweetId = id
                return user.save(on: self.app.db)
            }
    }
    
    func findUser(with username: String) -> UserDB? {
        users.first(where: { $0.username == username })
    }
    
    func findUserWith(id: String) -> UserDB? {
        users.first(where: { $0.userId == id })
    }
    
    func refresh() {
        users.forEach { $0.lastTweetId = nil }
        users.forEach { updateLastTweet($0, id: nil)}
    }
    
    func deleteAll(completion: @escaping (String) -> Void) {
        let _ = UserDB.query(on: app.db).delete().whenComplete { result in
            switch result {
            case .success:
                completion("All users deleted.")
                self.users.removeAll()
            case .failure(let error):
                completion("Failed to delete all users. \(error)")
            }
        }
    }
}
