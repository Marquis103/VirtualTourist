//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/23/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates:() -> Void ) {
	dispatch_async(dispatch_get_main_queue()) { () -> Void in
		updates()
	}
}

func performDownloadsAndUpdateInBackground(updates:() -> Void) {
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { () -> Void in
		updates()
	}
}