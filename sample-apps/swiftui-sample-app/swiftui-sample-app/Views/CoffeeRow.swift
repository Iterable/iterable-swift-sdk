import SwiftUI

struct CoffeeRow: View {
  var coffee: Coffee
  
  var body: some View {
    HStack(alignment: .top) {
      coffee.image
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: metrics.thumbnailSize, height: metrics.thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
        .accessibility(hidden: true)
      
      VStack(alignment: .leading) {
        Text(coffee.title)
          .font(.headline)
          .lineLimit(1)
        
        Text(coffee.description)
          .lineLimit(2)
      }
      .padding(.vertical, metrics.textPadding)
      
      Spacer(minLength: 0)
    }
    .font(.subheadline)
    .padding(.vertical, metrics.rowPadding)
    .accessibilityElement(children: .combine)
  }
  
  private var metrics: Metrics {
    return Metrics(thumbnailSize: 96, cornerRadius: 16, rowPadding: 0, textPadding: 8)
  }
  
  struct Metrics {
    var thumbnailSize: CGFloat
    var cornerRadius: CGFloat
    var rowPadding: CGFloat
    var textPadding: CGFloat
  }
}

struct CoffeeRow_Previews: PreviewProvider {
  static var previews: some View {
    CoffeeRow(coffee: Coffee.cappuccino)
  }
}
