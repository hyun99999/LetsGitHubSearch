import XCTest

import ComposableArchitecture

@testable import GitHubSearch_final

@MainActor
final class RepositoryTests: XCTestCase {
  func test_user_get_repoSearchResults_when_search() async {
    let store = TestStore(
      initialState: RepoSearch.State(),
      reducer: RepoSearch()
    )

      // ✅ Dependency 사용.
    store.dependencies.repoSearchClient.search = { _ in .mock }

    await store.send(.keywordChanged("Swift")) {
      $0.keyword = "Swift"
    }

    await store.send(.search) {
      $0.isLoading = true
    }

      // mock 데이터를 가지고 성공에 대한 테스트 진행.
    await store.receive(.dataLoaded(.success(.mock))) {
      $0.isLoading = false
      $0.searchResults = [
        "Swift",
        "SwiftyJSON",
        "SwiftGuide",
        "SwiftterSwift",
      ]
    }
  }
}
