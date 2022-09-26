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
        }
    }
    public var labelFormat: LabelFormat = .decimal
    public var startFrequency: CGFloat = 76
    public var endFrequency: CGFloat = 108
    public var frequecy: CGFloat = 76 {
        didSet {
            frequecy = max(min(frequecy, endFrequency), startFrequency)
            var startPostion = (frequecy - startFrequency) / stepFrequency  * distanceFrequency
            startPostion = startPostion + ((frequecy - startFrequency)  / stepFrequency) * 1
            scrollView.setContentOffset(CGPoint(x: startPostion - bounds.width/2, y: 0), animated: true)
            delegate?.frequency(view: self, didChange: frequecy)
        }
    }
    public var stepFrequency: CGFloat = 0.05
    public var distanceFrequency: CGFloat = 6
    public var intermediateFrequencyColor: UIColor = .gray
    public var mainMargin: CGFloat = 3
    public var intermediateMargin: CGFloat = 10
    public var labelMargin: CGFloat = 4
    public var mainFrequencyColor: UIColor = .black
    public var indicatorColor: UIColor = .red
    public var labelFont = UIFont.systemFont(ofSize: 9, weight: .light)
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
    
    private var tempView: UIView?
    
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
        scrollView.contentInset = UIEdgeInsets(top: 0, left: bounds.width/2, bottom: 0, right: bounds.width/2)
    }
    func refresh() {
        buildFrequency()
        buildOverlay()
    }
    public override func prepareForInterfaceBuilder() {
        setup()
    }
}

extension RadioFrequencyView: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        frequecy = recalcCurrent(scrollView)
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else {return}
        
        frequecy = recalcCurrent(scrollView)
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
        
        let fake = UIView(frame: .null)
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
        
        fake.addSubview(frequenciesView)
        frequenciesView.translatesAutoresizingMaskIntoConstraints = false
        frequenciesView.leftAnchor.constraint(equalTo: fake.leftAnchor).isActive = true
        frequenciesView.rightAnchor.constraint(equalTo: fake.rightAnchor).isActive = true
        frequenciesView.topAnchor.constraint(equalTo: fake.topAnchor).isActive = true
        frequenciesView.bottomAnchor.constraint(equalTo: fake.bottomAnchor).isActive = true
        
        frequenciesView.axis = .horizontal
        frequenciesView.distribution = .fill

        buildFrequency()
        buildOverlay()
    }
    func recalcCurrent(_ scrollView: UIScrollView) -> CGFloat {
        let position = scrollView.contentOffset.x + bounds.width/2
        let format = labelFormat == .decimal ? "%.1f" : "%.0f"
        let current = String(format: format, position / (distanceFrequency + 1) * stepFrequency + startFrequency)
        
        return CGFloat(Float(current) ?? 0)
    }
    @objc func leftPressed() {
        frequecy = max(startFrequency, frequecy - stepFrequency)

    }
    @objc func rightPressed() {
        frequecy = min(endFrequency, frequecy + stepFrequency)
    }
    func buildOverlay() {
        indicatorView.removeFromSuperview()
        
        addSubview(indicatorView)
        indicatorView.isUserInteractionEnabled = false
        indicatorView.backgroundColor = indicatorColor
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        indicatorView.bottomAnchor.constraint(equalTo: tempView!.bottomAnchor, constant: mainMargin).isActive = true
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
        leftButton.centerYAnchor.constraint(equalTo: tempView!.centerYAnchor).isActive = true
        leftButton.addTarget(self, action: #selector(leftPressed), for: .touchUpInside)
        rightButton.removeFromSuperview()
        addSubview(rightButton)
        rightButton.setImage(rightButtonImage, for: .normal)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        rightButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        rightButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        rightButton.centerYAnchor.constraint(equalTo: tempView!.centerYAnchor).isActive = true
        rightButton.addTarget(self, action: #selector(rightPressed), for: .touchUpInside)
    }
    func buildFrequency() {
        frequenciesView.spacing = distanceFrequency
        frequenciesView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        
        
        for element in stride(from: startFrequency, to: endFrequency, by: stepFrequency).enumerated() {
            let isIntermediate = element.offset % 5 != 0
            let view = UIView(frame: .null)
            view.backgroundColor = .clear
            
            
            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalToConstant: 1).isActive = true
            frequenciesView.addArrangedSubview(view)
            let label = UILabel(frame: .null)
            view.addSubview(label)
            var text = "\(element.element)"
            if labelFormat == .int {
                text = "\(Int(element.element))"
            }
            label.text = text
            label.textColor = isIntermediate ? .clear : .black
            label.font = labelFont
            label.translatesAutoresizingMaskIntoConstraints = false
            label.bottomAnchor.constraint(equalTo: frequenciesView.bottomAnchor).isActive = true
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            
            let line = UIView(frame: .null)
            view.addSubview(line)
            line.backgroundColor = isIntermediate ? intermediateFrequencyColor : mainFrequencyColor
            line.translatesAutoresizingMaskIntoConstraints = false
            line.topAnchor.constraint(equalTo: view.topAnchor, constant: isIntermediate ? intermediateMargin : mainMargin).isActive = true
            line.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -labelMargin + (isIntermediate ? -intermediateMargin : -mainMargin)).isActive = true
            line.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            line.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            if !isIntermediate {
                tempView = line
            }
        }
    }

}

