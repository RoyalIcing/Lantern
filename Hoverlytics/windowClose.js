(function() {
	var oldWindowClose = window.close;
	window.close = function() {
		window.webkit.messageHandlers.windowDidClose.postMessage(true);
	
		oldWindowClose();
	};
})();