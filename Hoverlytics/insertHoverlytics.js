(function() {
	if (window.top === window.self) {
		window.webkit.messageHandlers.googleAPIAuthorizationChanged.postMessage({
			googleClientAPILoaded: false,
			loadingHoverlyticsScript: true
		});
		
		var s = document.createElement('script');
		s.src = ('http://hoverlytics.burntcaramel.com/go/v3/go.js?_='+Math.random());
		document.body.appendChild(s);
	}
})();