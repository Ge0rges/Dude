Parse.Cloud.define("updateLastSeen", function(request, response) {

	//Use the master key so we can use administrative access and modify fields on user objects:
	Parse.Cloud.useMasterKey();

	if (request.params.email && request.params["data"]) {
		var query = new Parse.Query(Parse.User);
		query.equalTo('email', request.params.email);
		query.first({
			success: function(user) {
				var mutableLastSeenDictionariesArray = user.lastSeen.slice(0);

				for (var i = 0; i < mutableLastSeenDictionariesArray.length; i++) {
					var lastSeen = mutableLastSeenDictionariesArray[i];

					if (lastSeen[response.params.email]) {
						i = mutableLastSeenDictionariesArray.length+1;
						mutableLastSeenDictionariesArray.splice(i, 1, request.params["builtDictionary"]);

						user.lastSeens = mutableLastSeenDictionariesArray;
						user.save;
					}
				}
			},

			error: function(error) {
				response.error(error.code, "Error: " + error.message);
			}
		});

	} else {
		response.error("No 'email' pr 'data' object was delivered in the payload.");
	}
});
