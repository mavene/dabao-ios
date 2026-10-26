import UIKit

/// A spinnable wheel with one coloured slice per label. The pointer sits at the top.
final class WheelView: UIView {

    /// Called each time a slice boundary passes the pointer while spinning.
    var onTick: (() -> Void)?

    private let wheelLayerView = UIView()
    private var labels: [String] = []
    private var displayLink: CADisplayLink?
    private var lastSliceIndex: Int?

    private static let palette: [UIColor] = [
        .systemPink, .systemOrange, .systemTeal, .systemIndigo, .systemGreen, .systemPurple
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(wheelLayerView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side = min(bounds.width, bounds.height)
        let currentTransform = wheelLayerView.transform
        wheelLayerView.transform = .identity
        wheelLayerView.frame = CGRect(x: (bounds.width - side) / 2,
                                      y: (bounds.height - side) / 2,
                                      width: side, height: side)
        rebuildSlices()
        wheelLayerView.transform = currentTransform
    }

    func setLabels(_ labels: [String]) {
        self.labels = labels
        wheelLayerView.transform = .identity
        lastSliceIndex = nil
        setNeedsLayout()
    }

    /// Spins so that slice `index` ends under the pointer. Calls `completion` when it stops.
    func spin(to index: Int, animated: Bool, completion: @escaping () -> Void) {
        guard !labels.isEmpty, labels.indices.contains(index) else { return completion() }

        let step = 2 * CGFloat.pi / CGFloat(labels.count)
        let jitter = CGFloat.random(in: -0.35...0.35) * step
        // Slice i is centred at -π/2 + (i + 0.5) * step; rotate that back to the top.
        let target = -(CGFloat(index) + 0.5) * step + jitter
        let finalAngle = target - 2 * .pi * 5

        guard animated else {
            wheelLayerView.transform = CGAffineTransform(rotationAngle: finalAngle)
            return completion()
        }

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = finalAngle
        animation.duration = 4
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.1, 0.7, 0.2, 1)

        wheelLayerView.layer.transform = CATransform3DMakeRotation(finalAngle, 0, 0, 1)
        startTicking()
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.stopTicking()
            completion()
        }
        wheelLayerView.layer.add(animation, forKey: "spin")
        CATransaction.commit()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil { stopTicking() }
    }

    // MARK: Drawing

    private func rebuildSlices() {
        wheelLayerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        wheelLayerView.subviews.forEach { $0.removeFromSuperview() }
        guard !labels.isEmpty else { return }

        let radius = wheelLayerView.bounds.width / 2
        let center = CGPoint(x: radius, y: radius)
        let step = 2 * CGFloat.pi / CGFloat(labels.count)

        for (index, text) in labels.enumerated() {
            let start = -CGFloat.pi / 2 + CGFloat(index) * step
            let path = UIBezierPath(arcCenter: center, radius: radius,
                                    startAngle: start, endAngle: start + step, clockwise: true)
            path.addLine(to: center)
            path.close()

            let slice = CAShapeLayer()
            slice.path = path.cgPath
            slice.fillColor = Self.palette[index % Self.palette.count].cgColor
            slice.strokeColor = UIColor.systemBackground.cgColor
            slice.lineWidth = 2
            wheelLayerView.layer.addSublayer(slice)

            let label = UILabel()
            label.text = text
            label.textColor = .white
            label.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.6
            label.textAlignment = .center
            label.bounds = CGRect(x: 0, y: 0, width: radius * 0.6, height: 24)
            let mid = start + step / 2
            label.center = CGPoint(x: center.x + cos(mid) * radius * 0.6,
                                   y: center.y + sin(mid) * radius * 0.6)
            label.transform = CGAffineTransform(rotationAngle: mid)
            wheelLayerView.addSubview(label)
        }
    }

    // MARK: Ticking

    private func startTicking() {
        stopTicking()
        lastSliceIndex = currentSliceIndex()
        let link = CADisplayLink(target: self, selector: #selector(tickFrame))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopTicking() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tickFrame() {
        let index = currentSliceIndex()
        if index != lastSliceIndex {
            lastSliceIndex = index
            onTick?()
        }
    }

    /// The slice currently under the pointer, read from the in-flight animation.
    private func currentSliceIndex() -> Int? {
        guard !labels.isEmpty,
              let presentation = wheelLayerView.layer.presentation() else { return nil }
        let angle = atan2(presentation.transform.m12, presentation.transform.m11)
        let step = 2 * CGFloat.pi / CGFloat(labels.count)
        var normalized = (-angle).truncatingRemainder(dividingBy: 2 * .pi)
        if normalized < 0 { normalized += 2 * .pi }
        return Int(normalized / step) % labels.count
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
}
