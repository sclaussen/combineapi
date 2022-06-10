import Foundation
import Combine

class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    private var cancellable: AnyCancellable?
    private var message: String = ""

    init() {
        getPosts()
    }

    func getPosts() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }

        // 1. dataTaskPublisher: creates the publisher
        // 2. subscribe: put the publisher on the background thread (dataTaskPublisher happens to auto bg)
        // 3. receive: get the published data on the main thread
        // 4. tryMap: verify a good response
        // 5. decode: decode the data
        // 6. sink: store the decoded data
        // 7. store: so the subscription can be cancelled
        cancellable = URLSession.shared
          .dataTaskPublisher(for: url)
          .subscribe(on: DispatchQueue.global(qos: .background))
          .receive(on: DispatchQueue.main)
          .tryMap(verifyStatusCodeAndGetPayload)
          .decode(type: [Post].self, decoder: JSONDecoder())
          .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.message = error.localizedDescription
                    }
                }, receiveValue: { [weak self] (returnedPosts) in
                       self?.posts = returnedPosts
                   })
    }

    func verifyStatusCodeAndGetPayload(output: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard let response = output.response as? HTTPURLResponse,
              response.statusCode >= 200 && response.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
        return output.data
    }
}
