import PlaygroundSupport
import UIKit

public protocol ArgumentDelegate {

	func didChangeValue()

}

public class Argument: UIStackView {

	private let labelName = UILabel()
	private let slider = UISlider()
	private let labelValue = UILabel()

	public var delegate: ArgumentDelegate?

	public var value: CGFloat {
		get {
			return CGFloat(self.slider.value)
		}
	}

	public required init(coder: NSCoder) {
		super.init(coder: coder)
	}

	public init(name: String, default defaultValue: Float, minimum minimumValue: Float = 0, maximum maximumValue: Float = 1) {
		super.init(frame: .zero)

		/* self */

		self.spacing = 5

		/* content */

		self.addArrangedSubview(self.labelName)
		self.addArrangedSubview(self.slider)
		self.addArrangedSubview(self.labelValue)

		self.labelName.text = name
		self.labelName.font = UIFont(name: "Courier", size: UIFont.labelFontSize)

		self.slider.minimumValue = minimumValue
		self.slider.maximumValue = maximumValue
		self.slider.value = defaultValue
		self.slider.addTarget(self, action: #selector(onSliderDrag), for: .valueChanged)

		self.labelValue.font = UIFont(name: "Courier", size: UIFont.labelFontSize)

		self.slider.sendActions(for: .valueChanged)
	}

	@objc private func onSliderDrag() {
		self.labelValue.text = String(format: "%05.2f", self.slider.value)

		self.delegate?.didChangeValue()
	}
}

public class Canvas: UIView {

	enum AnimationType: Int {
		case translateX
		case scale
	}

	fileprivate static let size: CGSize = CGSize(width: 600, height: 300)

	private static let contentMargin: CGFloat = 5
	private static let playgroundSizeFactor: CGFloat = 0.5
	private static let squareSize: CGFloat = 50

	private let content = UIStackView()

	private let playgroundWrapper = UIView()
	private let playground = UIView()
	private let square = UIView()

	private var leftSquareConstraint: NSLayoutConstraint?
	private var centerSquareConstraint: NSLayoutConstraint?

	private let animations = UISegmentedControl(items: ["Translate X", "Scale"])

	private let speed = Argument(name: "Speed:", default: 3, minimum: 0.3, maximum: 6)
	private let damping = Argument(name: "Damping:", default: 0.5, minimum: 0.1)
	private let initialVelocityX = Argument(name: "Velocity X:", default: 0, maximum: 10)
	private let initialVelocityY = Argument(name: "Velocity Y:", default: 0, maximum: 10)

	private var forwardsAnimator: UIViewPropertyAnimator?
	private var backwardsAnimator: UIViewPropertyAnimator?

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	public init() {
		super.init(frame: CGRect(x: 0, y: 0, width: Canvas.size.width, height: Canvas.size.height))

		/* self */

		self.backgroundColor = .white

		/* content */

		self.content.translatesAutoresizingMaskIntoConstraints = false
		self.content.axis = .vertical
		self.content.spacing = 10

		self.addSubview(self.content)

		self.content.topAnchor.constraint(equalTo: self.topAnchor, constant: Canvas.contentMargin).isActive = true
		self.content.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -Canvas.contentMargin).isActive = true
		self.content.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Canvas.contentMargin).isActive = true
		self.content.leftAnchor.constraint(equalTo: self.leftAnchor, constant: Canvas.contentMargin).isActive = true

		/* playground wrapper */

		self.content.addArrangedSubview(self.playgroundWrapper)

		/* playground */

		self.playground.translatesAutoresizingMaskIntoConstraints = false
		self.playground.backgroundColor = .lightGray

		self.playgroundWrapper.addSubview(self.playground)

		self.playground.topAnchor.constraint(equalTo: self.playgroundWrapper.topAnchor).isActive = true
		self.playground.centerYAnchor.constraint(equalTo: self.playgroundWrapper.centerYAnchor).isActive = true
		self.playground.centerXAnchor.constraint(equalTo: self.playgroundWrapper.centerXAnchor).isActive = true

		self.playground.widthAnchor.constraint(equalTo: self.playgroundWrapper.widthAnchor, multiplier: Canvas.playgroundSizeFactor).isActive = true

			/* square */

		self.square.translatesAutoresizingMaskIntoConstraints = false
		self.square.backgroundColor = .red

		self.playground.addSubview(self.square)

		self.leftSquareConstraint = self.square.leftAnchor.constraint(equalTo: self.playground.leftAnchor)

		self.leftSquareConstraint?.isActive = true

		self.centerSquareConstraint = self.square.centerXAnchor.constraint(equalTo: self.playground.centerXAnchor)

		self.square.centerYAnchor.constraint(equalTo: self.playground.centerYAnchor).isActive = true

		self.square.widthAnchor.constraint(equalToConstant: Canvas.squareSize).isActive = true
		self.square.heightAnchor.constraint(equalToConstant: Canvas.squareSize).isActive = true

		/* animations */

		self.animations.selectedSegmentIndex = AnimationType.translateX.rawValue

		self.content.addArrangedSubview(self.animations)

		/* arguments */

		self.content.addArrangedSubview(self.speed)
		self.content.addArrangedSubview(self.damping)
		self.content.addArrangedSubview(self.initialVelocityX)
		self.content.addArrangedSubview(self.initialVelocityY)

		self.damping.delegate = self
		self.initialVelocityX.delegate = self
		self.initialVelocityY.delegate = self
	}

	public override func layoutSubviews() {
		super.layoutSubviews()

		self.playground.layoutIfNeeded()

		self.createAnimator()
	}

	private func getCurrentAnimationType() -> AnimationType? {
		return AnimationType(rawValue: self.animations.selectedSegmentIndex)
	}

	private func getCurrentTimingParameters() -> UISpringTimingParameters {
		let initialVelocity = CGVector(dx: self.initialVelocityX.value, dy: self.initialVelocityY.value)

		return UISpringTimingParameters(dampingRatio: self.damping.value, initialVelocity: initialVelocity)
	}

	private func getCurrentAnimator() -> UIViewPropertyAnimator? {
		return self.forwardsAnimator?.isRunning ?? false ? self.forwardsAnimator : self.backwardsAnimator
	}

	private func createAnimator() {
		let duration: TimeInterval = TimeInterval(self.speed.value)
		let timingParameters = self.getCurrentTimingParameters()

		self.forwardsAnimator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)

		self.forwardsAnimator?.addAnimations { [weak self] in
			guard let animationType = self?.getCurrentAnimationType() else {
				return
			}

			switch animationType {
			case .translateX:
				self?.centerSquareConstraint?.isActive = false
				self?.leftSquareConstraint?.isActive = true

				self?.playground.layoutIfNeeded()

				let maximumX = (Canvas.size.width - Canvas.contentMargin * 2) * Canvas.playgroundSizeFactor - Canvas.squareSize

				self?.square.transform = CGAffineTransform(translationX: maximumX, y: 0)
			case .scale:
				self?.leftSquareConstraint?.isActive = false
				self?.centerSquareConstraint?.isActive = true

				self?.playground.layoutIfNeeded()

				let maximumScale: CGFloat = 2

				self?.square.transform = CGAffineTransform(scaleX: maximumScale, y: maximumScale)
			}
		}

		self.forwardsAnimator?.addCompletion({ [weak self] _ in
			self?.backwardsAnimator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)

			self?.backwardsAnimator?.addAnimations { [weak self] in
				self?.square.transform = .identity
			}

			self?.backwardsAnimator?.addCompletion({ [weak self] _ in
				self?.createAnimator()
			})

			self?.backwardsAnimator?.startAnimation()
		})

		self.forwardsAnimator?.startAnimation()
	}

}

extension Canvas: ArgumentDelegate {

	public func didChangeValue() {
		guard let currentAnimator = self.getCurrentAnimator() else {
			return
		}

		let timingParameters = self.getCurrentTimingParameters()

		currentAnimator.pauseAnimation()
		currentAnimator.continueAnimation(withTimingParameters: timingParameters, durationFactor: 0)
	}

}

PlaygroundPage.current.liveView = Canvas()
