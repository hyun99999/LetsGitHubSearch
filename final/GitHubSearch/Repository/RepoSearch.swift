import ComposableArchitecture

struct RepoSearch: ReducerProtocol {
    // MARK: 지금 앱은 어떤 상태들로 정의되는가?
  struct State: Equatable {
    var keyword = ""
    var searchResults = [String]()
    var isLoading = false
    var requestCount = 0
  }

  enum Action: Equatable {
      // MARK: 상태들을 변화시키는 사용자의 액션은 무엇인가?
    case keywordChanged(String)
    case search
    case dataLoaded(TaskResult<RepositoryModel>)
  }

  @Dependency(\.repoSearchClient) var repoSearchClient
  @Dependency(\.continuousClock) var clock

  private enum SearchDebounceId {}

    // ✅ EffectTask 는 서버통신을 하거나 데이터를 읽어오는 등 effect task 를 반환해주게 된다.
  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
      // MARK: 각각의 Action이 발생했을 때 상태는 어떻게 변화해야 하는가?
    switch action {
        // 키워드가 변경되면 값을 설정.
    case let .keywordChanged(keyword):
      state.keyword = keyword

      if keyword == "" {
        state.isLoading = false
        state.searchResults = []
        return .cancel(id: SearchDebounceId.self)
      }

      return .run { send in
        try await self.clock.sleep(for: .seconds(0.5))
        await send(.search)
      }
      .cancellable(id: SearchDebounceId.self, cancelInFlight: true)

        // 키워드가 포함된 searchResults 값을 설정.
    case .search:
      state.isLoading = true
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
