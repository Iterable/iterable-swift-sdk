import SwiftUI

struct CoffeeView: View {
  var coffee: Coffee
  
  var body: some View {
    VStack {
      coffee.image
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: metrics.thumbnailSize, height: metrics.thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
        .accessibility(hidden: true)
        .padding()
      Text(coffee.description)
        .font(.title3)
      Button(action: {}) {
        Label("Buy", systemImage: "hand.thumbsup")
          .padding()
          .font(.title)
      }
    }
    .onAppear {
      AppModel.shared.selectedCoffee = coffee
    }
    .navigationTitle(coffee.title)
  }
  
  private var metrics: Metrics {
    return Metrics(thumbnailSize: 196, cornerRadius: 16, rowPadding: 0, textPadding: 8)
  }
  
  struct Metrics {
    var thumbnailSize: CGFloat
    var cornerRadius: CGFloat
    var rowPadding: CGFloat
    var textPadding: CGFloat
  }
}

struct CoffeeView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      CoffeeView(coffee: .latte)
    }
  }
}
