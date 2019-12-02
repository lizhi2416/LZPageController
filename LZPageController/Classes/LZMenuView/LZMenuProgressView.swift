//
//  LZMenuProgressView.swift
//  Cartoon-Swift
//
//  Created by 蒋理智 on 2019/10/8.
//  Copyright © 2019 lizhi. All rights reserved.
//

import UIKit

class LZMenuProgressView: UIView {

    var itemFrames: [CGRect]?
    var color: CGColor?
    var progress: CGFloat = 0 {
        didSet {
            if progress == oldValue {
                return
            }
            self.setNeedsDisplay()
        }
    }
    
    //进度条的速度因数，默认为 15，越小越快， 大于 0
    var speedFactor: CGFloat = 15.0
    var speedValue: CGFloat {
        get {
            if speedFactor<=0 {
                return 15.0
            }
            return speedFactor
        }
    }
    
    var cornerRadius: CGFloat = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    // 调皮属性，用于实现新腾讯视频效果
    var naughty = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var isTriangle = false
    var hollow = false
    var hasBorder = false
    
    //动画参数
    var sign: Int = 0
    var gap: CGFloat = 0
    var step: CGFloat = 0
    
    weak var link: CADisplayLink?
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        let height = self.frame.size.height
        
        var index = Int(self.progress)
        
        guard let itemFrames = self.itemFrames else { return  }
        
        index = (index <= itemFrames.count - 1) ? index : itemFrames.count - 1
        
        if index < 0 {
            index = 0
        }
        
        let rate: CGFloat = self.progress - CGFloat(index);
        let currentFrame = itemFrames[index]
        let currentWidth = currentFrame.size.width
        let nextIndex = index + 1 < itemFrames.count ? index + 1 : index;
        let nextWidth = itemFrames[nextIndex].size.width

        let currentX = currentFrame.origin.x;
        let nextX = itemFrames[nextIndex].origin.x
        var startX = currentX + (nextX - currentX) * CGFloat(rate)
        var width = currentWidth + (nextWidth - currentWidth) * CGFloat(rate)
        var endX = startX + width
        
        if (self.naughty) {
            let currentMidX = currentX + currentWidth / 2.0
            let nextMidX   = nextX + nextWidth / 2.0
            
            if (rate <= 0.5) {
                startX = currentX + (currentMidX - currentX) * rate * 2.0
                let currentMaxX = currentX + currentWidth
                endX = currentMaxX + (nextMidX - currentMaxX) * rate * 2.0;
            } else {
                startX = currentMidX + (nextX - currentMidX) * (rate - 0.5) * 2.0
                let nextMaxX = nextX + nextWidth
                endX = nextMidX + (nextMaxX - nextMidX) * (rate - 0.5) * 2.0
            }
            width = endX - startX
        }
        
        let lineWidth: CGFloat = (self.hollow || self.hasBorder) ? 1.0 : 0.0
        
        if (self.isTriangle) {
            ctx?.move(to: CGPoint(x: startX, y: height))
            ctx?.addLine(to: CGPoint(x: endX, y: height))
            ctx?.addLine(to: CGPoint(x: startX + width / 2.0, y: 0))
            ctx?.closePath()
            if let color = self.color {
                ctx?.setFillColor(color)
            }
            ctx?.fillPath()
            return;
        }
        
        let path: UIBezierPath = UIBezierPath(roundedRect: CGRect(x: startX, y: lineWidth / 2.0, width: width, height: height - lineWidth), cornerRadius: self.cornerRadius)
        ctx?.addPath(path.cgPath)
        
        if (self.hollow) {
            if let color = self.color {
                ctx?.setStrokeColor(color)
            }
            ctx?.strokePath()
            return;
        }
        if let color = self.color {
            ctx?.setFillColor(color)
        }
        ctx?.fillPath()
        
        if (self.hasBorder) {
            // 计算点
            guard let first = itemFrames.first else { return  }
            guard let last = itemFrames.last else { return  }
            let startX = first.minX
            let endX = last.maxX
            let path = UIBezierPath(roundedRect: CGRect(x: startX, y: lineWidth / 2.0, width: (endX - startX), height: height - lineWidth), cornerRadius: self.cornerRadius)
            ctx?.setLineWidth(lineWidth)
            ctx?.addPath(path.cgPath)
            
            // 绘制
            if let color = self.color {
                ctx?.setStrokeColor(color)
            }
            ctx?.strokePath()
        }
    }
    

}

extension LZMenuProgressView {
    func setProgressWithOutAnimate(progress: CGFloat) {
        if progress == self.progress {
            return
        }
        self.progress = progress
        self.setNeedsDisplay()
    }
    
    func moveToPostion(pos: Int) {
        
        self.gap = CGFloat(fabsf(Float(self.progress - CGFloat(pos))))
        self.sign = self.progress > CGFloat(pos) ? -1 : 1;
        self.step = self.gap / self.speedValue
        
        if (self.link != nil) {
            self.link?.invalidate()
        }
        let link = CADisplayLink.init(target: self, selector: #selector(progressChanged))
        link.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        self.link = link
    }
    
    @objc func progressChanged() {
        if (gap > 0.000001) {
            gap -= step
            if (gap < 0.0) {
                //swift类型安全，类型之间转换严瑾，需要强转
                let intRate = Int(self.progress + CGFloat(sign) * step + 0.5)
                
//                lround(22.222)四舍五入转换成整数
                self.progress = CGFloat(intRate)
                return
            }
            self.progress += CGFloat(sign) * step;
        } else {
            let intRate = Int(self.progress + 0.5)
            self.progress = CGFloat(intRate)
            link?.invalidate()
            link = nil;
        }
    }
}
