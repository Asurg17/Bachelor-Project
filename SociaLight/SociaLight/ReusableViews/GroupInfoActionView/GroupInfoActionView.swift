//
//  GroupInfoActionView.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 26.07.22.
//

import UIKit

class GroupInfoActionView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var label: UILabel!
    @IBOutlet var leftArrow: UIImageView!
    
    @IBInspectable var iconImage: UIImage = UIImage() {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var labelText: String = "" {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var colour: UIColor = UIColor.black {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var isLeftArrowHidden: Bool = false {
        didSet {
            updateView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        let bundle = Bundle(for: GroupInfoActionView.self)
        bundle.loadNibNamed(String(describing: Self.self), owner: self, options: nil)
        
        guard let contentView = contentView else { fatalError("ContentView not set!") }
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(contentView)
    }
    
    var delegate: GroupInfoActionViewDelegate?
    
    func updateView() {
        icon.image = iconImage
        label.text = labelText
        leftArrow.isHidden = isLeftArrowHidden
        
        icon.tintColor = colour
        label.textColor = colour
    }
    
    
    @IBAction func touchBegan () {
        DispatchQueue.main.async {
            self.alpha = 1.0
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                self.alpha = 0.5
            }, completion: nil)
        }
    }
    
    @IBAction func touchEnd () {
        DispatchQueue.main.async {
            self.alpha = 0.5
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                self.alpha = 1.0
            }, completion: nil)
        }
    }
    
    @IBAction func performAction() {
        touchEnd()
        delegate?.actionDidInitiated(self)
    }
    
}
