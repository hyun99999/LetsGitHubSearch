import SwiftUI

import ComposableArchitecture

struct RepoSearchView: View {
    // ✅ Store 형태로 변형하기 위해 StoreOf 사용.
  let store: StoreOf<RepoSearch>

  var body: some View {
      // ✅ Store 을 관찰이 가능하도록 변형.
    WithViewStore(self.store) { viewStore in
        // 이후 viewStore 을 통해서 값과 로직에 접근.
      NavigationView {
        Group {
          Text("\(viewStore.requestCount)")
          Spacer()

          if(viewStore.isLoading) {
            ProgressView()
          } else {
            List {
              ForEach(viewStore.searchResults, id: \.self) { repo in
                Text(repo)
              }
            }
          }

          Spacer()
        }
        .searchable(
          text: Binding(
            get: { viewStore.keyword },
            set: { viewStore.send(.keywordChanged($0)) }
          )
        )
        .navigationTitle("Github Search")
      }
    }
  }
}

struct RepoSearchView_Previews: PreviewProvider {
  static var previews: some View {
    RepoSearchView(
      store: Store(
        initialState: RepoSearch.State(),
        reducer: RepoSearch()
      )
    )
  }
}
