Parse.Cloud.define("updateLastSeen", function(request, response) {

	//Use the master key so we can use administrative access and modify fields on user objects:
	Parse.Cloud.useMasterKey();

	if (request.params.email && request.params["builtDictionary"]) {
		var query = new Parse.Query(Parse.User);
		query.equalTo('email', request.params.email);
		query.first({
			success: function(user) {
				var mutableLastSeenDictionariesArray = [];

				if (typeof user.lastSeens != 'undefined' && user.lastSeens.length > 0) {
					mutableLastSeenDictionariesArray =	user.lastSeens.slice(0)
				}

				var addedLastSeen = false;

				for (var i = 0; i < mutableLastSeenDictionariesArray.length; i++) {
					var lastSeen = mutableLastSeenDictionariesArray[i];

					if (lastSeen[response.params.email]) {
						i = mutableLastSeenDictionariesArray.length+1;
						mutableLastSeenDictionariesArray.splice(i, 1);// Remove the old last seen
						mutableLastSeenDictionariesArray.splice(0, 0, request.params["builtDictionary"]);// Add at the begining of the array

						addedLastSeen = true;
					}
				}

				if (!addedLastSeen) {
					mutableLastSeenDictionariesArray.splice(0, 0, request.params["builtDictionary"]);// Add at the begining of the array
				}

				user.lastSeens = mutableLastSeenDictionariesArray;
				user.save;
				response.success();
			},

			error: function(error) {
				response.error(error.code, "Error: " + error.message);
			}
		});

	} else {
		response.error("No 'email' or no 'builtDictionary' object was delivered in the payload.");
	}
});
