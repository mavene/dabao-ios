import UIKit

final class MenuItemCell: UITableViewCell {

    static let reuseIdentifier = "MenuItemCell"

    var onAdd: (() -> Void)?
    var onRemove: (() -> Void)?

    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let priceLabel = UILabel()
    private let spicyIcon = UIImageView(image: UIImage(systemName: "flame.fill"))
    private let quantityLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let removeButton = UIButton(type: .system)
    private let buttons = UIStackView()

    // Compact: buttons on the right. Accessibility sizes: buttons below the text.
    private var compactConstraints: [NSLayoutConstraint] = []
    private var accessibilityConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.applyLayout()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAdd = nil
        onRemove = nil
    }

    private func setUpViews() {
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.numberOfLines = 0
        detailLabel.font = .preferredFont(forTextStyle: .caption1)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        priceLabel.font = .preferredFont(forTextStyle: .subheadline)
        quantityLabel.font = .preferredFont(forTextStyle: .subheadline)
        [nameLabel, detailLabel, priceLabel, quantityLabel].forEach { $0.adjustsFontForContentSizeCategory = true }
        quantityLabel.textColor = UIColor(named: "AccentColor")
        spicyIcon.tintColor = .systemRed
        spicyIcon.contentMode = .scaleAspectFit
        spicyIcon.isAccessibilityElement = false

        // Symbols sized by a text style scale with Dynamic Type.
        let symbolConfig = UIImage.SymbolConfiguration(textStyle: .title2)
        addButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: symbolConfig), for: .normal)
        removeButton.setImage(UIImage(systemName: "minus.circle", withConfiguration: symbolConfig), for: .normal)
        addButton.addAction(UIAction { [weak self] _ in self?.onAdd?() }, for: .touchUpInside)
        removeButton.addAction(UIAction { [weak self] _ in self?.onRemove?() }, for: .touchUpInside)

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, spicyIcon])
        nameRow.spacing = 4
        nameRow.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [nameRow, detailLabel, priceLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        [removeButton, quantityLabel, addButton].forEach { buttons.addArrangedSubview($0) }
        buttons.spacing = 8
        buttons.alignment = .center

        [textStack, buttons].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            spicyIcon.widthAnchor.constraint(equalToConstant: 14),
            spicyIcon.heightAnchor.constraint(equalToConstant: 14),
            // Keep a comfortable 44pt tap target even when the icons are small.
            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            addButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            removeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            removeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        compactConstraints = [
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: buttons.leadingAnchor, constant: -8),
            buttons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            buttons.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]
        accessibilityConstraints = [
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttons.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 8),
            buttons.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ]
        applyLayout()
    }

    private func applyLayout() {
        let large = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        NSLayoutConstraint.deactivate(large ? compactConstraints : accessibilityConstraints)
        NSLayoutConstraint.activate(large ? accessibilityConstraints : compactConstraints)
    }

    func configure(with row: MenuItemViewModel) {
        nameLabel.text = row.name
        addButton.accessibilityLabel = "Add \(row.name)"
        removeButton.accessibilityLabel = "Remove one \(row.name)"
        spicyIcon.accessibilityLabel = "Spicy"
        quantityLabel.accessibilityLabel = row.quantityText.map { "Quantity \($0.replacingOccurrences(of: "×", with: ""))" }
        detailLabel.text = row.detail
        priceLabel.text = row.priceText
        spicyIcon.isHidden = !row.isSpicy
        quantityLabel.text = row.quantityText
        quantityLabel.isHidden = row.quantityText == nil
        removeButton.isHidden = row.quantityText == nil

        // Sold-out dishes are greyed out.
        contentView.alpha = row.isSoldOut ? 0.4 : 1.0
        addButton.isEnabled = !row.isSoldOut
    }
}
