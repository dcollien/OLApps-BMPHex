settings = {}

settings.isEmbedded = true
settings.isFullWidth = true

OpenLearning.activity.setSubmissionType 'file'
url = (OpenLearning.page.setData settings, request.user).url

response.writeData '<span style="font-family: sans-serif; font-weight: 400; font-size: 16px">App has been configured</span> ' + url
