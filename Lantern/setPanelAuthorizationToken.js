(function() {
	if (window.location.hostname != "hoverlytics.burntcaramel.com") {
		return;
	}
	
	window.webkit.messageHandlers.googleAPIAuthorizationChanged.postMessage({
		googleClientAPILoaded: false,
		addGoogleClientAPIReadyCallback: (typeof window.addGoogleClientAPIReadyCallback)
	});
	
	var token = __TOKEN__;
	
	window.addGoogleClientAPIReadyCallback(function() {
		gapi.auth.setToken(token);
		
		window.webkit.messageHandlers.googleAPIAuthorizationChanged.postMessage({
			googleClientAPILoaded: true,
			setToken: (typeof gapi.auth.setToken),
			getToken: JSON.stringify(gapi.auth.getToken())
		});
	});
	
	// Make sure Backbone app has been created by queuing in jQuery's ready.
	jQuery(document).ready(function() {
		var hoverlyticsApp = window.App;
		if (hoverlyticsApp) {
			var profile = hoverlyticsApp.profile;
			
			/*
			var oldCheckGoogleAuthorization = profile.checkGoogleAuthorization;
			
			profile.checkGoogleAuthorization = function() {
				window.webkit.messageHandlers.googleAPIAuthorizationChanged.postMessage({
					googleClientAPILoaded: true,
					changeProfileMethod: true
				});
				
				//oldCheckGoogleAuthorization({performAuthorization: false});
				profile.handleGoogleAuthorizationResult(token);
			};
			*/
			
			var oldHandleGoogleAuthorizationResult = profile.handleGoogleAuthorizationResult
			
			profile.handleGoogleAuthorizationResult = function(authorizationResult) {
				window.webkit.messageHandlers.googleAPIAuthorizationChanged.postMessage({
					googleClientAPILoaded: true,
					authorizationResult: JSON.stringify(authorizationResult)
				});
				
				oldHandleGoogleAuthorizationResult.call(profile, authorizationResult);
			}
		}
	});
})();