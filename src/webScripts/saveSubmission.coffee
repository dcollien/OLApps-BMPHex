try
	data = JSON.parse request.data.submission
catch error
	data = null	

if request.method is 'POST' and data
	submission = {
		metadata: {
			hex: data.hex
			pixels: data.pixels
			base64: data.base64
			achievements: data.achievements
			width: data.width
			height: data.height
		}
		file: {
			filename: 'image.bmp'
			data: data.base64
			encoding: 'base64'
		}
		previewImage: {
			filename: 'preview.png'
			data: data.previewBase64
			encoding: 'base64'
		}
		markup: "{{./PreviewImage}}"
	}

	submissionData = OpenLearning.activity.saveSubmission request.user, submission, 'file'

	taskMarksUpdate = { }
	taskMarksUpdate[request.user] =
		completed: true
	
	OpenLearning.activity.submit request.user
	OpenLearning.activity.setMarks taskMarksUpdate
	
	response.setHeader 'Content-Type', 'application/json'
	response.writeJSON {
		success: true,
		submission: submission,
		saved: submissionData
	}
else
	response.writeJSON {
		success: false,
		reason: 'Not POST'
	}

