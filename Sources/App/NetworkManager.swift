import Vapor

protocol NetworkService {
    func getResourceOf<T:Codable>(type: T.Type, for url: URL?, app: Vapor.Application, completion: @escaping (Result<T, Error>) -> Void)
}

class NetworkManager: NetworkService {
    
    func getResourceOf<T:Codable>(type: T.Type, for url: URL?, app: Vapor.Application, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let urlString = url?.absoluteString else {
            return completion(.failure(Abort(.custom(code: 1, reasonPhrase: "Couldn't convert url to string"))))
        }
        print(urlString)
        guard let token = Environment.get("BEARER_TOKEN") else {
            return completion(.failure(Abort(.custom(code: 1, reasonPhrase: "No Bearer Token Variable"))))
        }
        
        let headers: HTTPHeaders = HTTPHeaders([("Authorization", "Bearer \(token)")])
        
        app.client.get(URI(string: urlString), headers: headers).whenComplete { result in
            switch result {
            case .success(let response):
                guard response.status == .ok else { return completion(.failure(Abort(.unauthorized))) }
                guard let buffer = response.body else { return completion(.failure(Abort(.unauthorized))) }
                guard let data = String(buffer: buffer).data(using: .utf8) else { return completion(.failure(Abort(.badRequest))) }
                
                do {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                    
                    let data = try decoder.decode(type.self, from: data)
                    completion(.success(data))
                    
                } catch {
                    completion(.failure(Abort(.custom(code: 3, reasonPhrase: "Failed decoding JSON"))))
                }
                
                
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
}
