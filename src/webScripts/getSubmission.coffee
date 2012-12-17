error = false

try
	submission = (OpenLearning.activity.getSubmission request.user).submission
catch err
	error = err

response.setHeader 'Content-Type', 'application/json'

if !error and submission.metadata?
	response.writeJSON submission.metadata
else
	response.writeJSON {
		width: 3
		height: 3
		pixels: null
		achievements: []
		error: error
		submission: submission
	}
