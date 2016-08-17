//
//  VectorEditor.swift
//  SNVector
//
//  Created by satoshi on 8/16/16.
//  Copyright © 2016 Satoshi Nakajima. All rights reserved.
//

import UIKit

class VectorEditor: UIViewController {
    let layerCurve = CAShapeLayer()
    var elements = [SNPathElement]()
    let radius = 20.0 as CGFloat
    let baseTag = 100
    var indexDragging:Int?
    var offset = CGPoint.zero

    private func updateCurve() {
        layerCurve.path = SNPath.pathFrom(elements)
        layerCurve.lineWidth = 1
        layerCurve.fillColor = UIColor.clearColor().CGColor
        layerCurve.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1.0).CGColor
        layerCurve.lineCap = "round"
        layerCurve.lineJoin = "round"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateCurve()
        self.view.layer.addSublayer(layerCurve)
        
        func addViewAt(pt:CGPoint, index:Int) {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2))
            view.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.3)
            view.layer.cornerRadius = radius
            view.layer.masksToBounds = true
            view.tag = baseTag + index
            self.view.addSubview(view)
            view.center = pt
        }
        
        for (index, element) in elements.enumerate() {
            switch(element) {
            case let move as SNMove:
                addViewAt(move.pt, index:index)
            case let quad as SNQuadCurve:
                addViewAt(quad.cp, index:index)
                //addViewAt(quad.pt)
            default:
                break
            }
        }
        
        if let quad = elements.last as? SNQuadCurve {
            addViewAt(quad.pt, index:elements.count)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension CGPoint {
    func middle(pt:CGPoint) -> CGPoint {
        return CGPointMake((self.x + pt.x)/2, (self.y + pt.y)/2)
    }
}

// MARK: UIResponder

extension VectorEditor {
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            if let subview = touch.view where subview.tag >= baseTag {
                indexDragging = subview.tag - baseTag
                let pt = touch.locationInView(view)
                let center = subview.center
                offset = CGPointMake(pt.x - center.x, pt.y - center.y)
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let index = indexDragging,
           let touch = touches.first,
           let subview = view.viewWithTag(index + baseTag) {
            let pt = touch.locationInView(view)
            subview.center = CGPointMake(pt.x - offset.x, pt.y - offset.y)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let index = indexDragging,
           let subview = view.viewWithTag(index + baseTag) {
            let cp = subview.center
            if index < elements.count {
                switch(elements[index]) {
                case let quad as SNQuadCurve:
                    if index > 0, let prev = elements[index-1] as? SNQuadCurve {
                        elements[index-1] = SNQuadCurve(cp: prev.cp, pt: prev.cp.middle(cp))
                    }
                    if index-1 < elements.count, let next = elements[index+1] as? SNQuadCurve {
                        elements[index] = SNQuadCurve(cp: cp, pt: cp.middle(next.cp))
                    } else {
                        elements[index] = SNQuadCurve(cp: cp, pt: quad.cp)
                    }
                default:
                    break
                }
            }
            updateCurve()
        }
        indexDragging = nil
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        indexDragging = nil
    }
}