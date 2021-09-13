import SwiftUI

struct CoffeeListView: View {
  var coffees: [Coffee]
  
  @State
  private var selection: Coffee?
  
  var body: some View {
    List {
      ForEach(coffees) { coffee in
        NavigationLink(
          destination: CoffeeView(coffee: coffee),
          tag: coffee,
          selection: $selection) {
            CoffeeRow(coffee: coffee)
        }
      }
      .tag(selection)
    }
    .onReceive(AppModel.shared.$selectedCoffee) { selectedCoffee in
      selection = selectedCoffee
    }
  }
}

struct CoffeeListView_Previews: PreviewProvider {
  static var previews: some View {
    CoffeeListView(coffees: Coffee.all)
  }
}
