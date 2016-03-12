# VirtualTourist
App allows users to drop pins on a map and retrieve public images uploaded by users to the region.  The app uses the Flickr API as a photo backend and core data as local image metadata store.

## Getting Started
App is build using Swift 2.1, iOS 9 and XCode 7.

##Known Issues
* Flickr API sometimes returns an empty set, when images are expected.
* Virtual Tourist displays 21 images at a time as a maximum, but if there is a page in the result with less than 21 images only those images will be returned even though there are more items in the entire set.

##Needed Functionality
* Pre-fetch data on pin drop
* Scrolling download (endless scrolling)

##License
Code released under the [MIT license](https://github.com/Marquis103/VirtualTourist/blob/master/License)
