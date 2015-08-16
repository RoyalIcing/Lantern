(function() {
	if (window.location.hostname != "hoverlytics.burntcaramel.com") {
		return;
	}
	
	// Make sure Backbone app has been created by queuing in jQuery's ready.
	jQuery(document).ready(function() {
		var hoverlyticsApp = window.App;
		if (hoverlyticsApp) {
			var profile = hoverlyticsApp.profile;
			profile.on('change:isAuthorized', function() {
				var token = gapi.auth.getToken();
				window.webkit.messageHandlers.googleAPIAuthorizationChanged.postMessage({
					tokenJSONString: JSON.stringify(token)
				});
			}, window);
		}
	});
})();