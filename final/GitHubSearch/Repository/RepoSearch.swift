import ComposableArchitecture

struct RepoSearch: ReducerProtocol {
    // MARK: 지금 앱은 어떤 상태들로 정의되는가?
  struct State: Equatable {
    var keyword = ""
    var searchResults = [String]()
    var isLoading = false
      // 요청의 횟수를 저장.
    var requestCount = 0
  }

  enum Action: Equatable {
      // MARK: 상태들을 변화시키는 사용자의 액션은 무엇인가?
    case keywordChanged(String)
    case search
      // 데이터를 로드해서 성공, 실패에 대한 액션.
    case dataLoaded(TaskResult<RepositoryModel>)
  }

    // ✅ 의존성 부여.
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

        // ✅ 키워드가 변경되면 .search 즉, 검색할 수 있도록 return 에 담음.
        // 바로 검색이 되지 않고, 마지막 키워드로 검색되도록 2가지 기능 구현.
      return .run { send in
          // 1️⃣ 바로 검색 요청을 보내는 것이 아닌, debounce 를 할 수 있도록 함.
        try await self.clock.sleep(for: .seconds(0.5))
        await send(.search)
      }
        // 2️⃣ 마지막 요청만 전달하도록 함.
      .cancellable(id: SearchDebounceId.self, cancelInFlight: true)

        // 키워드가 포함된 searchResults 값을 설정.
    case .search:
      state.isLoading = true
        // 요청 횟수를 증가.
      state.requestCount += 1
      return Effect.run { [keyword = state.keyword] send in
        let result = await TaskResult { try await repoSearchClient.search(keyword) }
        await send(.dataLoaded(result))
      }

        // 성공 시
    case let .dataLoaded(.success(repositoryModel)):
      state.isLoading = false
      state.searchResults = repositoryModel.items.map { $0.name }
      return .none

        // 실패 시
    case .dataLoaded(.failure):
      state.isLoading = false
      state.searchResults = []
      return .none
    }
  }
}
