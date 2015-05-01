//
//  StatsViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 24/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


enum BaseContentTypeChoice: Int {
	case LocalHTMLPages = 1
	case Images = 2
	case Feeds = 3
	
	var baseContentType: BaseContentType {
		switch self {
		case .LocalHTMLPages:
			return .LocalHTMLPage
		case .Images:
			return .Image
		case .Feeds:
			return .Feed
		}
	}
}

extension BaseContentTypeChoice: MenuItemRepresentative {
	var title: String {
		switch self {
		case .LocalHTMLPages:
			return "Local Pages"
		case .Images:
			return "Images"
		case .Feeds:
			return "Feeds"
		}
	}
	var tag: Int? { return rawValue }
	
	typealias UniqueIdentifier = BaseContentTypeChoice
	var uniqueIdentifier: UniqueIdentifier { return self }
}


enum StatsFilterResponseChoice: Int {
	case All = 0
	
	case Successful = 2
	case Redirects = 3
	case RequestErrors = 4
	case ResponseErrors = 5
	
	case ValidInformation = 100
	case ProblematicMIMEType = 101
	case ProblematicPageTitle = 102
	case ProblematicHeading = 103
	case ProblematicMetaDescription = 104
	
	
	var responseType: PageResponseType? {
		switch self {
		case .Successful:
			return .Successful
		case .Redirects:
			return .Redirects
		case .RequestErrors:
			return .RequestErrors
		case .ResponseErrors:
			return .ResponseErrors
		default:
			return nil
		}
	}
	
	var validationArea: PageInfoValidationArea? {
		switch self {
		case .ProblematicMIMEType:
			return .MIMEType
		case .ProblematicHeading:
			return .H1
		case .ProblematicPageTitle:
			return .Title
		case .ProblematicMetaDescription:
			return .MetaDescription
		default:
			return nil
		}
	}
}

extension StatsFilterResponseChoice: MenuItemRepresentative {
	var title: String {
		switch self {
		case .All:
			return "All"
			
		case .Successful:
			return "[2xx] Successful"
		case .Redirects:
			return "[3xx] Redirects"
		case .RequestErrors:
			return "[4xx] Request Errors"
		case .ResponseErrors:
			return "[5xx] Response Errors"
			
		case .ValidInformation:
			return "Valid Information"
			
		case .ProblematicMIMEType:
			return "Invalid MIME Types"
		case .ProblematicHeading:
			return "Invalid Headings"
		case .ProblematicPageTitle:
			return "Invalid Page Titles"
		case .ProblematicMetaDescription:
			return "Invalid Meta Description"
		}
	}
	
	var tag: Int? { return rawValue }
	
	typealias UniqueIdentifier = StatsFilterResponseChoice
	var uniqueIdentifier: UniqueIdentifier { return self }
}

enum StatsColumnsMode: Int {
	case Titles = 1
	case Descriptions = 2
	case Types = 3
	case DownloadSizes = 4
	case Links = 5
	
	func columnIdentifiersForBaseContentType(baseContentType: BaseContentType) -> [PagePresentedInfoIdentifier] {
		switch self {
		case .Titles:
			return [.pageTitle, .h1]
		case .Descriptions:
			return [.metaDescription, .pageTitle]
		case .Types:
			return [.statusCode, .MIMEType]
		case .DownloadSizes:
			switch baseContentType {
			case .LocalHTMLPage:
				return [.pageByteCount, .pageByteCountBeforeBodyTag, .pageByteCountAfterBodyTag]
			default:
				return [.pageByteCount]
			}
		case .Links:
			return [.internalLinkCount, .externalLinkCount]
		}
	}
	
	var title: String {
		switch self {
		case .Titles:
			return "Titles"
		case .Descriptions:
			return "Descriptions"
		case .Types:
			return "Types"
		case .DownloadSizes:
			return "Sizes"
		case .Links:
			return "Links"
		}
	}
}

extension StatsColumnsMode: SegmentedItemRepresentative {
	var tag: Int? { return rawValue }
	
	typealias UniqueIdentifier = StatsColumnsMode
	var uniqueIdentifier: UniqueIdentifier { return self }
}

extension StatsColumnsMode: Printable {
	var description: String {
		return title
	}
}

extension StatsFilterResponseChoice {
	var preferredColumnsMode: StatsColumnsMode? {
		switch self {
		case .ProblematicMIMEType:
			return .Types
		case .ProblematicPageTitle, .ProblematicHeading:
			return .Titles
		case .ProblematicMetaDescription:
			return .Descriptions
		default:
			return nil
		}
	}
}

extension BaseContentTypeChoice {
	var allowedColumnsModes: [StatsColumnsMode] {
		switch self {
		case .LocalHTMLPages:
			return [.Titles, .Descriptions, .Types, .DownloadSizes, .Links]
		default:
			return [.Types, .DownloadSizes]
		}
	}
}


class StatsViewController: NSViewController {

	@IBOutlet var outlineView: NSOutlineView!
	
	@IBOutlet var columnsModeSegmentedControl: NSSegmentedControl!
	var columnsModeSegmentedControlAssistant: SegmentedControlAssistant<StatsColumnsMode>?
	
	@IBOutlet var filterResponseChoicePopUpButton: NSPopUpButton!
	var filterResponseChoicePopUpButtonAssistant: PopUpButtonAssistant<StatsFilterResponseChoice>?
	
	@IBOutlet var baseContentTypeChoicePopUpButton: NSPopUpButton!
	var baseContentTypeChoicePopUpButtonAssistant: PopUpButtonAssistant<BaseContentTypeChoice>?
	
	var chosenBaseContentChoice: BaseContentTypeChoice = .LocalHTMLPages
	var filterToBaseContentType: BaseContentType {
		return chosenBaseContentChoice.baseContentType
	}
	var filterResponseChoice: StatsFilterResponseChoice = .All
	var selectedColumnsMode: StatsColumnsMode = .Titles
	var allowedColumnsModes: [StatsColumnsMode] {
		return chosenBaseContentChoice.allowedColumnsModes
	}
	
	var filteredURLs = [NSURL]()
	
	var rowMenu: NSMenu!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		
		outlineView.removeTableColumn(outlineView.tableColumnWithIdentifier("text")!)
		
		//updateColumnsToOnlyShow(selectedColumnsMode.columnIdentifiersForBaseContentType(filterToBaseContentType))
		
		outlineView.setDataSource(self)
		outlineView.setDelegate(self)
		
		createRowMenu()
		
		updateUI()
    }
	
	var primaryURL: NSURL! {
		didSet {
			crawl()
		}
	}
	
	var pageMapper: PageMapper!
	
	func updateListOfURLs() {
		if let primaryURL = primaryURL {
			let baseContentType = filterToBaseContentType
			if filterResponseChoice == .All {
				filteredURLs = pageMapper.copyURLsWithBaseContentType(baseContentType)
			}
			else if let responseType = filterResponseChoice.responseType {
				filteredURLs = pageMapper.copyURLsWithBaseContentType(baseContentType, withResponseType: responseType)
			}
			else if filterResponseChoice == .ValidInformation {
				filteredURLs = pageMapper.copyHTMLPageURLsWhichCompletelyValidateForType(baseContentType)
			}
			else if let validationArea = filterResponseChoice.validationArea {
				filteredURLs = pageMapper.copyHTMLPageURLsForType(baseContentType, failingToValidateInArea: validationArea)
			}
			else {
				fatalError("filterResponseChoice must be set to something valid")
			}
			
			//println("filteredURLs \(filteredURLs)")
			outlineView.reloadData()
		}
	}
	
	func updateUI(
		baseContentType: Bool = true,
		filterResponseChoice: Bool = true,
		columnsMode: Bool = true
		)
	{
		if baseContentType {
			updateBaseContentTypeChoiceUI()
		}
		if filterResponseChoice {
			updateFilterResponseChoiceUI()
		}
		if columnsMode {
			updateColumnsModeUI()
		}
		
		updateListOfURLs()
	}
	
	func clearPageMapper() {
		if let oldPageMapper = pageMapper {
			oldPageMapper.cancel()
			pageMapper = nil
		}
	}
	
	func crawl() {
		clearPageMapper()
		
		if let primaryURL = primaryURL {
			pageMapper = PageMapper(primaryURL: primaryURL)
			pageMapper.didUpdateCallback = { loadedPageURL in
				self.pageURLDidUpdate(loadedPageURL)
			}
			
			pageMapper.reload()
		}
	}
	
	private func pageURLDidUpdate(pageURL: NSURL) {
		updateUI()
		//outlineView.reloadItem(pageURL, reloadChildren: true)
	}
	
	private func updateColumnsToOnlyShow(columnIdentifiers: [PagePresentedInfoIdentifier]) {
		func updateHeaderOfColumn(column: NSTableColumn, withTitleFromIdentifier identifier: PagePresentedInfoIdentifier) {
			(column.headerCell as! NSTableHeaderCell).stringValue = identifier.titleForBaseContentType(filterToBaseContentType)
		}
		
		let minColumnWidth: CGFloat = 130.0
		
		outlineView.beginUpdates()
		
		let uniqueColumnIdentifiers = Set(columnIdentifiers)
		let existingTableColumnIdentifierStrings = outlineView.tableColumns.map { return $0.identifier }
		for identifierString in existingTableColumnIdentifierStrings {
			if let identifier = PagePresentedInfoIdentifier(rawValue: identifierString) where !uniqueColumnIdentifiers.contains(identifier) && identifier != .requestedURL {
				outlineView.removeTableColumn(outlineView.tableColumnWithIdentifier(identifierString)!)
			}
		}
		
		let columnsRemainingWidth = outlineView.enclosingScrollView!.documentVisibleRect.width - outlineView.outlineTableColumn!.width
		let columnWidth = max(columnsRemainingWidth / CGFloat(columnIdentifiers.count), minColumnWidth)
		
		var columnIndex = 1 // After outline column
		for identifier in columnIdentifiers {
			let existingColumnIndex = outlineView.columnWithIdentifier(identifier.rawValue)
			var tableColumn: NSTableColumn
			if existingColumnIndex >= 0 {
				tableColumn = outlineView.tableColumnWithIdentifier(identifier.rawValue)!
				outlineView.moveColumn(existingColumnIndex, toColumn: columnIndex)
			}
			else {
				tableColumn = NSTableColumn(identifier: identifier.rawValue)
				outlineView.addTableColumn(tableColumn)
			}
			
			tableColumn.width = columnWidth
			updateHeaderOfColumn(tableColumn, withTitleFromIdentifier: identifier)
			
			columnIndex++
		}
		
		updateHeaderOfColumn(outlineView.outlineTableColumn!, withTitleFromIdentifier: .requestedURL)
		
		outlineView.endUpdates()
		
		//outlineView.resizeSubviewsWithOldSize(outlineView.bounds.rectByInsetting(dx: 1.0, dy: 0.0).size)
		//outlineView.resizeWithOldSuperviewSize(outlineView.bounds.size)
		outlineView.reloadData()
	}
	
	func changeColumnsMode(columnsMode: StatsColumnsMode, updateUI: Bool = true) {
		selectedColumnsMode = columnsMode
		
		if updateUI {
			updateColumnsModeUI()
			
			//columnsModeSegmentedControlAssistant?.selectedItemRepresentative = columnsMode
			
			//updateColumnsToOnlyShow(columnsMode.columnIdentifiersForBaseContentType(filterToBaseContentType))
		}
	}
	
	@IBAction func changeBaseContentTypeFilter(sender: NSPopUpButton) {
		let menuItem = sender.selectedItem!
		let tag = menuItem.tag
		
		let contentChoice = BaseContentTypeChoice(rawValue: tag)!
		chosenBaseContentChoice = contentChoice
		
		updateUI(baseContentType: false)
	}
	
	@IBAction func changeResponseTypeFilter(sender: NSPopUpButton) {
		let menuItem = sender.selectedItem!
		let tag = menuItem.tag
		
		filterResponseChoice = StatsFilterResponseChoice(rawValue: tag)!
		if let preferredColumnsMode = filterResponseChoice.preferredColumnsMode {
			changeColumnsMode(preferredColumnsMode)
		}
		
		updateUI(filterResponseChoice: false)
	}
	
	@IBAction func showTitleColumns(sender: AnyObject?) {
		changeColumnsMode(StatsColumnsMode.Titles)
	}
	
	@IBAction func showDescriptionColumns(sender: AnyObject?) {
		changeColumnsMode(StatsColumnsMode.Descriptions)
	}
	
	@IBAction func showDownloadSizesColumns(sender: AnyObject?) {
		changeColumnsMode(StatsColumnsMode.DownloadSizes)
	}
	
	@IBAction func changeColumnsMode(sender: NSSegmentedControl) {
		let tag = sender.tagOfSelectedSegment()
		if let columnsMode = StatsColumnsMode(rawValue: tag) {
			changeColumnsMode(columnsMode)
		}
	}
}

extension StatsViewController {
	func createRowMenu() {
		// Row Menu
		rowMenu = NSMenu(title: "Row Menu")
		
		let showSourceItem = rowMenu.addItemWithTitle("Show Source", action: "showSourcePreviewForPageAtSelectedRow:", keyEquivalent: "")!
		showSourceItem.target = self
		
		let copyURLItem = rowMenu.addItemWithTitle("Copy URL", action: "copyURLForSelectedRow:", keyEquivalent: "")!
		copyURLItem.target = self
		
		outlineView.menu = rowMenu
	}
	
	@IBAction func showSourcePreviewForPageAtSelectedRow(menuItem: NSMenuItem) {
		let row = outlineView.clickedRow
		if row != -1 {
			showSourcePreviewForPageAtRow(row)
		}
	}
	
	@IBAction func copyURLForSelectedRow(menuItem: NSMenuItem) {
		let row = outlineView.clickedRow
		if row != -1 {
			performCopyURLForURLAtRow(row)
		}
	}
	
	func showSourcePreviewForPageAtRow(row: Int) {
		if let pageURL = outlineView.itemAtRow(row) as? NSURL
		{
			if pageMapper.hasFinishedRequestingURL(pageURL)
			{
				if let pageInfo = pageMapper.pageInfoForRequestedURL(pageURL) {
					let storyboard = self.storyboard!
					let sourcePreviewTabViewController = SourcePreviewTabViewController()
					sourcePreviewTabViewController.pageInfo = pageInfo
					
					let rowRect = outlineView.rectOfRow(row)
					presentViewController(sourcePreviewTabViewController, asPopoverRelativeToRect: rowRect, ofView: outlineView, preferredEdge: NSMinYEdge, behavior: .Semitransient)
				}
			}
		}
	}
	
	func performCopyURLForURLAtRow(row: Int) {
		if let URL = outlineView.itemAtRow(row) as? NSURL
		{
			let pasteboard = NSPasteboard.generalPasteboard()
			pasteboard.clearContents()
			// This does not copy the URL as a string though
			//let success = pasteboard.writeObjects([URL])
			//println("Copying \(success) \(pasteboard) \(URL)")
			pasteboard.declareTypes([NSURLPboardType, NSStringPboardType], owner: nil)
			URL.writeToPasteboard(pasteboard)
			pasteboard.setString(URL.absoluteString!, forType: NSStringPboardType)
		}
	}
}

extension StatsViewController {
	func menuItemRepresentativesForFilterResponseChoice() -> [StatsFilterResponseChoice?] {
		switch filterToBaseContentType {
		case .LocalHTMLPage:
			return [
				.All,
				nil,
				.Successful,
				.Redirects,
				.RequestErrors,
				.ResponseErrors,
				nil,
				.ValidInformation,
				.ProblematicMIMEType,
				.ProblematicPageTitle,
				.ProblematicHeading,
				.ProblematicMetaDescription
			]
		default:
			return [
				.All,
				nil,
				.Successful,
				.Redirects,
				.RequestErrors,
				.ResponseErrors,
				nil,
				.ValidInformation,
				.ProblematicMIMEType,
			]
		}
	}
	
	func updateFilterResponseChoiceUI() {
		let popUpButton = filterResponseChoicePopUpButton
		
		if pageMapper == nil {
			popUpButton.hidden = true
			return
		}
		else {
			popUpButton.hidden = false
		}
		
		var popUpButtonAssistant = filterResponseChoicePopUpButtonAssistant ?? {
			let popUpButtonAssistant = PopUpButtonAssistant<StatsFilterResponseChoice>(popUpButton: popUpButton)
			
			let menuAssistant = popUpButtonAssistant.menuAssistant
			menuAssistant.titleReturner = { choice in
				switch choice {
				case .All:
					let baseContentType = self.filterToBaseContentType
					switch baseContentType {
					case .LocalHTMLPage:
						return "All Local Pages"
					case .Image:
						return "All Images"
					case .Feed:
						return "All Feeds"
					default:
						fatalError("Unimplemented base content type")
					}
				case .Successful, .Redirects, .RequestErrors, .ResponseErrors:
					let baseContentType = self.filterToBaseContentType
					let responseType = choice.responseType!
					let URLCount = self.pageMapper.numberOfLoadedURLsWithBaseContentType(baseContentType, responseType: responseType)
					return "\(choice.title) (\(URLCount))"
				default:
					return choice.title
				}
			}
			
			self.filterResponseChoicePopUpButtonAssistant = popUpButtonAssistant
			
			return popUpButtonAssistant
		}()
		
		popUpButtonAssistant.menuItemRepresentatives = menuItemRepresentativesForFilterResponseChoice()
		popUpButtonAssistant.update()
	}
}

extension StatsViewController {
	var baseContentTypeChoiceMenuItemRepresentatives: [BaseContentTypeChoice?] {
		return [
			.LocalHTMLPages,
			.Images,
			.Feeds
		]
	}
	
	func updateBaseContentTypeChoiceUI() {
		let popUpButton = baseContentTypeChoicePopUpButton
		
		if pageMapper == nil {
			popUpButton.hidden = true
			return
		}
		
		popUpButton.hidden = false
		
		let popUpButtonAssistant = baseContentTypeChoicePopUpButtonAssistant ?? {
			let popUpButtonAssistant = PopUpButtonAssistant<BaseContentTypeChoice>(popUpButton: popUpButton)
			
			let menuAssistant = popUpButtonAssistant.menuAssistant
			menuAssistant.titleReturner = { choice in
				let baseContentType = choice.baseContentType
				let requestedURLCount = self.pageMapper.numberOfRequestedURLsWithBaseContentType(baseContentType)
				let loadedURLCount = self.pageMapper.numberOfLoadedURLsWithBaseContentType(baseContentType)
				return "\(choice.title) (\(loadedURLCount)/\(requestedURLCount))"
			}
			
			self.baseContentTypeChoicePopUpButtonAssistant = popUpButtonAssistant
			return popUpButtonAssistant
		}()
		
		popUpButtonAssistant.menuItemRepresentatives = baseContentTypeChoiceMenuItemRepresentatives
		popUpButtonAssistant.update()
	}
}

extension StatsViewController {
	func updateColumnsModeUI() {
		let allowedColumnsModes = self.allowedColumnsModes
		let segmentedControl = columnsModeSegmentedControl
		
		if pageMapper != nil {
			segmentedControl.hidden = false
			
			let segmentedControlAssistant = columnsModeSegmentedControlAssistant ?? {
				let segmentedControlAssistant = SegmentedControlAssistant<StatsColumnsMode>(segmentedControl: segmentedControl)
				
				self.columnsModeSegmentedControlAssistant = segmentedControlAssistant
				return segmentedControlAssistant
				}()
			
			segmentedControlAssistant.segmentedItemRepresentatives = allowedColumnsModes
			segmentedControlAssistant.update()
			
			if segmentedControlAssistant.selectedUniqueIdentifier == nil {
				// If previous is not allowed, choose the first columns mode.
				changeColumnsMode(allowedColumnsModes[0], updateUI: false)
			}
			
			segmentedControlAssistant.selectedItemRepresentative = selectedColumnsMode
		}
		else {
			segmentedControl.hidden = true
		}
	
		updateColumnsToOnlyShow(selectedColumnsMode.columnIdentifiersForBaseContentType(filterToBaseContentType))
	}

}

extension StatsViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if item == nil {
			return filteredURLs.count
		}
		
		return 0
	}
	
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		return filteredURLs[index]
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		return false
	}
	
	func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
		return item
	}
	
	func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		
		if
			let pageURL = item as? NSURL,
			let identifierString = tableColumn?.identifier,
			let identifier = PagePresentedInfoIdentifier(rawValue: identifierString)
		{
			var cellIdentifier = (identifier == .requestedURL ? "requestedURL" : "text")
			
			//var validatedStringValue: ValidatedStringValue
			var stringValue: String?
			var opacity: CGFloat = 1.0
			
			if pageMapper.hasFinishedRequestingURL(pageURL)
			{
				if let pageInfo = pageMapper.pageInfoForRequestedURL(pageURL) {
					stringValue = identifier.stringValueInPageInfo(pageInfo)
				}
			}
			else {
				if identifier == .requestedURL {
					stringValue = pageURL.relativePath
				}
				else {
					stringValue = "(loading)"
					opacity = 0.2
				}
			}
			
			if stringValue == nil {
				stringValue = "(none)"
				opacity = 0.3
			}
			else if stringValue == "" {
				stringValue = "(empty)"
				opacity = 0.3
			}
			
			if let view = outlineView.makeViewWithIdentifier(cellIdentifier, owner: self) as? NSTableCellView {
				view.textField?.stringValue = stringValue!
				view.alphaValue = opacity
				
				//view.menu = rowMenu

				return view
			}
		}
		
		return nil
	}
}
