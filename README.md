# Lantern

## Description

Lantern is a Swift 5 application that allows users to easily crawl and audit websites. This makes it simple to debug website issues and enhance search engine optimization. It is available for free on the [Mac App Store](https://itunes.apple.com/us/app/lantern-website-crawler-for/id991526452?ls=1&mt=12).

### Why Lantern?

Lantern allows users to efficiently audit their websites through a UI. Being able to dig underneath the surface and examine sites at the meta level can lead to powerful findings and significant optimization.

### How To Use

Simply type the URL you wish to crawl into Lantern's search bar, and from there you will be able to investigate metadata, embedded content, and links through the user interface.

<img width="400" alt="Lantern standard view. Browser on left, metadata on right." src="https://user-images.githubusercontent.com/54863526/189182970-604809bc-c715-4dfb-9877-e4440be786b7.png">

In this example image, the user is investigating the images on their website and able to ensure that they all appear as expected.

<img width="400" alt="Lantern standard view. User is looking at title data of a site's home page" src="https://user-images.githubusercontent.com/54863526/189184627-4bf2f2a7-910c-4d0e-bbd4-3ea6fb320476.png">

This example shows how a user could quickly investigate title related data using Lantern. Simply navigate to the site and select the "Titles" tab.


When done, click "stop crawling" or enter a new address into the search bar.




## Developer Setup Guide

This project uses [Carthage](https://github.com/Carthage/Carthage) to manage dependencies.

Set up a local repository by following the steps below
1. `git clone https://github.com/RoyalIcing/Lantern.git`
1. `cd Lantern`
1. `brew install carthage`
1. `carthage update --use-xcframeworks`
1. Open in [XCode](https://developer.apple.com/xcode/) to start editing.

## Links

[Download on the Mac App Store](https://itunes.apple.com/us/app/lantern-website-crawler-for/id991526452?ls=1&mt=12)

[Developer site](https://icing.space/)

[Back on Open Collective](https://opencollective.com/lantern)

## Libraries 

Uses:
- [Grain data flow for Swift](https://github.com/BurntCaramel/Grain)
- [BurntCocoaUI](https://github.com/BurntCaramel/BurntCocoaUI)
- [BurntFoundation](https://github.com/BurntCaramel/BurntFoundation)
- [WebKit](https://www.webkit.org)
- [Alamofire](https://github.com/Alamofire/Alamofire)
- [Ono](https://github.com/mattt/Ono)

## License

Lantern is released under the [Apache-2.0 License](https://github.com/RoyalIcing/Lantern/blob/master/LICENSE).

Example demos include images from https://www.burntcaramel.com/.
