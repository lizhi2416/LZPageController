//
//  LZMenuItem.swift
//  Cartoon-Swift
//
//  Created by 蒋理智 on 2019/9/29.
//  Copyright © 2019 lizhi. All rights reserved.
//

import UIKit

enum LZMenuItemState {
    case selected
    case normal
}

@objc protocol LZMenuItemDelegate: class {
    func didPressedMenuItem(_ menuItem: LZMenuItem)
}

class LZMenuItem: UILabel {
    
    private var normalRed: CGFloat = 0, normalGreen: CGFloat = 0, normalBlue: CGFloat = 0, normalAlpha: CGFloat = 0
    
    private var selectedRed: CGFloat = 0, selectedGreen: CGFloat = 0, selectedBlue: CGFloat = 0, selectedAlpha: CGFloat = 0
    
    var normalColor = UIColor.darkGray {
        didSet {
            normalColor.getRed(&normalRed, green: &normalGreen, blue: &normalBlue, alpha: &normalAlpha)
        }
    }
    
    var selectedColor = UIColor.lightGray {
        didSet {
            selectedColor.getRed(&selectedRed, green: &selectedGreen, blue: &selectedBlue, alpha: &selectedAlpha)
        }
    }
    
    var normalSize: CGFloat = 15.0
    
    var selectedSize: CGFloat = 15.0
    
    
    var rate: CGFloat = 0 {
        didSet {
            guard rate >= 0.0 || rate <= 1.0 else {
                return
            }
            let r = normalRed + (selectedRed - normalRed) * rate;
            let g = normalGreen + (selectedGreen - normalGreen) * rate;
            let b = normalBlue + (selectedBlue - normalBlue) * rate;
            let a = normalAlpha + (selectedAlpha - normalAlpha) * rate;
            self.textColor = UIColor.init(red: r, green: g, blue: b, alpha: a);
            let minScale = self.normalSize / self.selectedSize
            let trueScale = minScale + (1 - minScale)*rate
            self.transform = CGAffineTransform(scaleX: trueScale, y: trueScale)
            if (minScale <= 1.0) {//只有选中尺寸更大才去改变
                if #available(iOS 8.2, *) {
                    self.font = UIFont.systemFont(ofSize: selectedSize, weight: UIFont.Weight(rawValue: rate*0.2))
                } else {
                    // Fallback on earlier versions
                }//这里保证选中时字体加粗
            }
        }
    }
    
    var speedFactor: CGFloat = 15.0
    
    var speedValue: CGFloat {
        get {
            if speedFactor<=0 {
                return 15.0
            }
            return speedFactor
        }
    }
    
    var sign: Int = 0
    var gap: CGFloat = 0
    var step: CGFloat = 0
    
    
    weak var delegate: LZMenuItemDelegate?
    
    weak var link: CADisplayLink?
    
    //对外只读，对内可读写
    private(set) var selected: Bool = false
    
    lazy var tapGesture: UITapGestureRecognizer = {
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(touchUpInside(_:)))
        return tapGes
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMainView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMainView()
    }
}

extension LZMenuItem {
    func setupMainView() {
        self.numberOfLines = 0
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func touchUpInside(_ tap: UITapGestureRecognizer) {
        self.delegate?.didPressedMenuItem(self)
    }
    
    func setSelected(selected: Bool, animation: Bool) {
        if (!animation) {
            self.rate = selected ? 1.0 : 0.0;
            return;
        }
        self.sign = selected ? 1 : -1;
        self.gap  = selected ? (1.0 - self.rate) : (self.rate - 0.0);
        self.step = self.gap / self.speedValue;
        if (link != nil) {
            link?.invalidate()
        }
        //link for show selected animation when animation is YES
        let displayLink = CADisplayLink(target: self, selector: #selector(rateChange))
        displayLink.add(to: RunLoop.main, forMode: .common)
        self.link = displayLink
    }
    
    @objc func rateChange() {
        if (gap > 0.000001) {
            gap -= step
            if (gap < 0.0) {
                //swift类型安全，类型之间转换严瑾，需要强转
                let intRate = Int(self.rate + CGFloat(sign) * step + 0.5)
                
//                lround(22.222)四舍五入转换成整数
                self.rate = CGFloat(intRate)
                return
            }
            self.rate += CGFloat(sign) * step;
        } else {
            let intRate = Int(self.rate + 0.5)
            self.rate = CGFloat(intRate)
            link?.invalidate()
            link = nil;
        }
    }
}
