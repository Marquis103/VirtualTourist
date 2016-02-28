//
//  photoViewCell.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/24/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit

class PhotoViewCell: UICollectionViewCell {

	@IBOutlet weak var photoCellImageView: UIImageView!
	@IBOutlet weak var loadingView: UIView! {
		didSet {
			loadingView.clipsToBounds = true
			loadingView.layer.cornerRadius = 10
			let activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width:
			50, height: 50))
			activityIndicatorView.center = CGPoint(x: (self.bounds.size.width / 2) + 5, y: (self.bounds.size.height / 2) + 5)
			loadingView.addSubview(activityIndicatorView)
			activityIndicatorView.hidesWhenStopped = true
			activityIndicatorView.activityIndicatorViewStyle = .WhiteLarge
			activityIndicatorView.startAnimating()
		}
	}
}
