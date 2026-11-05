import Foundation

@MainActor
final class RestaurantInfoPresenter: RestaurantInfoPresenterProtocol, RestaurantInfoInteractorOutputProtocol {

    weak var view: RestaurantInfoViewProtocol?
    private let interactor: RestaurantInfoInteractorInputProtocol
    private let router: RestaurantInfoRouterProtocol

    init(view: RestaurantInfoViewProtocol,
         interactor: RestaurantInfoInteractorInputProtocol,
         router: RestaurantInfoRouterProtocol) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    // Opt out of the main-actor deinit hop, which crashes in the back-deployed
    // runtime shim (deployment target < iOS 18.4).
    nonisolated deinit {}

    func viewDidLoad() {
        interactor.loadFacts()
    }

    func didTapDone() {
        router.close()
    }

    func didLoadFacts(_ facts: RestaurantFacts) {
        // MARK: TODO 3 - Tell the view the title and the rows to show. (DONE)
        view?.showTitle(facts.name)
        view?.showRows(makeRows(from: facts))
    }

    func makeRows(from facts: RestaurantFacts) -> [InfoRowViewModel] {
        // MARK: TODO 4 - Turn the facts into rows of text. The tests in
        // RestaurantInfoPresenterTests show some of the rows we expect, e.g.
        // "Status" / "Closed", and "Menu" / "6 dishes (1 sold out today)". (DONE).
        
        // format the strings
        let dishes = facts.dishCount == 1 ? "1 dish" : "\(facts.dishCount) dishes"
        let soldOut = facts.soldOutCount == 0 ? "" : " (\(facts.soldOutCount) sold out today)"
        // use the info row view model to display facts (title and value)
        return [
            InfoRowViewModel(title: "Cuisine", value: facts.cuisine),
            InfoRowViewModel(title: "Rating", value: "★ " + String(format: "%.1f", facts.rating)),
            InfoRowViewModel(title: "Delivery time", value: "About \(facts.deliveryMinutes) min"),
            InfoRowViewModel(title: "Delivery fee", value: PriceFormatter.string(from: facts.deliveryFee)),
            InfoRowViewModel(title: "Status", value: facts.isOpen ? "Open now" : "Closed"),
            InfoRowViewModel(title: "Menu", value: dishes + soldOut),
            InfoRowViewModel(title: "Spicy dishes", value: "\(facts.spicyCount)")
        ]
    }
}
