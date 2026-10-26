import Foundation

/// The logic behind the wheel, kept free of UIKit so it is easy to test.
/// The wheel has one slice per cuisine that currently has an open restaurant.
struct WheelPicker {

    let restaurants: [Restaurant]

    init(restaurants: [Restaurant]) {
        self.restaurants = restaurants.filter(\.isOpen)
    }

    /// Distinct cuisines of open restaurants, in the order they first appear.
    var cuisines: [String] {
        var seen = Set<String>()
        return restaurants.map(\.cuisine).filter { seen.insert($0).inserted }
    }

    /// A wheel needs at least two slices to be worth spinning.
    var canSpin: Bool {
        cuisines.count >= 2
    }

    func randomCuisineIndex<G: RandomNumberGenerator>(using generator: inout G) -> Int? {
        let count = cuisines.count
        return count == 0 ? nil : Int.random(in: 0..<count, using: &generator)
    }

    func restaurant<G: RandomNumberGenerator>(forCuisine cuisine: String,
                                              using generator: inout G) -> Restaurant? {
        restaurants.filter { $0.cuisine == cuisine }.randomElement(using: &generator)
    }
}
