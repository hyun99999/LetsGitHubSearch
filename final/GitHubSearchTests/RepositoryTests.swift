import XCTest

import ComposableArchitecture

@testable import GitHubSearch_final

@MainActor
final class RepositoryTests: XCTestCase {
  func test_user_get_repoSearchResults_when_search() async {
      // ✅ 테스트를 위한 Store 는 TestStore 로 생성 가능.
    let store = TestStore(
      initialState: RepoSearch.State(),
      reducer: RepoSearch()
    )

    await store.send(.keywordChanged("Swift")) {
      $0.keyword = "Swift"
    }

    await store.send(.search) {
      $0.searchResults = [
        "Swift",
        "SwiftyJSON",
        "SwiftGuide",
        "SwiftterSwift",
      ]
    }
  }
}
