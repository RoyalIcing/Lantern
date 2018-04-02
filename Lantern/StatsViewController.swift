//
//	StatsViewController.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 24/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation
import BurntCocoaUI
import LanternModel
import Quartz


enum BaseContentTypeChoice: Int {
	case localHTMLPages = 1
	case images
	case feeds
	
	var baseContentType: BaseContentType {
		switch self {
		case .localHTMLPages:
			return .localHTMLPage
		case .images:
			return .image
		case .feeds:
			return .feed
		}
	}
}

extension BaseContentTypeChoice: UIChoiceRepresentative {
	var title: String {
		switch self {
		case .localHTMLPages:
			return "Local Pages"
		case .images:
			return "Images"
		case .feeds:
			return "Feeds"
		}
	}
	
	typealias UniqueIdentifier = BaseContentTypeChoice
	var uniqueIdentifier: UniqueIdentifier { return self }
}


enum StatsFilterResponseChoice: Int {
	case all = 0
	
	case successful = 2
	case redirects = 3
	case requestErrors = 4
	case responseErrors = 5
	
	case validInformation = 100
	case problematicMIMEType = 101
	case problematicPageTitle = 102
	case problematicHeading = 103
	case problematicMetaDescription = 104
	
	case isLinkedByBrowsedPage = 200
	case containsLinkToBrowsedPage = 201
	
	
	var responseType: PageResponseType? {
		switch self {
		case .successful:
			return .successful
		case .redirects:
			return .redirects
		case .requestErrors:
			return .requestErrors
		case .responseErrors:
			return .responseErrors
		default:
			return nil
		}
	}
	
	var validationArea: PageInfoValidationArea? {
		switch self {
		case .problematicMIMEType:
			return .mimeType
		case .problematicHeading:
			return .h1
		case .problematicPageTitle:
			return .Title
		case .problematicMetaDescription:
			return .metaDescription
		default:
			return nil
		}
	}
	
	func pageLinkFilterWithURL(_ URL: Foundation.URL) -> PageLinkFilter? {
		switch self {
		case .isLinkedByBrowsedPage:
			return .isLinkedByURL(URL)
		case .containsLinkToBrowsedPage:
			return .containsLinkToURL(URL)
		default:
			return nil
		}
	}
}

extension StatsFilterResponseChoice: UIChoiceRepresentative {
	var title: String {
		switch self {
		case .all:
			return "All"
			
		case .successful:
			return "Successful 2xx"
		case .redirects:
			return "Redirects 3xx"
		case .requestErrors:
			return "Client Errors 4xx"
		case .responseErrors:
			return "Server Errors 5xx"
			
		case .validInformation:
			return "Valid Information"
			
		case .problematicMIMEType:
			return "Invalid MIME Types"
		case .problematicHeading:
			return "Invalid Headings"
		case .problematicPageTitle:
			return "Invalid Page Titles"
		case .problematicMetaDescription:
			return "Invalid Meta Description"
			
		case .isLinkedByBrowsedPage:
			return "Linked by Browsed Page"
		case .containsLinkToBrowsedPage:
			return "Contains Link to Browsed Page"
		}
	}
	
	var tag: Int? { return rawValue }
	
	typealias UniqueIdentifier = StatsFilterResponseChoice
	var uniqueIdentifier: UniqueIdentifier { return self }
}

enum StatsColumnsMode: Int {
	case titles = 1
	case descriptions = 2
	case types = 3
	case downloadSizes = 4
	case links = 5
	
	func columnIdentifiersForBaseContentType(_ baseContentType: BaseContentType) -> [PagePresentedInfoIdentifier] {
		switch self {
		case .titles:
			return [.pageTitle, .h1]
		case .descriptions:
			return [.metaDescription, .pageTitle]
		case .types:
			return [.statusCode, .MIMEType]
		case .downloadSizes:
			switch baseContentType {
			case .localHTMLPage:
				return [.pageByteCount, .pageByteCountBeforeBodyTag, .pageByteCountAfterBodyTag]
			default:
				return [.pageByteCount]
			}
		case .links:
			return [.internalLinkCount, .externalLinkCount]
		}
	}
	
	var title: String {
		switch self {
		case .titles:
			return "Titles"
		case .descriptions:
			return "Descriptions"
		case .types:
			return "Types"
		case .downloadSizes:
			return "Sizes"
		case .links:
			return "Links"
		}
	}
}

extension StatsColumnsMode: UIChoiceRepresentative {
	var tag: Int? { return rawValue }
	
	typealias UniqueIdentifier = StatsColumnsMode
	var uniqueIdentifier: UniqueIdentifier { return self }
}

extension StatsColumnsMode: CustomStringConvertible {
	var description: String {
		return title
	}
}

extension StatsFilterResponseChoice {
	var preferredColumnsMode: StatsColumnsMode? {
		switch self {
		case .problematicMIMEType:
			return .types
		case .problematicPageTitle, .problematicHeading:
			return .titles
		case .problematicMetaDescription:
			return .descriptions
		default:
			return nil
		}
	}
}

extension BaseContentTypeChoice {
	var allowedColumnsModes: [StatsColumnsMode] {
		switch self {
		case .localHTMLPages:
			return [.titles, .descriptions, .types, .downloadSizes, .links]
		default:
			return [.types, .downloadSizes]
		}
	}
}

extension PageResponseType {
	var cocoaColor: NSColor {
		switch self {
		case .requestErrors, .responseErrors:
			return NSColor(srgbRed: 233.0/255.0, green: 36.0/255.0, blue: 0.0, alpha: 1.0)
		default:
			return NSColor.textColor
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
	var baseContentTypeChoicePopUpButtonAssistant: PopUpButtonAssistant<BaseContentTypeChoice>!
	
	var rowMenu: NSMenu!
	var rowMenuAssistant: MenuAssistant<MenuActions>!
	
	let crawlerPreferences = CrawlerPreferences.sharedCrawlerPreferences
	var crawlerPreferencesObserver: NotificationObserver<CrawlerPreferences.Notification>!
	
	
	lazy var pageMapperListenerUUID = UUID()
	
	var browsedURL: URL?
	
	var chosenBaseContentChoice: BaseContentTypeChoice = .localHTMLPages
	var filterToBaseContentType: BaseContentType {
		return chosenBaseContentChoice.baseContentType
	}
	var filterResponseChoice: StatsFilterResponseChoice = .all
	var selectedColumnsMode: StatsColumnsMode = .titles
	var allowedColumnsModes: [StatsColumnsMode] {
		return chosenBaseContentChoice.allowedColumnsModes
	}
	
	var filteredURLs = [URL]()
	
	var didChooseURLCallback: ((_ URL: URL, _ pageInfo: PageInfo) -> ())?
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
		
		outlineView.removeTableColumn(outlineView.tableColumn(withIdentifier: "text")!)

		//updateColumnsToOnlyShow(selectedColumnsMode.columnIdentifiersForBaseContentType(filterToBaseContentType))

		outlineView.dataSource = self
		outlineView.delegate = self

		outlineView.target = self
		outlineView.doubleAction = #selector(StatsViewController.doubleClickSelectedRow(_:))

		createRowMenu()

		updateUI()

		startObservingCrawlerPreferences()
	}
	
	deinit {
		stopObservingCrawlerPreferences()
	}
	
	func startObservingCrawlerPreferences() {
		crawlerPreferencesObserver = NotificationObserver<CrawlerPreferences.Notification>(object: crawlerPreferences)
		
		crawlerPreferencesObserver.observe(.ImageDownloadChoiceDidChange) { [weak self] notification in
			self?.updateMaximumImageDownload()
		}
	}
	
	func stopObservingCrawlerPreferences() {
		crawlerPreferencesObserver.stopObserving()
		crawlerPreferencesObserver = nil
	}
	
	var primaryURL: URL! {
		didSet {
			browsedURL = primaryURL
			crawl()
		}
	}
	
	var pageMapper: PageMapper? {
		return pageMapperProvider?.pageMapper
	}
	
	func updateMaximumImageDownload() {
		if let pageMapper = pageMapper {
			let maximumImageByteCount = crawlerPreferences.imageDownloadChoice.maximumByteCount
			pageMapper.setMaximumByteCount(maximumImageByteCount, forBaseContentType: .image)
		}
	}
	
	func didNavigateToURL(_ URL: Foundation.URL, crawl: Bool) {
		if let pageMapper = pageMapper {
			browsedURL = URL
			updateListOfURLs()
			
			if crawl {
				pageMapper.addAdditionalURL(URL)
			}
		}
		else {
			primaryURL = URL
		}
	}
	
	var clickedRow: Int? {
		let row = outlineView.clickedRow
		if row != -1 {
			return row
		}
		else {
			return nil
		}
	}
	
	var clickedColumn: Int? {
		let column = outlineView.clickedColumn
		if column != -1 {
			return column
		}
		else {
			return nil
		}
	}
	
	var soloSelectedRow: Int? {
		let row = outlineView.selectedRow
		if row != -1 {
			return row
		}
		else {
			return nil
		}
	}
	
	var selectedURLs: [URL] {
		get {
			let selectedRowIndexes = outlineView!.selectedRowIndexes
			return selectedRowIndexes.flatMap { row in
				return outlineView.item(atRow: row) as? URL
			}
		}
		set {
			let outlineView = self.outlineView!
			let newRowIndexes = NSMutableIndexSet()
			for URL in newValue {
				let row = outlineView.row(forItem: URL)
				if row != -1 {
					newRowIndexes.add(row)
				}
			}
			outlineView.selectRowIndexes(newRowIndexes as IndexSet, byExtendingSelection: false)
		}
	}
	
	var previouslySelectedURLs = [URL]()
	
	func updateListOfURLs() {
		if let pageMapper = pageMapper {
			let baseContentType = filterToBaseContentType
			if filterResponseChoice == .all {
				filteredURLs = pageMapper.copyURLsWithBaseContentType(baseContentType)
			}
			else if let responseType = filterResponseChoice.responseType {
				filteredURLs = pageMapper.copyURLsWithBaseContentType(baseContentType, withResponseType: responseType)
			}
			else if filterResponseChoice == .validInformation {
				filteredURLs = pageMapper.copyHTMLPageURLsWhichCompletelyValidateForType(baseContentType)
			}
			else if let validationArea = filterResponseChoice.validationArea {
				filteredURLs = pageMapper.copyHTMLPageURLsForType(baseContentType, failingToValidateInArea: validationArea)
			}
			else if
				let browsedURL = browsedURL,
				let pageLinkFilter = filterResponseChoice.pageLinkFilterWithURL(browsedURL)
			{
				#if DEBUG
					print("filtering to browsedURL \(browsedURL)")
				#endif
				filteredURLs = pageMapper.copyHTMLPageURLsFilteredBy(pageLinkFilter)
			}
			else {
				fatalError("filterResponseChoice must be set to something valid")
			}
		}
		else {
			filteredURLs = []
		}
		
		outlineView.reloadData()
		
		self.selectedURLs = previouslySelectedURLs
	}
	
	func updateUI(
		_ baseContentType: Bool = true,
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
	
	func crawl() {
		if
			let primaryURL = self.primaryURL,
			let pageMapperProvider = self.pageMapperProvider
		{
			guard let pageMapper = pageMapperProvider.createPageMapper(primaryURL: primaryURL)
				else { return }
			
			pageMapper[didUpdateCallback: pageMapperListenerUUID] = { loadedPageURL in
				self.pageURLDidUpdate(loadedPageURL)
			}
			
			updateMaximumImageDownload()
			
			pageMapper.reload()
		}
		
		updateListOfURLs()
		updateUI()
	}
	
	var updateUIWithProgressOperation: BlockOperation!
	
	fileprivate func pageURLDidUpdate(_ pageURL: URL) {
		// Update the UI with a background quality of service using an operation.
		if updateUIWithProgressOperation == nil {
			let updateUIWithProgressOperation = BlockOperation(block: {
				self.updateUI()
				self.updateUIWithProgressOperation = nil
			})
			OperationQueue.main.addOperation(updateUIWithProgressOperation)
			self.updateUIWithProgressOperation = updateUIWithProgressOperation
		}
	}
	
	fileprivate func updateColumnsToOnlyShow(_ columnIdentifiers: [PagePresentedInfoIdentifier]) {
		func updateHeaderOfColumn(_ column: NSTableColumn, withTitleFromIdentifier identifier: PagePresentedInfoIdentifier) {
			column.headerCell.stringValue = identifier.titleForBaseContentType(filterToBaseContentType)
		}
		
		let minColumnWidth: CGFloat = 130.0
		
		outlineView.beginUpdates()
		
		let uniqueColumnIdentifiers = Set(columnIdentifiers)
		let existingTableColumnIdentifierStrings = outlineView.tableColumns.map { return $0.identifier }
		for identifierString in existingTableColumnIdentifierStrings {
			if let identifier = PagePresentedInfoIdentifier(rawValue: identifierString) , !uniqueColumnIdentifiers.contains(identifier) && identifier != .requestedURL {
				outlineView.removeTableColumn(outlineView.tableColumn(withIdentifier: identifierString)!)
			}
		}
		
		let columnsRemainingWidth = outlineView.enclosingScrollView!.documentVisibleRect.width - outlineView.outlineTableColumn!.width - 12.0
		let columnWidth = max(columnsRemainingWidth / CGFloat(columnIdentifiers.count), minColumnWidth)
		
		var columnIndex = 1 // After outline column
		for identifier in columnIdentifiers {
			let existingColumnIndex = outlineView.column(withIdentifier: identifier.rawValue)
			var tableColumn: NSTableColumn
			if existingColumnIndex >= 0 {
				tableColumn = outlineView.tableColumn(withIdentifier: identifier.rawValue)!
				outlineView.moveColumn(existingColumnIndex, toColumn: columnIndex)
			}
			else {
				tableColumn = NSTableColumn(identifier: identifier.rawValue)
				outlineView.addTableColumn(tableColumn)
			}
			
			tableColumn.minWidth = 60.0
			tableColumn.width = columnWidth
			updateHeaderOfColumn(tableColumn, withTitleFromIdentifier: identifier)
			
			columnIndex += 1
		}
		
		updateHeaderOfColumn(outlineView.outlineTableColumn!, withTitleFromIdentifier: .requestedURL)
		
		outlineView.endUpdates()
		
		//outlineView.resizeSubviewsWithOldSize(outlineView.bounds.rectByInsetting(dx: 1.0, dy: 0.0).size)
		//outlineView.resizeWithOldSuperviewSize(outlineView.bounds.size)
		outlineView.reloadData()
	}
	
	func changeColumnsMode(_ columnsMode: StatsColumnsMode, updateUI: Bool = true) {
		selectedColumnsMode = columnsMode
		
		if updateUI {
			updateColumnsModeUI()
			
			//columnsModeSegmentedControlAssistant?.selectedItemRepresentative = columnsMode
			
			//updateColumnsToOnlyShow(columnsMode.columnIdentifiersForBaseContentType(filterToBaseContentType))
		}
	}
	
	@IBAction func changeBaseContentTypeFilter(_ sender: NSPopUpButton) {
		if let contentChoice = baseContentTypeChoicePopUpButtonAssistant.selectedItemRepresentative {
			chosenBaseContentChoice = contentChoice
			
			updateUI(false)
		}
	}
	
	@IBAction func changeResponseTypeFilter(_ sender: NSPopUpButton) {
		let menuItem = sender.selectedItem!
		let tag = menuItem.tag
		
		filterResponseChoice = StatsFilterResponseChoice(rawValue: tag)!
		if let preferredColumnsMode = filterResponseChoice.preferredColumnsMode {
			changeColumnsMode(preferredColumnsMode)
		}
		
		updateUI(filterResponseChoice: false)
	}
	
	#if false
	
	@IBAction func showTitleColumns(sender: AnyObject?) {
		changeColumnsMode(StatsColumnsMode.Titles)
	}
	
	@IBAction func showDescriptionColumns(sender: AnyObject?) {
		changeColumnsMode(StatsColumnsMode.Descriptions)
	}
	
	@IBAction func showDownloadSizesColumns(sender: AnyObject?) {
		changeColumnsMode(StatsColumnsMode.DownloadSizes)
	}
	
	#endif
	
	@IBAction func changeColumnsMode(_ sender: NSSegmentedControl) {
		if let columnsMode = columnsModeSegmentedControlAssistant?.selectedItemRepresentative {
			changeColumnsMode(columnsMode)
		}
	}
	
	func showPreviewForRow(_ row: Int) {
		if let
			URL = outlineView.item(atRow: row) as? URL,
			let pageMapper = pageMapper,
			let info = pageMapper.pageInfoForRequestedURL(URL)
		{
			if info.contentInfo == nil {
				pageMapper.priorityRequestContentIfNeededForURL(URL, expectedBaseContentType: info.baseContentType)
				return
			}
			
			switch info.baseContentType {
			case .localHTMLPage:
				showSourcePreviewForPageAtRow(row)
			case .image:
				showImagePreviewForResourceAtRow(row)
			case .feed:
				showSourcePreviewForPageAtRow(row)
			default:
				break
			}
		}
	}
	
	@IBAction func doubleClickSelectedRow(_ sender: AnyObject?) {
		if let row = clickedRow, let column = clickedColumn {
			if
				let URL = outlineView.item(atRow: row) as? URL,
				let pageInfo = pageMapper?.pageInfoForRequestedURL(URL)
			{
				// Double clicking requested URL chooses that URL.
				if column == 0 {
					switch pageInfo.baseContentType {
					case .localHTMLPage:
						didChooseURLCallback?(URL, pageInfo)
					default:
						showPreviewForRow(row)
					}
				}
				else {
					showStringValuePreviewForResourceAtRow(row, column: column)
				}
			}
		}
	}
	
	@IBAction func pauseCrawling(_ sender: AnyObject?) {
		//pageMapper?.pauseCrawling()
		pageMapper?.cancel()
	}
	
	@IBAction func recrawl(_ sender: AnyObject?) {
		//pageMapper?.pauseCrawling()
		pageMapper?.cancel()
	}
	
	override func responds(to selector: Selector) -> Bool {
		switch selector {
		case #selector(StatsViewController.pauseCrawling(_:)):
			return pageMapper?.isCrawling ?? false
		default:
			return super.responds(to: selector)
		}
	}
}

// TODO: finish quicklook support, needs a local file cache
extension StatsViewController: QLPreviewPanelDataSource, QLPreviewPanelDelegate {
	override func keyDown(with theEvent: NSEvent) {
		if let charactersIgnoringModifiers = theEvent.charactersIgnoringModifiers {
			let u = charactersIgnoringModifiers[charactersIgnoringModifiers.startIndex]
			
			if u == Character(" ") {
				if let row = soloSelectedRow {
					showPreviewForRow(row)
				}
				// TODO: enable again
				//quickLookPreviewItems(self)
			}
		}
	}
	
	override func quickLookPreviewItems(_ sender: Any?)
	{
		if let pageMapper = pageMapper {
			let selectedRowIndexes = outlineView.selectedRowIndexes
			if selectedRowIndexes.count == 1 {
				let row = selectedRowIndexes.first
				if let pageURL = outlineView.item(atRow: row!) as? URL , pageMapper.hasFinishedRequestingURL(pageURL)
				{
					
				}
			}
		}
	}
	
	func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
		return selectedURLs.count
	}
	
	func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
		return selectedURLs[index] as QLPreviewItem?
	}
	
	override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
		return true
	}
	
	override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
		panel.delegate = self
	}
	
	override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
		panel.delegate = nil
	}
}


extension StatsViewController {
	enum MenuActions: String {
		case browsePage
		case showSourcePreview
		case expandValue
		case showImagePreview
		case copyURL
		
		var selector: Selector {
			switch self {
			case .browsePage: return #selector(StatsViewController.browsePageAtSelectedRow(_:))
			case .showSourcePreview: return #selector(StatsViewController.showSourcePreviewForPageAtSelectedRow(_:))
			case .expandValue: return #selector(StatsViewController.showStringValuePreviewForResourceAtSelectedRow(_:))
			case .showImagePreview: return #selector(StatsViewController.showImagePreviewForResourceAtSelectedRow(_:))
			case .copyURL: return #selector(StatsViewController.copyURLForSelectedRow(_:))
			}
		}
	}
}

extension StatsViewController.MenuActions : UIChoiceRepresentative {
	var title: String {
		switch self {
		case .browsePage:
			return "Browse Page"
		case .showSourcePreview:
			return "Show Source"
		case .expandValue:
			return "Expand This Value"
		case .showImagePreview:
			return "Show Image Preview"
		case .copyURL:
			return "Copy URL"
		}
	}
	
	var tag: Int? { return nil }
	
	typealias UniqueIdentifier = String
	var uniqueIdentifier: UniqueIdentifier {
		return rawValue
	}
}

extension StatsViewController {
	func createRowMenu() {
		let menu = NSMenu(title: "Row Menu")
		
		rowMenuAssistant = MenuAssistant<MenuActions>(menu: menu)
		
		rowMenuAssistant.customization.actionAndTarget = { itemRepresentative in
			return (action: itemRepresentative.selector, target: self)
		}
		
		self.rowMenu = menu
	}
	
	func rowMenuItemRepresentativesForResourceInfo(_ info: PageInfo) -> [MenuActions?] {
		switch info.baseContentType {
		case .localHTMLPage, .feed:
			return [
				.browsePage,
				.showSourcePreview,
				.expandValue,
				nil,
				.copyURL
			]
		case .image:
			if
				let contentInfo = info.contentInfo
				// Does not allow SVG preview for now, as needs a WKWebView or similar
				, info.MIMEType?.stringValue != "image/svg+xml" && NSBitmapImageRep.canInit(with: contentInfo.data)
			{
				return [
					.showImagePreview,
					.expandValue,
					nil,
					.copyURL
				]
			}
			else {
				fallthrough
			}
		default:
			return [
				.expandValue,
				nil,
				.copyURL
			]
		}
	}
	
	func menuForResourceInfo(_ info: PageInfo) -> NSMenu {
		rowMenuAssistant.menuItemRepresentatives = rowMenuItemRepresentativesForResourceInfo(info)
		return rowMenuAssistant.update()
	}
	
	@IBAction func browsePageAtSelectedRow(_ sender: AnyObject?) {
		if let
			row = clickedRow,
			let URL = outlineView.item(atRow: row) as? URL,
			let pageInfo = pageMapper?.pageInfoForRequestedURL(URL)
		{
			didChooseURLCallback?(URL, pageInfo)
		}
	}
	
	@IBAction func showSourcePreviewForPageAtSelectedRow(_ menuItem: NSMenuItem) {
		if let row = clickedRow {
			showSourcePreviewForPageAtRow(row)
		}
	}
	
	@IBAction func showStringValuePreviewForResourceAtSelectedRow(_ menuItem: NSMenuItem) {
		if let row = clickedRow, let column = clickedColumn {
			showStringValuePreviewForResourceAtRow(row, column: column)
		}
	}
	
	@IBAction func showImagePreviewForResourceAtSelectedRow(_ menuItem: NSMenuItem) {
		if let row = clickedRow {
			showImagePreviewForResourceAtRow(row)
		}
	}
	
	@IBAction func copyURLForSelectedRow(_ menuItem: NSMenuItem) {
		if let row = clickedRow {
			performCopyURLForURLAtRow(row)
		}
	}
	
	func showSourcePreviewForPageAtRow(_ row: Int) {
		if
			let pageURL = outlineView.item(atRow: row) as? URL,
			let pageMapper = pageMapper , pageMapper.hasFinishedRequestingURL(pageURL)
		{
			if let pageInfo = pageMapper.pageInfoForRequestedURL(pageURL) {
				let sourcePreviewTabViewController = SourcePreviewTabViewController()
				sourcePreviewTabViewController.pageInfo = pageInfo
				
				let rowRect = outlineView.rect(ofRow: row)
				presentViewController(sourcePreviewTabViewController, asPopoverRelativeTo: rowRect, of: outlineView, preferredEdge: NSRectEdge.minY, behavior: .semitransient)
			}
		}
	}
	
	func presentedInfoIdentifierForTableColumn(_ tableColumn: NSTableColumn) -> PagePresentedInfoIdentifier? {
		return PagePresentedInfoIdentifier(rawValue: tableColumn.identifier)
	}
	
	func showStringValuePreviewForResourceAtRow(_ row: Int, column: Int) {
		let tableColumn = outlineView.tableColumns[column] 
		
		if
			let presentedInfoIdentifier = presentedInfoIdentifierForTableColumn(tableColumn),
			let pageURL = outlineView.item(atRow: row) as? URL,
			let pageMapper = pageMapper
		{
			let presentedInfoIdentifier = presentedInfoIdentifier.longerFormInformation ?? presentedInfoIdentifier
			
			if let pageInfo = pageMapper.pageInfoForRequestedURL(pageURL) {
				let validatedStringValue = presentedInfoIdentifier.validatedStringValueInPageInfo(pageInfo, pageMapper: pageMapper)
				
				let previewViewController = MultipleStringPreviewViewController.instantiateFromStoryboard()
				switch validatedStringValue {
				case .multiple(let values):
					previewViewController.validatedStringValues = values
				default:
					previewViewController.validatedStringValues = [validatedStringValue]
				}
				
				let rowRect = outlineView.frameOfCell(atColumn: column, row: row)
				presentViewController(previewViewController, asPopoverRelativeTo: rowRect, of: outlineView, preferredEdge: NSRectEdge.minY, behavior: .semitransient)
			}
		}
	}
	
	func showImagePreviewForResourceAtRow(_ row: Int) {
		if
			let pageURL = outlineView.item(atRow: row) as? URL,
			let pageMapper = pageMapper , pageMapper.hasFinishedRequestingURL(pageURL)
		{
			if
				let pageInfo = pageMapper.pageInfoForRequestedURL(pageURL),
				let contentInfo = pageInfo.contentInfo
			{
				let previewViewController = ImagePreviewViewController.instantiateFromStoryboard()
				previewViewController.imageData = contentInfo.data
				previewViewController.MIMEType = pageInfo.MIMEType?.stringValue
				previewViewController.sourceURL = pageInfo.requestedURL
				
				let rowRect = outlineView.rect(ofRow: row)
				presentViewController(previewViewController, asPopoverRelativeTo: rowRect, of: outlineView, preferredEdge: NSRectEdge.minY, behavior: .semitransient)
			}
		}

	}
	
	func performCopyURLForURLAtRow(_ row: Int) {
		if let url = outlineView.item(atRow: row) as? URL
		{
			let pasteboard = NSPasteboard.general()
			pasteboard.clearContents()
			// This does not copy the URL as a string though
			//let success = pasteboard.writeObjects([URL])
			//println("Copying \(success) \(pasteboard) \(URL)")
			pasteboard.declareTypes([NSURLPboardType, NSStringPboardType], owner: nil)
			(url as NSURL).write(to: pasteboard)
			pasteboard.setString(url.absoluteString, forType: NSStringPboardType)
		}
	}
}

extension StatsViewController {
	func menuItemRepresentativesForFilterResponseChoice() -> [StatsFilterResponseChoice?] {
		switch filterToBaseContentType {
		case .localHTMLPage:
			return [
				.all,
				nil,
				.successful,
				//.Redirects,
				.requestErrors,
				.responseErrors,
				nil,
				.validInformation,
				//.ProblematicMIMEType,
				.problematicPageTitle,
				.problematicHeading,
				.problematicMetaDescription,
				nil,
				.isLinkedByBrowsedPage,
				.containsLinkToBrowsedPage
			]
		default:
			return [
				.all,
				nil,
				.successful,
				//.Redirects,
				.requestErrors,
				.responseErrors,
				//nil,
				//.ValidInformation,
				//.ProblematicMIMEType,
			]
		}
	}
	
	func updateFilterResponseChoiceUI() {
		let popUpButton = filterResponseChoicePopUpButton!
		
		if pageMapper == nil {
			popUpButton.animator().isHidden = true
			return
		}
		else {
			popUpButton.animator().isHidden = false
		}
		
		let popUpButtonAssistant = filterResponseChoicePopUpButtonAssistant ?? {
			let popUpButtonAssistant = PopUpButtonAssistant<StatsFilterResponseChoice>(popUpButton: popUpButton)
			
			let menuAssistant = popUpButtonAssistant.menuAssistant
			menuAssistant.customization.title = { choice in
				switch choice {
				case .all:
					let baseContentType = self.filterToBaseContentType
					switch baseContentType {
					case .localHTMLPage:
						return "All Local Pages"
					case .image:
						return "All Images"
					case .feed:
						return "All Feeds"
					default:
						fatalError("Unimplemented base content type")
					}
				case .successful, .redirects, .requestErrors, .responseErrors:
					let baseContentType = self.filterToBaseContentType
					let responseType = choice.responseType!
					let URLCount = self.pageMapper?.numberOfLoadedURLsWithBaseContentType(baseContentType, responseType: responseType) ?? 0
					return "\(choice.title) (\(URLCount))"
				default:
					return choice.title
				}
			}
			menuAssistant.customization.tag = { choice in
				return choice.rawValue
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
			.localHTMLPages,
			.images,
			.feeds
		]
	}
	
	func updateBaseContentTypeChoiceUI() {
		let popUpButton = baseContentTypeChoicePopUpButton!
		
		if pageMapper == nil {
			popUpButton.animator().isHidden = true
			return
		}
		
		popUpButton.animator().isHidden = false
		
		let popUpButtonAssistant = baseContentTypeChoicePopUpButtonAssistant ?? {
			let popUpButtonAssistant = PopUpButtonAssistant<BaseContentTypeChoice>(popUpButton: popUpButton)
			
			let menuAssistant = popUpButtonAssistant.menuAssistant
			menuAssistant.customization.title = { choice in
				let baseContentType = choice.baseContentType
				let loadedURLCount = self.pageMapper?.numberOfLoadedURLsWithBaseContentType(baseContentType) ?? 0
				return "\(choice.title) (\(loadedURLCount))"
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
		let segmentedControl = columnsModeSegmentedControl!
		
		if pageMapper != nil {
			segmentedControl.animator().isHidden = false
			
			let segmentedControlAssistant = columnsModeSegmentedControlAssistant ?? {
				let segmentedControlAssistant = SegmentedControlAssistant<StatsColumnsMode>(segmentedControl: segmentedControl)
				
				segmentedControlAssistant.customization.tag = { choice in
					return choice.rawValue
				}
				
				self.columnsModeSegmentedControlAssistant = segmentedControlAssistant
				return segmentedControlAssistant
			}()
			
			segmentedControlAssistant.segmentedItemRepresentatives = allowedColumnsModes
			segmentedControlAssistant.update()
			
			if segmentedControlAssistant.selectedUniqueIdentifier == nil {
				// If previous is not allowed, choose the first columns mode.
				changeColumnsMode(allowedColumnsModes[0], updateUI: false)
			}
			
			segmentedControlAssistant.selectedUniqueIdentifier = selectedColumnsMode
		}
		else {
			segmentedControl.animator().isHidden = true
		}
	
		updateColumnsToOnlyShow(selectedColumnsMode.columnIdentifiersForBaseContentType(filterToBaseContentType))
	}

}

extension StatsViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if item == nil {
			return filteredURLs.count
		}
		
		return 0
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		if item == nil {
			return filteredURLs[index]
		}
		
		fatalError("Outline view is only currently one level deep")
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
		return item
	}
	
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		
		if
			let pageURL = item as? URL,
			let identifierString = tableColumn?.identifier,
			let identifier = PagePresentedInfoIdentifier(rawValue: identifierString)
		{
			let cellIdentifier = (identifier == .requestedURL ? "requestedURL" : "text")
			
			var menu: NSMenu?
			var stringValue: String
			var suffixString: String?
			var opacity: CGFloat = 1.0
			var textColor: NSColor = NSColor.textColor
			
			if let pageMapper = pageMapper, pageMapper.hasFinishedRequestingURL(pageURL)
			{
				var validatedStringValue: ValidatedStringValue = .missing
				
				if let pageInfo = pageMapper.pageInfoForRequestedURL(pageURL) {
					validatedStringValue = identifier.validatedStringValueInPageInfo(pageInfo, pageMapper: pageMapper)
					
					if
						let finalURL = pageInfo.finalURL,
						let redirectionInfo = pageMapper.redirectedDestinationURLToInfo[finalURL] {
							if identifier == .statusCode {
								suffixString = String(redirectionInfo.statusCode)
							}
					}
					
					textColor = PageResponseType(statusCode: pageInfo.statusCode).cocoaColor
					
					menu = menuForResourceInfo(pageInfo)
				}
				
				switch validatedStringValue {
				case .notRequested:
					stringValue = "(double-click to download)"
				default:
					stringValue = validatedStringValue.stringValueForPresentation
				}
				
				opacity = validatedStringValue.alphaValueForPresentation
			}
			else {
				let validatedStringValue = identifier.validatedStringValueForPendingURL(pageURL)
				
				switch validatedStringValue {
				case .validString(let string):
					stringValue = string
				case .missing:
					stringValue = "(missing)"
					opacity = 0.2
				default:
					stringValue = "(loading)"
					opacity = 0.2
				}
			}
			
			if let view = outlineView.make(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView {
				if let textField = view.textField {
					if let suffixString = suffixString {
						stringValue += " \(suffixString)"
					}
					
					textField.stringValue = stringValue
					textField.textColor = textColor
				}
				view.alphaValue = opacity
				
				view.menu = menu

				return view
			}
		}
		
		return nil
	}
	
	/* Seem to need both outlineViewSelectionIsChanging and outlineViewSelectionDidChange to correctly get the selection as the outline view updates quickly, either after selecting by mouse clicking or using the up/down arrow keys.
	*/
	func outlineViewSelectionIsChanging(_ notification: Notification)
	{
		previouslySelectedURLs = selectedURLs
	}
	
	func outlineViewSelectionDidChange(_ notification: Notification)
	{
		previouslySelectedURLs = selectedURLs
	}
}
