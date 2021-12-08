import SwiftUI
import IterableSDK

struct ContentView: View {
  @State
  private var presentingLogin = false
  
  @State
  private var buttonText = "Login"
  
  @State
  private var selectedTab: SelectedTab = .home
  
  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationView {
        CoffeeListView(coffees: Coffee.all)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button(action: login) {
                VStack {
                  Image(systemName: "person.circle")
                  Text(buttonText)
                }
              }
            }
          }
          .navigationTitle("Our Coffees")
      }
      .tabItem {
        Image(systemName: "house")
        Text("Coffees")
      }
      .tag(SelectedTab.home)
      
      NavigationView {
        IterableInboxView()
          .noMessagesTitle("No Messages")
          .noMessagesBody("Please check back later")
      }
      .tabItem {
        Image(systemName: "envelope")
        Text("Inbox")
      }
      .tag(SelectedTab.inbox)
    }
    .onAppear {
      buttonText = (AppModel.shared.email == nil) ? "Login" : "Logout"
    }
    .onReceive(AppModel.shared.$email) { email in
      buttonText = (email == nil) ? "Login" : "Logout"
    }
    .onReceive(AppModel.shared.$selectedTab) { tab in
      selectedTab = tab ?? .home
    }
    .sheet(isPresented: $presentingLogin) {
      LoginView(isPresented: $presentingLogin)
    }
  }
  
  private func login() {
    presentingLogin = true
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
