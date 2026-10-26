import Foundation

/// One dish on a restaurant's menu.
nonisolated struct MenuItem: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Decimal
    let category: String
    let isSoldOut: Bool
    let isSpicy: Bool
}

/// A line in the cart: which dish, and how many.
struct CartLine: Hashable {
    let item: MenuItem
    var quantity: Int

    var subtotal: Decimal {
        item.price * Decimal(quantity)
    }
}
