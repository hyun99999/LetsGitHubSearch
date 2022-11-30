import ComposableArchitecture

struct RepoSearch: ReducerProtocol {
  struct State: Equatable {
    var keyword = ""
    var searchResults = [String]()
    var isLoading = false
  }

  enum Action: Equatable {
    case keywordChanged(String)
    case search
      // 데이터를 로드해서 성공, 실패에 대한 액션.
    case dataLoaded(TaskResult<RepositoryModel>)
  }

    // ✅ 의존성 부여.
  @Dependency(\.repoSearchClient) var repoSearchClient

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case let .keywordChanged(keyword):
      state.keyword = keyword
      return .none

    case .search:
      state.isLoading = true
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
