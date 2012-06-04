class BMPHexEditor
	@WIDTH_BYTES  = [18, 19, 20, 21]
	@HEIGHT_BYTES = [22, 23, 24, 25]
	@FILE_LENGTH_BYTES = [2, 3, 4, 5]
	@PIXEL_ARRAY_LENGTH_BYTES = [34, 35, 36, 37]
	
	@BYTES_PER_PIXEL = 3
	@HEX = 16
	
	@MAX_DIMENSION = 8
	
	@MAX_SIZE = 150
	
	@ACHIEVEMENT_INIT_ORDER = [ 'Show Pixel Array', 'Show DIB Header', 'Show BMP Header', 'Edited Padding Bytes' ]
	
	@ACHIEVEMENTS = {
		'Mondrian': {
			title: 'Piet Mondrian',
			description: 'A true masterpiece!',
			action: ->
		},
		
		'Show BMP Header': {		
			title: 'Clicked on something!'
			description: '\'BMP Header\' Tab is now available',
			action: ->
				$('#bmpHeaderTab').fadeIn( )
				$('#content').fadeIn( )
				$('#bmpHeaderTab a').tab('show')
				$('.bmpHeaderByte').addClass( 'bmpHeaderByteUnlocked' )
				@resize( )
		},
		
		'Show DIB Header': {
			title: 'Messing with sizes'
			description: '\'DIB Header\' Tab is now available',
			action: ->
				$('#dibHeaderTab').fadeIn( )
				$('#content').fadeIn( )
				$('#dibHeaderTab a').tab('show')
				$('.dibHeaderByte').addClass( 'dibHeaderByteUnlocked' )
				@resize( )
		},
		
		'Show Pixel Array': {
			title: 'Pixel Artist!',
			description: '\'Pixel Array\' Tab is now available',
			action: ->
				$('#pixelArrayTab').fadeIn( )
				$('#content').fadeIn( )
				$('#pixelArrayTab a').tab('show')
				@resize( )
		},
		
		'Edited Padding Bytes': {
			title: 'Shouting into the Void',
			description: 'Padding bytes edited. Nothing happens.',
			action: ->
		}
	}
	
	constructor: (@width, @height, @unlockedAchievements) ->
		@canvas = $('#bitmapCanvas')[0]
		@ctx = @canvas.getContext '2d'
		
		$dropZone = $('#dropZone')
		
		@canvas.width  = BMPHexEditor.MAX_SIZE
		@canvas.height = BMPHexEditor.MAX_SIZE
		
		@bitsPerPixel = BMPHexEditor.BYTES_PER_PIXEL * 8
		@bmpHeaderLength = 14
		@dibHeaderLength = 40
		@headerLength = @bmpHeaderLength + @dibHeaderLength
		
		@selectedX = 0
		@selectedY = 0
		@isSelected = false
		
		if @unlockedAchievements
			for name in BMPHexEditor.ACHIEVEMENT_INIT_ORDER
				if unlockedAchievements[name]
					@unlockAchievement name, true
		else
			@unlockedAchievements = {}
		console.log @unlockedAchievements
		
		$('#totalAchievements').text BMPHexEditor.ACHIEVEMENT_INIT_ORDER.length
		
		@resetImage( )
		
		# reset image on changing header inputs
		$('.headerInput').bind 'change', => @headerByteChanged( )
		
		$dropZone.bind 'drop', (event) => @handleDrop event
		$('#selectImage').bind 'change', (event) => @handleDrop event
		
		$('.hexConst, .headerInput').mouseover ->
			id = $(this).attr 'id'
			byte = parseInt( id.replace 'byte', '' )
			$('#byteDisplay' + byte).addClass 'highlighted'
		
		$('.hexConst, .headerInput').mouseout ->
			id = $(this).attr 'id'
			byte = parseInt( id.replace 'byte', '' )
			$('#byteDisplay' + byte).removeClass 'highlighted'
			
		$('#bmpHeaderUnlock').click => 
			@unlockAchievement 'Show BMP Header'
			return false
	
	unlockAchievement: (achievement, isSilent=false) ->
		if @unlockedAchievements[achievement] is true
			return
		
		$('#achievementDropdown').fadeIn( )
		
		@unlockedAchievements[achievement] = true
		achievementData = BMPHexEditor.ACHIEVEMENTS[achievement]
		achievementData.action.call( @ )
		
		numUnlocked = 0
		for name, unlocked of @unlockedAchievements
			if unlocked
				numUnlocked += 1
		
		updateCount = ->
			$('#numUnlocked').css { 'position': 'relative', 'top': '-10px' }
			$('#numUnlocked').text numUnlocked
			$('#numUnlocked').animate { 'top': '0px' }
			
		$('#numUnlocked').html '&#x2713;'
		setTimeout updateCount, 1000
		
		$newItem = $('<li class="listedAchievement">')
		$title = $('<span>').text achievementData.title
		$newItem.append $('<i class="icon-ok faded">')
		$newItem.append ' '
		$newItem.append $title
		$('#achievementList').append $newItem
		
		if !isSilent
			$('#achievementSpace').empty( )
			
			$achievementAlert = $('<div class="alert alert-success hide">')
			$achievementAlert.append $('<strong>Achievement Unlocked:</strong>')
			$achievementAlert.append ' &nbsp; '
			$achievementAlert.append achievementData.title
			$achievementAlert.append $('<br>')
			$achievementAlert.append achievementData.description
			$achievementAlert.append $('<span style="position: absolute; left: 20px; top: 20px;">Click to Close</span>')
			$achievementAlert.alert( )
			
			$achievementAlert.click -> $(this).fadeOut( )
			
			setTimeout (-> $achievementAlert.fadeOut( )), 8000
			
			$('#achievementSpace').append $achievementAlert
			$achievementAlert.slideDown( )
			
			
		# TODO server-side, etc.

	isAchievementUnlocked: (achievement) ->
		return @unlockedAchievements[achievement]

	resize: ->
		$('#content').css {
			'position': 'relative'
			'top': ($('#header').height( ) + 20) + 'px'
		}
	
	encodeDataURI: (input) ->
		keyString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
		
		output = ""
		encodedCharIndexes = new Array( 4 )
		inx = 0
		paddingBytes = 0
		
		while inx < input.length
			bytebuffer = new Array( 3 )
			
			for jnx in [0...bytebuffer.length]
				if inx < input.length
					bytebuffer[jnx] = input[inx++] & 0xff
				else
					bytebuffer[jnx] = 0
		
			encodedCharIndexes[0] = bytebuffer[0] >> 2
			encodedCharIndexes[1] = ((bytebuffer[0] & 0x3) << 4) | (bytebuffer[1] >> 4)
			encodedCharIndexes[2] = ((bytebuffer[1] & 0x0f) << 2) | (bytebuffer[2] >> 6)
			encodedCharIndexes[3] = bytebuffer[2] & 0x3f
			
			paddingBytes = inx - (input.length - 1)
			
			switch paddingBytes
				when 2
					encodedCharIndexes[3] = 64
					encodedCharIndexes[2] = 64
				when 1 
					encodedCharIndexes[3] = 64
				
			for jnx in [0...encodedCharIndexes.length]
				output += keyString.charAt encodedCharIndexes[jnx]
		return output
	
	handleDrop: (event) ->
		event.preventDefault( )
	
		supported = window.File and window.FileReader and window.FileList and window.Blob
		
		if not supported
			alert "Your browser can't do this :( Try using Safari 5.2+, Chrome, Firefox or IE 10+"
			return
		
		dropEvent = event.originalEvent
		files = dropEvent.target.files || dropEvent.dataTransfer.files
		file = files[0]

		reader = new FileReader( )
		
		reader.onload = (readerEvent) =>
			image = new Image( )
			image.onload = (imageEvent) =>
				if image.width <= BMPHexEditor.MAX_DIMENSION and image.height <= BMPHexEditor.MAX_DIMENSION
					@updateWithImage image
				else
					alert 'Image is too large for this activity (' + BMPHexEditor.MAX_DIMENSION + ' x ' + BMPHexEditor.MAX_DIMENSION + 'px maximum)'
			
			image.src = readerEvent.target.result

		
		reader.onerror = (readerEvent) ->
			console.log readerEvent
		
		reader.readAsDataURL file
		return false
		
	updateWithImage: (image) ->
		@canvas.width  = image.width
		@canvas.height = image.height
		
		@width = image.width
		@height = image.height
		
		@ctx.clearRect 0, 0, @canvas.width, @canvas.height
			
		@ctx.drawImage image, 0, 0
		
		imageData = @ctx.getImageData 0, 0, @canvas.width, @canvas.height
		@pixels = imageData.data
		
		@rebuild( )
		@redraw( )
		
	updatePixels: ->
		bytes = @getBytes( )
		@pixels = []
		for i in [0...(@width*@height*4)]
			@pixels.push @getPixelFromBMPBytes( i, bytes )
			
		for i in [0...bytes.length]
			$byteDisplay = $('#byteDisplay' + i)
			if $byteDisplay.is 'span'
				$byteDisplay.text @paddedHex( bytes[i] )
			else
				$byteDisplay.val @paddedHex( bytes[i] )
		
		@redraw( )
	
	redraw: ->
		# how big are pixels going to be drawn
		widthPixelSize  = Math.floor (BMPHexEditor.MAX_SIZE / @width)
		heightPixelSize = Math.floor (BMPHexEditor.MAX_SIZE / @height)
		pixelSize = Math.min widthPixelSize, heightPixelSize
		
		#resize canvas to snuggly fit bigger pixels for this image
		@canvas.width  = pixelSize * @width
		@canvas.height = pixelSize * @height
		
		@ctx.clearRect 0, 0, @canvas.width, @canvas.height
		
		# draw big pixels
		for x in [0...@width]
			for y in [0...@height]
				i = 4 * (y * @width + x)
				r = @pixels[i+0]
				g = @pixels[i+1]
				b = @pixels[i+2]
				#a = @pixels[i+3]
									
				@ctx.fillStyle = "rgba(" + r + "," + g + "," + b + ", 1)"
				@ctx.fillRect x * pixelSize, y * pixelSize, pixelSize, pixelSize
				
				if @isSelected and @selectedX is x and @selectedY is y
					if (r + g + b)/3 < 80
						@ctx.strokeStyle = "rgba(255,255,255,0.75)"
					else
						@ctx.strokeStyle = "rgba(0,0,0,0.5)"
					@ctx.lineWidth = 2
					@ctx.strokeRect x * pixelSize+1, y * pixelSize+1, pixelSize-2, pixelSize-2
	
	hexArrayToDec: (bytes) ->
		return bytes.map (x) -> parseInt x, BMPHexEditor.HEX
	
	editedPadding: ->
		if @isAchievementUnlocked 'Show Pixel Array'
			@unlockAchievement 'Edited Padding Bytes'
	
	rebuildFileDisplay: ->
		$fileByteDisplay = $('#fileView')
		$fileByteDisplay.empty( )
		
		bytes = @getBytes( )
		
		
		for i in [0...bytes.length]
			if i < @bmpHeaderLength
				className = "displayByte bmpHeaderByte"
				className += ' bmpHeaderByteUnlocked' if @isAchievementUnlocked 'Show BMP Header'
				
				tagName = "span"
			else if i < (@bmpHeaderLength + @dibHeaderLength)
				className = "displayByte dibHeaderByte"
				className += ' dibHeaderByteUnlocked' if @isAchievementUnlocked 'Show DIB Header'
				
				if i in BMPHexEditor.WIDTH_BYTES or i in BMPHexEditor.HEIGHT_BYTES 
					tagName = "input"
				else
					tagName = "span"
			else
				tagName = "input"
				className = "displayByte pixelByte"
			
			$byteField = $('<' + tagName + ' class="' + className + '">')
			$byteField.attr 'id', 'byteDisplay' + i
			$byteField.data 'byte', i
			hex = (@paddedHex bytes[i].toString( BMPHexEditor.HEX ))
			
			if tagName is "input"
				$byteField.val hex
				$byteField.attr 'maxlength', 2
				# bind to other view
				paddedHex = (x) => @paddedHex x
				$byteField.bind 'change', -> 
					$(this).val paddedHex( $(this).val( ) )
					byte = $(this).data( 'byte' )
					$('#byte' + byte).val $(this).val( )	
			else
				$byteField.text hex
			
			$fileByteDisplay.append $byteField
		
		#console.log @hexArrayToDec( bytes )
		$('#downloadLink').attr 'href', 'data:image/x-bmp;base64,' + @encodeDataURI( @hexArrayToDec( bytes ) )
		
		$('.bmpHeaderByte').click => @unlockAchievement 'Show BMP Header'
		
		$('.pixelByte').bind 'change', => @pixelByteChanged( )
		$('.dibHeaderByte').bind 'change', => @headerByteChanged( )
		
		$('.displayByte').mouseover -> $('#byte' + $(this).data( 'byte' )).addClass 'highlighted'
		$('.displayByte').mouseout -> $('#byte' + $(this).data( 'byte' )).removeClass 'highlighted'
	
		
		$('input.displayByte').click -> this.select( )
		
		self = @
		$('.pixelByte').mouseover ->
			byte = $(this).data( 'byte' )
			self.addBorderForByte byte
		
		$('.pixelByte').mouseout => @removeBorder( )
		
		
	addBorderForByte: (byte) ->
		if @isAchievementUnlocked 'Show Pixel Array'
			
			coord = @coordForByte byte
			if coord isnt null
				[x, y] = coord
				@isSelected = true
				@selectedX = x
				@selectedY = y
				@redraw( )
	
	removeBorder: ->
		if @isAchievementUnlocked 'Show Pixel Array'
			@isSelected = false
			@redraw( )
		
	headerByteChanged: ->
		if not @headerBytesChanged
			@headerBytesChanged = 0
		
		
		@headerBytesChanged += 1
		
		if @headerBytesChanged > 2
			@unlockAchievement 'Show DIB Header'
		
		@resetImage( )
		
	pixelByteChanged: ->
		if not @pixelsChanged
			@pixelsChanged = 0
		
		@pixelsChanged += 1
		@updatePixels( )
		
		if @pixelsChanged > 8
			colorsSeen = []
			console.log "checking colors"
			for i in [0...(@width*@height)]
				offset = i*4
				r = @pixels[offset+0]
				g = @pixels[offset+1]
				b = @pixels[offset+2]
				a = @pixels[offset+3]
				
				colorString = (r + ', ' + g + ', ' + b)
				
				if colorString not in colorsSeen
					colorsSeen.push colorString
				
				#console.log colorsSeen
				
				if colorsSeen.length > 3
					@unlockAchievement 'Show Pixel Array'
				
				if (@width*@height) > 4 and colorsSeen.length is (@width*@height)
					@unlockAchievement 'Mondrian'
					break
		
	getBytes: ->
		bytes = []
		for i in [0...@getFileLength( )]			
			$byteDisplay = $('#byte' + i)
			if $byteDisplay.is 'input'
				byteValue = $byteDisplay.val( )
			else
				byteValue = $byteDisplay.text( )
			bytes.push byteValue
		return bytes
		
	rebuild: ->
		fileLength = @getFileLength( )
		arrayLength = @getPixelArrayLength( )
		
		@set4ByteText BMPHexEditor.FILE_LENGTH_BYTES, fileLength
		@set4ByteText BMPHexEditor.PIXEL_ARRAY_LENGTH_BYTES, arrayLength
		
		@set4ByteVal BMPHexEditor.WIDTH_BYTES, @width
		@set4ByteVal BMPHexEditor.HEIGHT_BYTES, @height
		
		$('#imageWidth').text @width
		$('#imageHeight').text @height
		$('#pixelArraySize').text arrayLength
		$('#fileSize').text fileLength
		
		@rebuildPixelArrayInput( )
		@rebuildFileDisplay( )
		
	rebuildPixelArrayInput: ->
		$pixelArray = $('#pixelArrayData')
		$pixelArray.empty( )
		
		for i in [0...@getPixelArrayLength( )]
			value = @getBMPByteFromPixels i
			$input = $( '<input id="byte' + (@headerLength + i) + '" class="pixelInput" maxlength="2">' )
			$input.data { 'byte': (@headerLength + i) }
			
			col = i % @getRowLength( )
			
			if col >= @width * BMPHexEditor.BYTES_PER_PIXEL
				$input.css {
					'border': '1px solid #aaa'
					'margin-right': '2px'
				}
			else if col % BMPHexEditor.BYTES_PER_PIXEL == 0
				$input.css {
					'border': '1px solid #bbe'
					'margin-right': '2px'
					'background-color': '#eef'
				}
			else if col % BMPHexEditor.BYTES_PER_PIXEL == 1
				$input.css {
					'border': '1px solid #beb'
					'margin-right': '2px'
					'background-color': '#efe'
				}
			else if col % BMPHexEditor.BYTES_PER_PIXEL == 2
				$input.css {
					'border': '1px solid #ebb'
					'margin-right': '8px'
					'background-color': '#fee'
				}
			
			byteValue = @paddedHex value
			$input.val byteValue
			$pixelArray.append $input
		
		
		# update pixels on changing pixel inputs
		self = @
		$('.pixelInput').bind 'change', => @pixelByteChanged( )
		$('.pixelInput').bind 'keydown', ->
			id = $(this).attr 'id'
			byte = $(this).data 'byte'
			if self.coordForByte(byte) is null
				self.editedPadding( ) 
			else
				self.pixelByteChanged( )
			
		$('.pixelInput').click -> this.select( )
		
		self = @
		$('.pixelInput').mouseover ->
			id = $(this).attr 'id'
			byte = $(this).data 'byte'
			
			$('#byteDisplay' + byte).addClass 'highlighted'
			self.addBorderForByte byte
		
		$('.pixelInput').mouseout ->
			id = $(this).attr 'id'
			byte = $(this).data 'byte'
			$('#byteDisplay' + byte).removeClass 'highlighted'
			self.removeBorder( )
		
		
		paddingPerRow = @getRowLength( ) - @width * BMPHexEditor.BYTES_PER_PIXEL
		$pixelArray.width( @width * 102 + 32 * paddingPerRow )
			
	resetImage: ->
		width  = @get4ByteVal BMPHexEditor.WIDTH_BYTES
		height = @get4ByteVal BMPHexEditor.HEIGHT_BYTES
		
		if width > BMPHexEditor.MAX_DIMENSION or height > BMPHexEditor.MAX_DIMENSION
			@set4ByteVal BMPHexEditor.WIDTH_BYTES, @width
			@set4ByteVal BMPHexEditor.HEIGHT_BYTES, @height
			
			alert 'This activity can only be used with ' + BMPHexEditor.MAX_DIMENSION + 'x' + BMPHexEditor.MAX_DIMENSION + ' pixel images or smaller.'
			return
		
		@width  = width
		@height = height
		@pixels = []
		
		# init with white
		for i in [0...(@width*@height*4)]
			@pixels.push 255
		
		@rebuild( )
		@redraw( )
		@resize( )
		
	set4ByteVal: (bytes, value) ->
		value = parseInt value
		$('#byte' + bytes[0]).val @paddedHex(value & 0xff)
		$('#byte' + bytes[1]).val @paddedHex((value >> 8) & 0xff)
		$('#byte' + bytes[2]).val @paddedHex((value >> 16) & 0xff)
		$('#byte' + bytes[3]).val @paddedHex((value >> 24) & 0xff)
		
		$('#byteDisplay' + bytes[0]).val @paddedHex(value & 0xff)
		$('#byteDisplay' + bytes[1]).val @paddedHex((value >> 8) & 0xff)
		$('#byteDisplay' + bytes[2]).val @paddedHex((value >> 16) & 0xff)
		$('#byteDisplay' + bytes[3]).val @paddedHex((value >> 24) & 0xff)		
		
			
	get4ByteVal: (bytes) ->
		value =  parseInt( $('#byte' + bytes[0]).val( ), BMPHexEditor.HEX )
		value += parseInt( $('#byte' + bytes[1]).val( ), BMPHexEditor.HEX ) << 8
		value += parseInt( $('#byte' + bytes[2]).val( ), BMPHexEditor.HEX ) << 16
		value += parseInt( $('#byte' + bytes[3]).val( ), BMPHexEditor.HEX ) << 24
		return value
			
	set4ByteText: (bytes, value) ->
		value = parseInt value
		$('#byte' + bytes[0]).text @paddedHex(value & 0xff)
		$('#byte' + bytes[1]).text @paddedHex((value >> 8) & 0xff)
		$('#byte' + bytes[2]).text @paddedHex((value >> 16) & 0xff)
		$('#byte' + bytes[3]).text @paddedHex((value >> 24) & 0xff)
		
		$('#byteDisplay' + bytes[0]).text @paddedHex(value & 0xff)
		$('#byteDisplay' + bytes[1]).text @paddedHex((value >> 8) & 0xff)
		$('#byteDisplay' + bytes[2]).text @paddedHex((value >> 16) & 0xff)
		$('#byteDisplay' + bytes[3]).text @paddedHex((value >> 24) & 0xff)
	
	coordForByte: (byte) ->
		byteIndex = byte - @headerLength
		
		rowLength = @getRowLength( )
		byteCol = (byteIndex % rowLength)
		col = Math.floor (byteCol / BMPHexEditor.BYTES_PER_PIXEL)
		row = Math.floor (byteIndex / rowLength)
		
		# padding byte
		if col >= @width
			return null
		
		x = col
		y = (@height - row - 1)
		return [x, y]
	
	getPixelFromBMPBytes: (pixelIndex, bytes) ->
		x = Math.floor( pixelIndex/4 ) % @width
		y = Math.floor( Math.floor( pixelIndex/4 ) / @width )
		
		switch pixelIndex % 4
			when 0 then colorField = 2
			when 1 then colorField = 1
			when 2 then colorField = 0
			when 3 then return 0 # alpha
		
		row = (@height - y - 1)
		col = x*BMPHexEditor.BYTES_PER_PIXEL
		
		byte = (row * @getRowLength( )) + col + colorField
		
		value = parseInt bytes[@headerLength + byte], BMPHexEditor.HEX
		
		return value
	
	getBMPByteFromPixels: (byteIndex) ->
		rowLength = @getRowLength( )
		byteCol = (byteIndex % rowLength)
		col = Math.floor (byteCol / BMPHexEditor.BYTES_PER_PIXEL)
		row = Math.floor (byteIndex / rowLength)
		
		# padding byte
		if col >= @width
			return 0
		
		x = col
		y = (@height - row - 1)
		
		offset = 4 * ((y * @width) + x)
		
		value = 0
		
		switch (byteCol % BMPHexEditor.BYTES_PER_PIXEL)
			when 0 then value = @pixels[2 + offset]
			when 1 then value = @pixels[1 + offset]
			when 2 then value = @pixels[0 + offset]
			
		return value
	
	paddedHex: (n) ->
		hex = n.toString 16
		if hex.length == 1
			hex = '0' + hex
		return hex
		
	getRowLength: -> Math.ceil( (@bitsPerPixel * @width)/32 ) * 4
		
	getPixelArrayLength: -> @getRowLength( ) * @height
	
	getFileLength: -> @headerLength + @getPixelArrayLength( )
	
	