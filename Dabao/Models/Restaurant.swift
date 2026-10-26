import Foundation

/// A restaurant on Dabao. Loaded from `restaurants.json`.
nonisolated struct Restaurant: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let cuisine: String
    let rating: Double
    let deliveryMinutes: Int
    let deliveryFee: Decimal
    let isOpen: Bool
    let imageName: String
    let menu: [MenuItem]
}
