//
//  ErrorView.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 11.08.22.
//

import UIKit

class ErrorView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var errorLabel: UILabel!
    
    var delegate: ErrorViewDelegate?
    
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
    
    
    @IBAction func reload () {
        delegate?.reload(self)
    }
}
