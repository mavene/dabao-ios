import UIKit

final class RestaurantCell: UITableViewCell {

    static let reuseIdentifier = "RestaurantCell"

    private let photoView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let starsStack = UIStackView()
    private let statusLabel = UILabel()
    private let statusDot = UIView()
    private let statusStack = UIStackView()
    private let ratingLabel = UILabel()
    private let ratingRow = UIStackView()   // accessibility sizes: rating on the left, status on the right
    private let textStack = UIStackView()
    private var restaurant: Restaurant?

    // Layout sets: compact (photo left, status right) vs. accessibility sizes (text only, full width).
    private var compactConstraints: [NSLayoutConstraint] = []
    private var accessibilityConstraints: [NSLayoutConstraint] = []   // shared by both large variants
    private var largeStatusRightConstraints: [NSLayoutConstraint] = [] // status stays at the right edge
    private var dotWidth: NSLayoutConstraint!
    private var dotHeight: NSLayoutConstraint!

    private var usesAccessibilityLayout: Bool {
        traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.applyLayout()
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusStyleChanged),
                                               name: UIAccessibility.differentiateWithoutColorDidChangeNotification,
                                               object: nil)
    }

    @objc private func statusStyleChanged() {
        applyLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        photoView.contentMode = .scaleAspectFit
        photoView.tintColor = UIColor(named: "AccentColor")
        photoView.backgroundColor = .secondarySystemBackground
        photoView.layer.cornerRadius = 12
        photoView.clipsToBounds = true

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 0
        detailLabel.font = .preferredFont(forTextStyle: .footnote)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 0
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusDot.layer.cornerRadius = 5
        statusDot.setContentHuggingPriority(.required, for: .horizontal)
        statusStack.axis = .horizontal
        statusStack.alignment = .center
        statusStack.addArrangedSubview(statusDot)
        statusStack.addArrangedSubview(statusLabel)

        ratingLabel.font = .preferredFont(forTextStyle: .footnote)
        ratingLabel.adjustsFontForContentSizeCategory = true
        ratingLabel.numberOfLines = 0

        starsStack.axis = .horizontal
        starsStack.spacing = 2

        ratingRow.axis = .horizontal
        ratingRow.alignment = .center
        ratingRow.spacing = 8
        ratingLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        ratingRow.addArrangedSubview(ratingLabel)

        [nameLabel, detailLabel, ratingRow, starsStack].forEach { textStack.addArrangedSubview($0) }
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        [photoView, textStack, statusStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        // Always on.
        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
        dotWidth = statusDot.widthAnchor.constraint(equalToConstant: 10)
        dotHeight = statusDot.heightAnchor.constraint(equalToConstant: 10)
        NSLayoutConstraint.activate([dotWidth, dotHeight])

        compactConstraints = [
            photoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoView.widthAnchor.constraint(equalToConstant: 64),
            photoView.heightAnchor.constraint(equalToConstant: 64),
            photoView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            photoView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            textStack.leadingAnchor.constraint(equalTo: photoView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: statusStack.leadingAnchor, constant: -8),

            statusStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]
        accessibilityConstraints = [
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        ]
        largeStatusRightConstraints = [
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            ratingRow.widthAnchor.constraint(equalTo: textStack.widthAnchor)
        ]
        applyLayout()
    }

    /// At accessibility text sizes the photo and stars are decorative and eat the width,
    /// so drop them and give the text the whole row width. The rating and status share the
    /// last line, with the status at the right edge, larger: a bigger dot, or (Differentiate Without Color on) a bigger icon without the word,
    /// since the word would squeeze the text. VoiceOver still reads Open or Closed.
    private func applyLayout() {
        let large = usesAccessibilityLayout

        // Reparent first; removing a view from its superview drops its constraints.
        NSLayoutConstraint.deactivate(compactConstraints + accessibilityConstraints
                                      + largeStatusRightConstraints)
        if large {
            ratingRow.addArrangedSubview(statusStack)
        } else {
            contentView.addSubview(statusStack)
        }

        if !large {
            NSLayoutConstraint.activate(compactConstraints)
        } else {
            NSLayoutConstraint.activate(accessibilityConstraints)
            NSLayoutConstraint.activate(largeStatusRightConstraints)
        }

        photoView.isHidden = large
        starsStack.isHidden = large
        ratingRow.isHidden = !large

        let dotSize: CGFloat = large ? 16 : 10
        dotWidth.constant = dotSize
        dotHeight.constant = dotSize
        statusDot.layer.cornerRadius = dotSize / 2

        if let restaurant { updateStatus(for: restaurant) }
    }

    func configure(with restaurant: Restaurant) {
        photoView.image = UIImage(systemName: restaurant.imageName)
        nameLabel.text = restaurant.name
        detailLabel.text = "\(restaurant.cuisine) · \(restaurant.deliveryMinutes) min · \(PriceFormatter.string(from: restaurant.deliveryFee)) delivery"

        ratingLabel.text = "★ \(String(format: "%.1f", restaurant.rating)) rating"

        starsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let fullStars = Int(restaurant.rating.rounded())
        for index in 0..<5 {
            let star = UIImageView(image: UIImage(systemName: index < fullStars ? "star.fill" : "star"))
            star.tintColor = .systemOrange
            starsStack.addArrangedSubview(star)
        }

        self.restaurant = restaurant
        updateStatus(for: restaurant)

        // One VoiceOver element per row, including open/closed and rating.
        let statusText = restaurant.isOpen ? "Open" : "Closed"
        let rating = String(format: "%.1f", restaurant.rating)
        isAccessibilityElement = true
        accessibilityLabel = "\(restaurant.name), \(statusText), \(restaurant.cuisine), rated \(rating) out of 5, \(restaurant.deliveryMinutes) minutes"
        accessibilityValue = "\(PriceFormatter.string(from: restaurant.deliveryFee)) delivery"
    }

    /// With "Differentiate Without Color" off: a plain colored dot on the right.
    /// With it on: a distinct icon plus the word "Open" or "Closed", also on the right.
    private func updateStatus(for restaurant: Restaurant) {
        let color: UIColor = restaurant.isOpen ? .systemGreen : .systemRed
        let differentiate = UIAccessibility.shouldDifferentiateWithoutColor
        statusDot.isHidden = differentiate
        statusLabel.isHidden = !differentiate
        statusDot.backgroundColor = color

        let statusText = restaurant.isOpen ? "Open" : "Closed"
        let symbol = restaurant.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill"
        let attachment = NSTextAttachment(image: UIImage(systemName: symbol)!.withTintColor(color))
        let text = NSMutableAttributedString(attachment: attachment)
        if usesAccessibilityLayout {
            statusLabel.font = .preferredFont(forTextStyle: .title2)   // icon only, bigger
        } else {
            statusLabel.font = .preferredFont(forTextStyle: .footnote)
            text.append(NSAttributedString(string: " \(statusText)"))
        }
        statusLabel.attributedText = text
        statusLabel.textColor = .label
    }
}
