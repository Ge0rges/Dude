Parse.Cloud.define("updateLastSeen", function(request, response) {
	
	//Use the master key so we can use administrative access and modify fields on user objects:
	Parse.Cloud.useMasterKey();

	//Check for the "lastSeen" key from the parameters
	if (request.params.lastSeen) {
		
		//Try to access the "lastSeens" dictionary from the payload:
		var clone = request.params.lastSeen.slice(0);//Create a mutable copy of the dictionary
		var timeStamp = new Date().getTime();
		var key = (email + timeStamp);
		clone[request.params.email] = request.params.lastSeen;
		clone[key] = timeStamp;
		
		//Get user using `request.params.email`
		var query = new Parse.Query(Parse.User);
		query.get(userID, {
		    success: function(_user) {
			    
			    console.log("Found user: " + _user);
		        
				var relation = _user.relation("currentMeeting");
	            relation.add(_meeting);
	
	            _user.save(null, {
	                success:function(){ /*Success asigning meeting relation for user*/},
	                error:function(error){throw "*** WARNING: Relation error: " + error.code;}
	            });
		        
		    },
		    error: function() {
		        response.error("Failed to find user with email: `" + request.params.email + "`");
		    }
		});				
					
		//user set object: clone for key:"lastSeens"
		
		
	}
	else {
		
		response.error("No `lastSeen` object was delivered in the payload.");
		
	}

});
