import ComposableArchitecture

struct RepoSearch: ReducerProtocol {
    // MARK: 지금 앱은 어떤 상태들로 정의되는가?
  struct State: Equatable {
    var keyword = ""
    var searchResults = [String]()
  }

  enum Action: Equatable {
      // MARK: 상태들을 변화시키는 사용자의 액션은 무엇인가?
    case keywordChanged(String)
    case search
  }

    // ✅ EffectTask 는 서버통신을 하거나 데이터를 읽어오는 등 effect task 를 반환해주게 된다.
    // 현재는 없기 때문에 none.
  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
      // MARK: 각각의 Action이 발생했을 때 상태는 어떻게 변화해야 하는가?
    switch action {
        // 키워드가 변경되면 값을 설정.
    case let .keywordChanged(keyword):
      state.keyword = keyword
      return .none

        // 키워드가 포함된 searchResults 값을 설정.
    case .search:
        // 현재는 서버통신이 아닌 sampleRepoLIsts 에서 필터링.
      state.searchResults = self.sampleRepoLists.filter {
        $0.contains(state.keyword)
      }
      return .none
    }
  }

  private let sampleRepoLists = [
    "Swift",
    "SwiftyJSON",
    "SwiftGuide",
    "SwiftterSwift",
  ]
}
