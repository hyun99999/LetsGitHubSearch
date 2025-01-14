import XCTest

import ComposableArchitecture

@testable import GitHubSearch_final

@MainActor
final class RepositoryTests: XCTestCase {
  func test_user_get_repo_search_results_when_search() async {
   // ✅ 테스트를 위한 Store 는 TestStore 로 생성 가능.
    let store = TestStore(
      initialState: RepoSearch.State(),
      reducer: RepoSearch()
    )

      // ✅ Dependency 사용.
    store.dependencies.repoSearchClient.search = { _ in .mock }
    store.dependencies.continuousClock = ImmediateClock()

    await store.send(.keywordChanged("Swift")) {
      $0.keyword = "Swift"
    }

    await store.receive(.search) {
      $0.isLoading = true
      $0.requestCount = 1
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

    // ✅ workshop 3 테스트 진행.
  func test_request_count_not_changed_when_keyword_cleared_within_debounce_time() async {
    let store = TestStore(
      initialState: RepoSearch.State(),
      reducer: RepoSearch()
    )

    store.dependencies.repoSearchClient.search = { _ in .mock }

    let clock = TestClock()
    store.dependencies.continuousClock = clock

    await store.send(.keywordChanged("Swift")) {
      $0.keyword = "Swift"
    }

    await clock.advance(by: .seconds(0.3))

    await store.send(.keywordChanged("")) {
      $0.keyword = ""
      $0.requestCount = 0
      $0.isLoading = false
      $0.searchResults = []
    }
  }
}
