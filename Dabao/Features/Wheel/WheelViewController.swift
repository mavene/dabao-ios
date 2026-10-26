import UIKit
import AudioToolbox

/// "What should I eat?": spin a wheel of cuisines, then get a restaurant from the winner.
/// Plain MVC like the restaurant list. The picking rules live in `WheelPicker`.
final class WheelViewController: UIViewController {

    /// Called after the sheet is dismissed when the user taps "Order here".
    var onOrder: ((Restaurant) -> Void)?

    private let picker: WheelPicker
    private let wheelView = WheelView()
    private let pointerView = UIImageView(image: UIImage(systemName: "arrowtriangle.down.fill"))
    private let spinButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let resultCard = UIStackView()
    private let resultNameLabel = UILabel()
    private let resultDetailLabel = UILabel()
    private let rewardLabel = UILabel()
    private let orderButton = UIButton(type: .system)
    private let spinAgainButton = UIButton(type: .system)
    private let tickFeedback = UISelectionFeedbackGenerator()

    private var winner: Restaurant?
    private var isSpinning = false

    init(restaurants: [Restaurant]) {
        picker = WheelPicker(restaurants: restaurants)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "What should I eat?"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })

        setUpViews()
        wheelView.setLabels(picker.cuisines)
        wheelView.onTick = { [weak self] in
            self?.tickFeedback.selectionChanged()
            AudioServicesPlaySystemSound(1104)
        }
        updateState(showingResult: false)
    }

    private func setUpViews() {
        wheelView.translatesAutoresizingMaskIntoConstraints = false
        pointerView.translatesAutoresizingMaskIntoConstraints = false
        pointerView.tintColor = .label

        var spinConfig = UIButton.Configuration.filled()
        spinConfig.title = "Spin!"
        spinConfig.cornerStyle = .capsule
        spinButton.configuration = spinConfig
        spinButton.addAction(UIAction { [weak self] _ in self?.spin() }, for: .touchUpInside)

        hintLabel.font = .preferredFont(forTextStyle: .footnote)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0

        resultNameLabel.font = .preferredFont(forTextStyle: .title2).bold()
        resultNameLabel.textAlignment = .center
        resultNameLabel.numberOfLines = 0
        resultDetailLabel.font = .preferredFont(forTextStyle: .subheadline)
        resultDetailLabel.textColor = .secondaryLabel
        resultDetailLabel.textAlignment = .center
        rewardLabel.text = "🎉 Free delivery if you order now"
        rewardLabel.font = .preferredFont(forTextStyle: .footnote).bold()
        rewardLabel.textColor = .systemGreen
        rewardLabel.textAlignment = .center

        var orderConfig = UIButton.Configuration.filled()
        orderConfig.title = "Order here"
        orderConfig.cornerStyle = .capsule
        orderButton.configuration = orderConfig
        orderButton.addAction(UIAction { [weak self] _ in self?.orderTapped() }, for: .touchUpInside)

        var againConfig = UIButton.Configuration.tinted()
        againConfig.title = "Spin again"
        againConfig.cornerStyle = .capsule
        spinAgainButton.configuration = againConfig
        spinAgainButton.addAction(UIAction { [weak self] _ in self?.spin() }, for: .touchUpInside)

        resultCard.axis = .vertical
        resultCard.spacing = 8
        resultCard.translatesAutoresizingMaskIntoConstraints = false
        [resultNameLabel, resultDetailLabel, rewardLabel, orderButton, spinAgainButton]
            .forEach(resultCard.addArrangedSubview)

        let bottomStack = UIStackView(arrangedSubviews: [spinButton, hintLabel, resultCard])
        bottomStack.axis = .vertical
        bottomStack.spacing = 12
        bottomStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(wheelView)
        view.addSubview(pointerView)
        view.addSubview(bottomStack)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            pointerView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            pointerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pointerView.widthAnchor.constraint(equalToConstant: 28),
            pointerView.heightAnchor.constraint(equalToConstant: 24),

            wheelView.topAnchor.constraint(equalTo: pointerView.bottomAnchor, constant: 4),
            wheelView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            wheelView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24),
            wheelView.heightAnchor.constraint(equalTo: wheelView.widthAnchor),

            bottomStack.topAnchor.constraint(equalTo: wheelView.bottomAnchor, constant: 20),
            bottomStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            bottomStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24)
        ])
    }

    private func updateState(showingResult: Bool) {
        resultCard.isHidden = !showingResult
        spinButton.isHidden = showingResult
        hintLabel.isHidden = showingResult
        spinButton.isEnabled = picker.canSpin && !isSpinning
        hintLabel.text = picker.canSpin
            ? "Spin to pick a cuisine, then we'll choose a restaurant for you."
            : "Not enough open restaurants to spin right now."
    }

    private func spin() {
        guard picker.canSpin, !isSpinning else { return }
        var generator = SystemRandomNumberGenerator()
        guard let index = picker.randomCuisineIndex(using: &generator) else { return }
        let cuisine = picker.cuisines[index]
        guard let pick = picker.restaurant(forCuisine: cuisine, using: &generator) else { return }

        isSpinning = true
        resultCard.isHidden = true
        spinButton.isHidden = false
        hintLabel.isHidden = false
        spinButton.isEnabled = false
        tickFeedback.prepare()

        let animated = !UIAccessibility.isReduceMotionEnabled
        wheelView.spin(to: index, animated: animated) { [weak self] in
            self?.finishSpin(with: pick)
        }
    }

    private func finishSpin(with restaurant: Restaurant) {
        isSpinning = false
        winner = restaurant
        resultNameLabel.text = restaurant.name
        resultDetailLabel.text = "\(restaurant.cuisine) · \(restaurant.deliveryMinutes) min"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1025)
        updateState(showingResult: true)
    }

    private func orderTapped() {
        guard let winner else { return }
        let onOrder = onOrder
        dismiss(animated: true) { onOrder?(winner) }
    }
}

private extension UIFont {
    func bold() -> UIFont {
        UIFont.systemFont(ofSize: pointSize, weight: .bold)
    }
}
