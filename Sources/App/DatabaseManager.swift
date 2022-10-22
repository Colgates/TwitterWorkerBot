import Vapor

protocol DatabaseService {
    var users: [UserDB] { get set }
//    func getUsers()
    func addUser(_ user: User, completion: @escaping (String) -> Void)
    func deleteUser(with username: String, completion: @escaping (String) -> Void)
    func updateLastTweet(_ user: UserDB, id: String?)
    func findUser(with username: String) -> UserDB?
    func findUserWith(id: String) -> UserDB?
    func refresh()
    func deleteAll()
}

final class DatabaseManager: DatabaseService {
    
    private let app: Application
    
    var users: [UserDB] = []
    
    init(app: Application) {
        self.app = app
        getUsers()
    }
    
    private func getUsers() {
        let users = UserDB.query(on: app.db).all()
        users.whenComplete { result in
            switch result {
            case .success(let users):
                self.users = users
                print("success get users: \(self.users.count)")
            case .failure(let error):
                print(error)
                print("error getting users db")
            }
        }
    }
    
    func addUser(_ user: User, completion: @escaping (String) -> Void) {
        let userDb = UserDB(userId: user.id, name: user.name, username: user.username)
        userDb.create(on: app.db).whenComplete { result in
            switch result {
            case .success:
                print("success adding new user")
                completion("success adding \(userDb.name)")
                self.getUsers()
                print(self.users.count)
            case .failure(let error):
                print("failed adding new user, error: \(error)")
                completion("failed adding \(userDb.name)")
            }
        }
    }
    
    func deleteUser(with username: String, completion: @escaping (String) -> Void) {
        guard let user = findUser(with: username) else {
            print("Could'n find user with \(username)")
            return
        }
        user.delete(on: app.db).whenComplete { result in
            switch result {
            case .success:
                print("success deleting user: \(user.name)")
                completion("success deleting \(user.name)")
                self.getUsers()
            case .failure(let error):
                print("failed deleting user, error: \(error)")
                completion("failed deleting \(user.name)")
            }
        }
    }
    
    func refresh() {
        users.forEach { updateLastTweet($0, id: nil) }
    }
    
    func deleteAll() {
        users.forEach { user in
            deleteUser(with: user.username) { message in
                print(message)
            }
        }
    }
    
    func updateLastTweet(_ user: UserDB, id: String?) {
        user.lastTweetId = id
        user.update(on: app.db).whenComplete { result in
            switch result {
            case .success:
                print("success updating user: \(user.name)")
                self.getUsers()
            case .failure(let error):
                print("failed adding new user, error: \(error)")
            }
        }
    }
    
    func findUser(with username: String) -> UserDB? {
        return users.first { $0.username == username }
    }
    
    func findUserWith(id: String) -> UserDB? {
        return users.first { $0.userId == id }
    }
}
