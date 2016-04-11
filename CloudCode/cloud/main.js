Parse.Cloud.define("updateLastSeen", function(request, response) {

	//Use the master key so we can use administrative access and modify fields on user objects:
	Parse.Cloud.useMasterKey();

	if (request.params["receiverEmail"] && request.params["data"] && request.params["senderEmail"]) {
		var query = new Parse.Query(Parse.User);
		query.equalTo("email", request.params["receiverEmail"]);

		query.first({
			success: function(user) {
					// Remove the old last seen
					for (var i = 0; i < user.get("lastSeens").length; i++) {
						var lastSeen = user.get("lastSeens")[i];// This is a PFFile

						if (lastSeen[0] == response.params["senderEmail"]) {
							user.remove("lastSeens", lastSeen);
							user.save(null, {
									success: function() {
										console.log("User saved after removing. Proceeding...");
								},
									error: function(error) {
										response.error("Couldn't save user after removing lastSeen. Error:" + error.message);
									}
							});

							i = lastSeens.length + 1;
						}
					}

					// Add new lastSeen
					user.add("lastSeens", request.params["data"]);

					user.save(null, {
              success: function() {
								console.log("User saved after adding. Success!");
								response.success("Success.");

						},
              error: function(error) {
								response.error("Couldn't save user after adding lastSeen. Error:" + error.message);
							}
          });
			},

			error: function(error) {
				response.error(error.code, "Error: " + error.message);
			}
		});

	} else {
		response.error("No 'receiverEmail', 'builtDictionary' or 'senderEmail' object was delivered in the payload.");
	}
});
