//
//  RadioFrequencyView.swift
//  RadioFrequencyView
//
//  Created by Ivailo Kanev on 23/09/22.
//

import UIKit
public protocol RadioFrequencyDelegate: AnyObject {
    func frequency(view: RadioFrequencyView, didChange value: CGFloat)
}

@IBDesignable
public class RadioFrequencyView: UIControl {
    public weak var delegate: RadioFrequencyDelegate?
    public enum Preset {
        case am
        case fm
    }
    public enum LabelFormat {
        case int
        case decimal
    }
    public var preset: Preset = .fm {
        didSet {
            switch preset {
            case .fm:
                labelFormat = .decimal
                startFrequency = 76
                endFrequency = 108
                stepFrequency = 0.05
            case .am:
                labelFormat = .int
                startFrequency = 153
                endFrequency = 1710
                stepFrequency = 1
            }
            refresh()
        }
    }
    public var labelFormat: LabelFormat = .decimal
    public var startFrequency: CGFloat = 76
    public var endFrequency: CGFloat = 108
    public var getFrequency: CGFloat {
        frequency
    }
    private(set) var frequency: CGFloat = 76 {
        didSet {
            frequency = max(min(frequency, endFrequency), startFrequency)
            update()
        }
    }
    public var stepFrequency: CGFloat = 0.1
    public var distanceFrequency: CGFloat = 6
    public var intermediateFrequencyColor: UIColor = .gray
    public var mainMargin: CGFloat = 16
    public var intermediateMargin: CGFloat = 26
    public var labelMargin: CGFloat = 4
    public var labelColor: UIColor = .black
    public var mainFrequencyColor: UIColor = .black
    public var indicatorMargin: CGFloat = 10
    public var indicatorColor: UIColor = .red
    public var labelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    public var labelCurrentFont = UIFont.systemFont(ofSize: 14, weight: .bold)
    @IBInspectable
    public var leftButtonImage: UIImage? {
        didSet {
            leftButton.setImage(leftButtonImage, for: .normal)
        }
    }
    @IBInspectable
    public var rightButtonImage: UIImage? {
        didSet {
            rightButton.setImage(rightButtonImage, for: .normal)
        }
    }
    @IBInspectable
    public var leftShadowImage: UIImage? {
        didSet {
            leftShadow.image = leftShadowImage
        }
    }
    @IBInspectable
    public var rightShadowImage: UIImage? {
        didSet {
            rightShadow.image = rightShadowImage
        }
    }
    @IBInspectable
    public var isInteractionScrollEnabled: Bool = false {
        didSet {
            scrollView.isUserInteractionEnabled = isInteractionScrollEnabled
        }
    }
    lazy var scrollView = UIScrollView(frame: .null)
    lazy var frequenciesView = UIStackView(frame: .null)
    lazy var indicatorView = UIStackView(frame: .null)
    lazy var leftButton = UIButton(frame: .null)
    lazy var rightButton = UIButton(frame: .null)
    lazy var leftShadow = UIImageView(frame: .null)
    lazy var rightShadow = UIImageView(frame: .null)
    lazy var fake = FrequencyDrawView(frame: .null)
    
    private var frequenciesCount: Int {
        return Int((endFrequency - startFrequency) / stepFrequency * distanceFrequency)
    }
    private var notifyDelegate = true
    private var tempView: UIView?
    private weak var displayLink: CADisplayLink?
    private var fakeWidth: NSLayoutConstraint?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentInset = UIEdgeInsets(top: 0, left: bounds.width/2 - fake.firstOffset, bottom: 0, right: bounds.width/2 - fake.firstOffset)
        notifyDelegate = false
        update(animated: false)
        notifyDelegate = true
    }
    public func setFrequency(_ value: CGFloat) {
        notifyDelegate = false
        frequency = value
        notifyDelegate = true
    }
    public func refresh() {
        buildFrequency()
        frequency = startFrequency
    }
    func update(animated: Bool = true) {
        var startPostion = (frequency - startFrequency) / stepFrequency  * distanceFrequency
        startPostion = startPostion + ((frequency - startFrequency) / stepFrequency)
        scrollView.setContentOffset(CGPoint(x: startPostion - scrollView.contentInset.left, y: 0), animated: animated)
        if notifyDelegate {
            delegate?.frequency(view: self, didChange: frequency)
        }
    }
    public override func prepareForInterfaceBuilder() {
        setup()
    }
}

extension RadioFrequencyView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isDecelerating, !scrollView.isDragging, !scrollView.isTracking {
            let position = scrollView.contentOffset.x + scrollView.contentInset.left

            let current = Int(( position / (distanceFrequency + 1) ).rounded())
            
            if fake.currentIndex != current, current % 5 == 0 || fake.currentIndex % 5 == 0 {
                fake.currentIndex = current
                createDisplayLink()
            }
            
            print(current%5, current)
            
        }
//        print(scrollView.isDecelerating, scrollView.isDragging, scrollView.isTracking)
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        frequency = recalcCurrent(scrollView)
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else {return}
        
        frequency = recalcCurrent(scrollView)
    }
}

private extension RadioFrequencyView {
    func setup() {
        guard subviews.isEmpty else { return }
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        
        
        scrollView.addSubview(fake)
        fake.translatesAutoresizingMaskIntoConstraints = false
        fake.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        let right = fake.rightAnchor.constraint(equalTo: scrollView.rightAnchor)
        right.priority = .defaultLow
        
        right.isActive = true
        fake.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        fake.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        let width = fake.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        width.priority = .defaultLow
        width.isActive = true
        fake.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        fakeWidth = fake.widthAnchor.constraint(equalToConstant: CGFloat(frequenciesCount) * distanceFrequency)
        fakeWidth?.isActive = true
        fake.closureUpdate = ({
            self.buildOverlay()
        })
        buildFrequency()
        
    }
    func createDisplayLink() {
        displayLink?.invalidate() // cancel prior one, if any
        
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink.add(to: .main, forMode: .default)
        self.displayLink = displayLink
    }

    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        fake.setNeedsDisplay()
        displayLink.invalidate()
    }
    func recalcCurrent(_ scrollView: UIScrollView) -> CGFloat {
        let position = scrollView.contentOffset.x + scrollView.contentInset.left
        let format = labelFormat == .decimal ? "%.1f" : "%.0f"
        let current = String(format: format, position / (distanceFrequency + 1) * stepFrequency + startFrequency)
        return CGFloat(Float(current) ?? 0)
    }
    @objc func leftPressed() {
        frequency = max(startFrequency, frequency - stepFrequency)

    }
    @objc func rightPressed() {
        frequency = min(endFrequency, frequency + stepFrequency)
    }
    func buildOverlay() {
        indicatorView.removeFromSuperview()
        
        addSubview(indicatorView)
        indicatorView.isUserInteractionEnabled = false
        indicatorView.backgroundColor = indicatorColor
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.topAnchor.constraint(equalTo: topAnchor, constant: indicatorMargin).isActive = true
        indicatorView.bottomAnchor.constraint(equalTo: fake.bottomAnchor, constant: -fake.bottomLine-indicatorMargin).isActive = true
        indicatorView.widthAnchor.constraint(equalToConstant: 2).isActive = true
        indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        rightShadow.removeFromSuperview()
        addSubview(rightShadow)
        rightShadow.translatesAutoresizingMaskIntoConstraints = false
        rightShadow.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightShadow.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightShadow.rightAnchor.constraint(equalTo: rightAnchor).isActive = true

        leftShadow.removeFromSuperview()
        addSubview(leftShadow)
        leftShadow.translatesAutoresizingMaskIntoConstraints = false
        leftShadow.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftShadow.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftShadow.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        
        leftButton.removeFromSuperview()
        addSubview(leftButton)
        leftButton.setImage(leftButtonImage, for: .normal)
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        leftButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        leftButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        leftButton.centerYAnchor.constraint(equalTo: fake.centerYAnchor, constant: -(fake.bottomLine-mainMargin)/2).isActive = true
        leftButton.addTarget(self, action: #selector(leftPressed), for: .touchUpInside)
        rightButton.removeFromSuperview()
        addSubview(rightButton)
        rightButton.setImage(rightButtonImage, for: .normal)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        rightButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        rightButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        rightButton.centerYAnchor.constraint(equalTo: fake.centerYAnchor, constant: -(fake.bottomLine-mainMargin)/2).isActive = true
        rightButton.addTarget(self, action: #selector(rightPressed), for: .touchUpInside)
        setNeedsDisplay()
        layoutIfNeeded()
        
    }
    func buildFrequency() {
        fakeWidth?.constant = CGFloat(frequenciesCount) * distanceFrequency
        fake.distance = distanceFrequency
        fake.intermediateMargin = intermediateMargin
        fake.mainMargin = mainMargin
        fake.labelMargin = labelMargin
        fake.startFrequency = startFrequency
        fake.endFrequency = endFrequency
        fake.stepFrequency = stepFrequency
        fake.labelFormat = labelFormat == .decimal ? "%g" : "%.0f"
        fake.intermediateFrequencyColor = intermediateFrequencyColor
        fake.mainFrequencyColor = mainFrequencyColor
        fake.labelColor = labelColor
        fake.labelFont = labelFont
        fake.labelCurrentFont = labelCurrentFont
        fake.setNeedsDisplay()
        layoutIfNeeded()
    }
}

class FrequencyDrawView: UIView {
    var count: Int {
        return Int((endFrequency - startFrequency) / stepFrequency)
    }
    var distance: CGFloat = 7
    var intermediateMargin: CGFloat = 10
    var mainMargin: CGFloat = 3
    var labelMargin: CGFloat = 4
    var startFrequency: CGFloat = 76
    var endFrequency: CGFloat = 108
    var stepFrequency: CGFloat = 0.05
    var labelFormat: String = "%.1f"
    var labelColor: UIColor = .black
    var intermediateFrequencyColor: UIColor = .gray
    var mainFrequencyColor: UIColor = .black
    var bottomLine: CGFloat = 0
    var firstOffset: CGFloat = 0
    var labelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    var labelCurrentFont = UIFont.systemFont(ofSize: 14, weight: .bold)
    var currentIndex: Int = 0
    var closureUpdate: (()->Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
        layer.masksToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let context = UIGraphicsGetCurrentContext() {
            for position in 0...count {
                let current = String(format: labelFormat, startFrequency + CGFloat(position) * stepFrequency)
                                             
                let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center

                let attrs = [NSAttributedString.Key.font: position == currentIndex ? labelCurrentFont : labelFont, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: labelColor]
                let size = current.size(withAttributes: attrs)
                if position == 0 {
                    firstOffset = size.width
                }
                let isIntermediate = position % 5 != 0
                if isIntermediate {
                    context.setStrokeColor(intermediateFrequencyColor.cgColor)
                } else {
                    context.setStrokeColor(mainFrequencyColor.cgColor)
                }
                context.setLineWidth(1)
                let movePoint = (distance + 1) * CGFloat(position) + firstOffset
                let margin = isIntermediate ? intermediateMargin : mainMargin
                context.move(to: CGPoint(x: movePoint, y: margin))
                context.addLine(to: CGPoint(x: movePoint, y: bounds.height - margin - size.height/2 - labelMargin))
                context.strokePath()
                bottomLine = max(bottomLine, size.height)
                if !isIntermediate {
//                    size = current.size(withAttributes: attrs)
                    current.draw(with: CGRect(x: movePoint-size.width/2, y: bounds.height-size.height, width: size.width, height: size.height), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                }
            }
            closureUpdate?()
        }
    }
}
