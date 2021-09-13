import SwiftUI

struct ContentView: View {
  @State
  private var presentingLogin = false
  
  @State
  private var buttonText = "Login"
  
  var body: some View {
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
    .onAppear {
      buttonText = (AppModel.shared.email == nil) ? "Login" : "Logout"
    }
    .onReceive(AppModel.shared.$email) { email in
      buttonText = (email == nil) ? "Login" : "Logout"
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
