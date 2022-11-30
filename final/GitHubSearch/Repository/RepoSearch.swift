import ComposableArchitecture

struct RepoSearch: ReducerProtocol {
  struct State: Equatable {
    var keyword = ""
    var searchResults = [String]()
    var isLoading = false
      // 요청의 횟수를 저장.
    var requestCount = 0
  }

  enum Action: Equatable {
    case keywordChanged(String)
    case search
    case dataLoaded(TaskResult<RepositoryModel>)
  }

  @Dependency(\.repoSearchClient) var repoSearchClient
  @Dependency(\.continuousClock) var clock

  private enum SearchDebounceId {}

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case let .keywordChanged(keyword):
      state.keyword = keyword

      if keyword == "" {
        state.isLoading = false
        state.searchResults = []
        return .cancel(id: SearchDebounceId.self)
      }

        // ✅ 키워드가 변경되면 .search 즉, 검색할 수 있도록 return 에 담음.
        // 바로 검색이 되지 않고, 마지막 키워드로 검색되도록 2가지 기능 구현.
      return .run { send in
          // 1️⃣ 바로 검색 요청을 보내는 것이 아닌, debounce 를 할 수 있도록 함.
        try await self.clock.sleep(for: .seconds(0.5))
        await send(.search)
      }
        // 2️⃣ 마지막 요청만 전달하도록 함.
      .cancellable(id: SearchDebounceId.self, cancelInFlight: true)

    case .search:
      state.isLoading = true
        // 요청 횟수를 증가.
      state.requestCount += 1
      return Effect.run { [keyword = state.keyword] send in
        let result = await TaskResult { try await repoSearchClient.search(keyword) }
        await send(.dataLoaded(result))
      }

    case let .dataLoaded(.success(repositoryModel)):
      state.isLoading = false
      state.searchResults = repositoryModel.items.map { $0.name }
      return .none

    case .dataLoaded(.failure):
      state.isLoading = false
      state.searchResults = []
      return .none
    }
  }
}
