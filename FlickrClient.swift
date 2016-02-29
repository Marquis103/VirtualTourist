//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/23/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation

class FlickrClient {
	static let sharedClient:FlickrClient = FlickrClient()
	private var session = NSURLSession.sharedSession()
	struct Constants {
		struct FlickrClient {
			static let ApiScheme = "https"
			static let ApiHost = "api.flickr.com"
			static let APIPath = "/services/rest"
			static let ApiMethod = "flickr.photos.search"
			static let APIKey = "255a31ccd4a30c7e4f575f56aaaced03"
			static let SafeSearch = 1
			static let extras = "url_m,date_taken"
			static let format = "json"
			static let nojsoncallback = 1
			static let SearchBBOXHalfWidth:Float = 0.01
			static let SearchBBOXHalfHeight:Float = 0.01
			static let SearchLatRange:(Float, Float) = (-90.0, 90.0)
			static let SearchLonRange:(Float, Float) = (-180.0, 180.0)
		}
		
		struct UIConstants {
			static let MaxPhotoCount = 21
			static let MaxPageCount = 4
			static let MaxItemsPerPage = 16
		}
		
	}
	
	private func checkForErrors(data:NSData?, response:NSURLResponse?, error:NSError?) -> NSError? {
		func sendError(error:String) -> NSError {
			print(error)
			let userInfo = [NSLocalizedDescriptionKey : error]
			return NSError(domain: "taskForGetMethod", code: -1, userInfo: userInfo)
		}
		
		//was there an error
		guard (error == nil) else {
			return sendError("There was an error with your request \(error)")
		}
		
		//did we get a successful response from the API?
		guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
			return sendError("There was an error with your request.  Status code is \((response as? NSHTTPURLResponse)?.statusCode)")
		}
		
		//guard was there any data returned
		guard let _ = data else {
			return sendError("Data was not found")
		}
		
		return nil
	}
	
	private func getURLFromParameters(parameters: [String:AnyObject]?, query:String?, replaceQueryString:Bool) -> NSMutableURLRequest? {
		let components = NSURLComponents()
		components.scheme = Constants.FlickrClient.ApiScheme
		components.host = Constants.FlickrClient.ApiHost
		components.path = Constants.FlickrClient.APIPath
		
		if let query = query {
			components.query = query
		}
		
		if let parameters = parameters {
			var queryItems = [NSURLQueryItem]()
			
			for (key, value) in parameters {
				let queryItem = NSURLQueryItem(name: key, value: "\(value)")
				queryItems.append(queryItem)
			}
			
			components.queryItems = queryItems
		}
		
		if let url = components.URL {
			return NSMutableURLRequest(URL: url)
		} else {
			return nil
		}
	}
	
	private func createBBox(latitude:Float, longitude:Float) -> String {
		let minLon = max(longitude - Constants.FlickrClient.SearchBBOXHalfWidth, Constants.FlickrClient.SearchLonRange.0)
		let maxLon = min(longitude + Constants.FlickrClient.SearchBBOXHalfWidth, Constants.FlickrClient.SearchLonRange.1)
		let minLat = max(latitude - Constants.FlickrClient.SearchBBOXHalfHeight, Constants.FlickrClient.SearchLatRange.0)
		let maxLat = min(latitude + Constants.FlickrClient.SearchBBOXHalfHeight, Constants.FlickrClient.SearchLatRange.1)
		
		return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
	}
	
	private func getPhotoPageNumber(withParameters parameters:[String:AnyObject], pin:Pin, completionHandler handler: (page:Int?, error:NSError?)-> Void) {
//		var parameters = [String:AnyObject]()
//		
//		
//		//setup parameters for query
//		parameters["bbox"] = createBBox(pin.latitude as! Float, longitude: pin.longitude as! Float)
//		parameters["safe_search"] = Constants.FlickrClient.SafeSearch
//		parameters["extras"] = Constants.FlickrClient.extras
//		parameters["api_key"] = Constants.FlickrClient.APIKey
//		parameters["method"] = Constants.FlickrClient.ApiMethod
//		parameters["format"] = Constants.FlickrClient.format
//		parameters["nojsoncallback"] = Constants.FlickrClient.nojsoncallback
		
		guard let request = getURLFromParameters(parameters, query: nil, replaceQueryString: false) else {
			let userInfo = [NSLocalizedDescriptionKey : "Could not generate request"]
			handler(page: nil, error: NSError(domain: "getPhotoPageNumber", code: -1, userInfo: userInfo))
			return
		}
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
			if let error = self.checkForErrors(data, response: response, error: error) {
				handler(page: nil, error: error)
			} else {
				var parsedResult: AnyObject!
				
				do {
					parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
				} catch {
					let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
					handler(page: nil, error: NSError(domain: "getPhotoPageNumber", code: -1, userInfo: userInfo))
				}
				
				if let photos = parsedResult {
					if let photosDict = photos["photos"] as? [String:AnyObject] {
						if let pageNumber = photosDict["pages"] as? Int {
							handler(page: pageNumber, error: nil)
						}
					}
				}
			}
		}
		
		task.resume()
	}
	
	
	func getPhotosByLocation(using pin:Pin, completionHandler handler: (result: AnyObject?, error: NSError?) -> Void) {
		var parameters = [String:AnyObject]()
		
		//setup parameters for query
		parameters["bbox"] = createBBox(pin.latitude as! Float, longitude: pin.longitude as! Float)
		parameters["safe_search"] = Constants.FlickrClient.SafeSearch
		parameters["extras"] = Constants.FlickrClient.extras
		parameters["api_key"] = Constants.FlickrClient.APIKey
		parameters["method"] = Constants.FlickrClient.ApiMethod
		parameters["format"] = Constants.FlickrClient.format
		parameters["nojsoncallback"] = Constants.FlickrClient.nojsoncallback
		parameters["per_page"] = Constants.UIConstants.MaxPhotoCount
		
		getPhotoPageNumber(withParameters: parameters, pin: pin) { (page, error) -> Void in
			guard error == nil else {
				handler(result: nil, error: error)
				return
			}
			
			if let pageCount = page {
				let pageLimit = min(pageCount, Constants.UIConstants.MaxItemsPerPage) //250 items per page
				let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
				parameters["page"] = min(randomPage, Constants.UIConstants.MaxPageCount)
				
				guard let request = self.getURLFromParameters(parameters, query: nil, replaceQueryString: false) else {
					let userInfo = [NSLocalizedDescriptionKey : "Could not generate request"]
					handler(result: nil, error: NSError(domain:"createNSURLMutableRequest", code: -1, userInfo: userInfo))
					return
				}
				
				let task = self.session.dataTaskWithRequest(request) { (data, response, error) -> Void in
					if let error = self.checkForErrors(data, response: response, error: error) {
						handler(result: nil, error: error)
					} else {
						var parsedResult: AnyObject!
						
						do {
							parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
						} catch {
							let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
							handler(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: -1, userInfo: userInfo))
						}
						
						handler(result: parsedResult, error: nil)
					}
				}
				
				task.resume()
			}
		}
	}
}