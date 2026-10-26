import UIKit

/// The Cart tab. Plain MVC: the view controller reads straight from CartStore.
final class CartViewController: UIViewController {

    private let cart: CartStore
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()
    private let checkoutButton = UIButton(type: .system)

    init(cart: CartStore = .shared) {
        self.cart = cart
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cart"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        setUpTableView()
        setUpEmptyLabel()
        setUpCheckoutButton()
        refresh()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: CartStore.didChangeNotification,
                                               object: nil)
    }

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LineCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpEmptyLabel() {
        emptyLabel.text = "Your cart is empty.\nLet's find something tasty!"
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setUpCheckoutButton() {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = UIColor(named: "AccentColor")
        config.title = "Place order"
        checkoutButton.configuration = config
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        checkoutButton.addAction(UIAction { [weak self] _ in self?.placeOrder() }, for: .touchUpInside)
        view.addSubview(checkoutButton)
        NSLayoutConstraint.activate([
            checkoutButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            checkoutButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            checkoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            checkoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        tableView.contentInset.bottom = 74
    }

    @objc private func refresh() {
        let isEmpty = cart.lines.isEmpty
        emptyLabel.isHidden = !isEmpty
        checkoutButton.isHidden = isEmpty
        tableView.isHidden = isEmpty
        tableView.reloadData()
    }

    private func placeOrder() {
        let total = PriceFormatter.string(from: cart.total)
        let alert = UIAlertController(title: "Order placed!",
                                      message: "We've charged \(total). Your food is on the way (not really, this is a demo).",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yay", style: .default) { [weak self] _ in
            self?.cart.clear()
        })
        present(alert, animated: true)
    }
}

extension CartViewController: UITableViewDataSource, UITableViewDelegate {

    // Section 0: one row per dish. Section 1: subtotal, delivery and total.
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? cart.restaurant?.name : "Summary"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? cart.lines.count : 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LineCell", for: indexPath)
        var content = UIListContentConfiguration.valueCell()

        if indexPath.section == 0 {
            let line = cart.lines[indexPath.row]
            content.text = "\(line.quantity) × \(line.item.name)"
            content.secondaryText = PriceFormatter.string(from: line.subtotal)
        } else {
            switch indexPath.row {
            case 0:
                content.text = "Subtotal"
                content.secondaryText = PriceFormatter.string(from: cart.subtotal)
            case 1:
                content.text = "Delivery"
                content.secondaryText = cart.hasFreeDelivery
                    ? "Free (wheel reward)"
                    : PriceFormatter.string(from: cart.deliveryFee)
            default:
                content.text = "Total"
                content.secondaryText = PriceFormatter.string(from: cart.total)
                content.textProperties.font = .preferredFont(forTextStyle: .headline)
            }
        }
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0 else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            self?.cart.removeLine(at: indexPath.row)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
