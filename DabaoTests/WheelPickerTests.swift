import XCTest
@testable import Dabao

@MainActor
final class WheelPickerTests: XCTestCase {

    private func restaurant(_ id: String, cuisine: String, isOpen: Bool = true,
                            fee: Decimal = 2) -> Restaurant {
        Restaurant(id: id, name: id, cuisine: cuisine, rating: 4, deliveryMinutes: 20,
                   deliveryFee: fee, isOpen: isOpen, imageName: "", menu: [])
    }

    func testCuisinesAreDistinctAndOpenOnly() {
        let picker = WheelPicker(restaurants: [
            restaurant("a", cuisine: "Hawker"),
            restaurant("b", cuisine: "Hawker"),
            restaurant("c", cuisine: "Salads", isOpen: false),
            restaurant("d", cuisine: "Desserts")
        ])
        XCTAssertEqual(picker.cuisines, ["Hawker", "Desserts"])
    }

    func testCannotSpinWithFewerThanTwoCuisines() {
        let picker = WheelPicker(restaurants: [restaurant("a", cuisine: "Hawker")])
        XCTAssertFalse(picker.canSpin)
    }

    func testPicksOpenRestaurantOfTheCuisine() {
        let picker = WheelPicker(restaurants: [
            restaurant("closed", cuisine: "Hawker", isOpen: false),
            restaurant("open", cuisine: "Hawker"),
            restaurant("other", cuisine: "Desserts")
        ])
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            XCTAssertEqual(picker.restaurant(forCuisine: "Hawker", using: &generator)?.id, "open")
        }
    }

    func testFreeDeliveryAppliesOnlyToTheRewardRestaurant() {
        let cart = CartStore()
        let wheelPick = restaurant("a", cuisine: "Hawker", fee: 3)
        let other = restaurant("b", cuisine: "Salads", fee: 4)
        let dish = MenuItem(id: "x", name: "X", description: "", price: 5, category: "",
                            isSoldOut: false, isSpicy: false)

        cart.grantFreeDelivery(for: wheelPick)
        cart.add(dish, from: wheelPick)
        XCTAssertEqual(cart.deliveryFee, 0)
        XCTAssertTrue(cart.hasFreeDelivery)

        cart.add(dish, from: other)
        XCTAssertEqual(cart.deliveryFee, 4)

        cart.clear()
        cart.add(dish, from: wheelPick)
        XCTAssertEqual(cart.deliveryFee, 3)
    }
}
