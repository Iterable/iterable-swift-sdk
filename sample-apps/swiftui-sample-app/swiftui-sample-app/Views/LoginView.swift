import SwiftUI

struct LoginView: View {
  @Binding
  var isPresented: Bool
  
  @State
  private var email = ""
  
  @State
  private var alertIsShowing = false
  
  private var navigationTitle: String {
    (AppModel.shared.email == nil) ? "Login" : "Logout"
  }
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("\n")) {
          VStack(alignment: .leading) {
            if AppModel.shared.email == nil {
              TextField("user@example.com", text: $email)
                .textContentType(.emailAddress)
                .disableAutocorrection(true)
                .autocapitalization(.none)
              Spacer(minLength: 20)
              Button(action: login) {
                Text("Login")
              }
            } else {
              Text(email)
              Spacer(minLength: 20)
              Button(action: logout ) {
                Text("Logout")
              }
            }
          }
          .padding()
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            isPresented = false
          }
        }
      }
      .navigationTitle(navigationTitle)
    }
    .alert(isPresented: $alertIsShowing) {
      Alert(title: Text("Email is required"), message: Text("Please enter your email"), dismissButton: .default(Text("OK")))
    }
    .onAppear {
      email = AppModel.shared.email ?? ""
    }
  }
  
  private func login() {
    guard !email.isEmpty else {
      alertIsShowing = true
      return
    }
    IterableHelper.login(email: email)
    AppModel.shared.email = email
    isPresented = false
  }
  
  private func logout() {
    IterableHelper.logout()
    AppModel.shared.email = nil
    isPresented = false
  }
}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      LoginView(isPresented: .constant(true))
    }
  }
}
