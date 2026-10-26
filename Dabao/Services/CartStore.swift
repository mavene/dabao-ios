import Foundation

/// Holds what's in the cart. One shared cart for the whole app.
///
/// Screens that care about the cart (the Menu and the Cart tab) listen for
/// `CartStore.didChangeNotification` so they can refresh.
@MainActor
final class CartStore {

    static let shared = CartStore()
    static let didChangeNotification = Notification.Name("CartStoreDidChange")

    /// The most of any one dish we let someone order.
    static let maxQuantityPerItem = 10

    private(set) var restaurant: Restaurant?
    private(set) var lines: [CartLine] = []

    /// Set by the wheel: delivery is free while ordering from this restaurant.
    private(set) var freeDeliveryRestaurantID: String?

    var itemCount: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Decimal {
        lines.reduce(0) { $0 + $1.subtotal }
    }

    var deliveryFee: Decimal {
        guard let restaurant, restaurant.id != freeDeliveryRestaurantID else { return 0 }
        return restaurant.deliveryFee
    }

    var hasFreeDelivery: Bool {
        restaurant != nil && restaurant?.id == freeDeliveryRestaurantID
    }

    func grantFreeDelivery(for restaurant: Restaurant) {
        freeDeliveryRestaurantID = restaurant.id
        notifyChange()
    }

    var total: Decimal {
        subtotal + deliveryFee
    }

    func quantity(of item: MenuItem) -> Int {
        lines.first(where: { $0.item.id == item.id })?.quantity ?? 0
    }

    /// Adds one of `item`. Returns false if we couldn't (sold out, or at the limit).
    @discardableResult
    func add(_ item: MenuItem, from restaurant: Restaurant) -> Bool {
        guard !item.isSoldOut else { return false }

        // A cart can only hold food from one restaurant at a time.
        if self.restaurant?.id != restaurant.id {
            lines.removeAll()
            self.restaurant = restaurant
        }

        if let index = lines.firstIndex(where: { $0.item.id == item.id }) {
            guard lines[index].quantity < CartStore.maxQuantityPerItem else { return false }
            lines[index].quantity += 1
        } else {
            lines.append(CartLine(item: item, quantity: 1))
        }
        notifyChange()
        return true
    }

    func remove(_ item: MenuItem) {
        guard let index = lines.firstIndex(where: { $0.item.id == item.id }) else { return }
        lines[index].quantity -= 1
        if lines[index].quantity == 0 {
            lines.remove(at: index)
        }
        if lines.isEmpty {
            restaurant = nil
        }
        notifyChange()
    }

    func removeLine(at index: Int) {
        lines.remove(at: index)
        if lines.isEmpty {
            restaurant = nil
        }
        notifyChange()
    }

    func clear() {
        lines.removeAll()
        restaurant = nil
        freeDeliveryRestaurantID = nil
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: CartStore.didChangeNotification, object: self)
    }
}
