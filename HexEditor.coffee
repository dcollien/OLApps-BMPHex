class BMPHexEditor
	@WIDTH_BYTES  = [18, 19, 20, 21]
	@HEIGHT_BYTES = [22, 23, 24, 25]
	@FILE_LENGTH_BYTES = [2, 3, 4, 5]
	@PIXEL_ARRAY_LENGTH_BYTES = [34, 35, 36, 37]
	
	@BYTES_PER_PIXEL = 3
	@HEX = 16
	
	@MAX_DIMENSION = 8
	
	@MAX_SIZE = 150
	
	constructor: (@width, @height) ->
		@canvas = $('#bitmapCanvas')[0]
		@ctx = @canvas.getContext '2d'
		
		$dropZone = $('#dropZone')
		
		@canvas.width  = BMPHexEditor.MAX_SIZE
		@canvas.height = BMPHexEditor.MAX_SIZE
		
		@bitsPerPixel = BMPHexEditor.BYTES_PER_PIXEL * 8
		@bmpHeaderLength = 14
		@dibHeaderLength = 40
		@headerLength = @bmpHeaderLength + @dibHeaderLength
		
		@resetImage( )
		
		# reset image on changing header inputs
		$('.headerInput').bind 'change', => @resetImage( )
		
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
		
		supported = window.File and window.FileReader and window.FileList and window.Blob
		
		if not supported
			alert "Your browser can't do this. Upgrade to a more recent or capable browser."
		
		event.preventDefault( )
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
		
		@redraw( )
	
	redraw: ->
		@updateFileDisplay( )
		
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
									
				@ctx.fillStyle = "rgba(" + r + "," + g + "," + b + ", 255)"
				@ctx.fillRect x * pixelSize, y * pixelSize, pixelSize, pixelSize
	
	hexArrayToDec: (bytes) ->
		return bytes.map (x) -> parseInt x, BMPHexEditor.HEX
	
	updateFileDisplay: ->
		$fileByteDisplay = $('#fileView')
		$fileByteDisplay.empty( )
		
		bytes = @getBytes( )
		
		for i in [0...bytes.length]
			if i < @bmpHeaderLength
				className = "displayByte bmpHeaderByte"
			else if i < (@bmpHeaderLength + @dibHeaderLength)
				className = "displayByte dibHeaderByte"
			else
				className = "displayByte pixelByte"
			
			$byteField = $('<span id="byteDisplay' + i + '" class="' + className + '">')
			$byteField.text (@paddedHex bytes[i].toString( BMPHexEditor.HEX ))
			$fileByteDisplay.append $byteField
		
		#console.log @hexArrayToDec( bytes )
		$('#downloadLink').attr 'href', 'data:image/x-bmp;base64,' + @encodeDataURI( @hexArrayToDec( bytes ) )
		
		$('.displayByte').mouseover ->
			id = $(this).attr 'id'
			byte = parseInt( id.replace 'byteDisplay', '' )
			$('#byte' + byte).addClass 'highlighted'
		
		$('.displayByte').mouseout ->
			id = $(this).attr 'id'
			byte = parseInt( id.replace 'byteDisplay', '' )
			$('#byte' + byte).removeClass 'highlighted'
	
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
		
	rebuildPixelArrayInput: ->
		$pixelArray = $('#pixelArrayData')
		$pixelArray.empty( )
		
		for i in [0...@getPixelArrayLength( )]
			value = @getBMPByteFromPixels i
			$input = $( '<input id="byte' + (@headerLength + i) + '" class="pixelInput" maxlength="2">' )
			
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
		$('.pixelInput').bind 'blur change', => @updatePixels( )
			
		$('.pixelInput').mouseover ->
			id = $(this).attr 'id'
			byte = parseInt( id.replace 'byte', '' )
			$('#byteDisplay' + byte).addClass 'highlighted'
		
		$('.pixelInput').mouseout ->
			id = $(this).attr 'id'
			byte = parseInt( id.replace 'byte', '' )
			$('#byteDisplay' + byte).removeClass 'highlighted'
		
		
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
		
		$('#content').css {
			'position': 'relative'
			'top': ($('#header').height( ) + 20) + 'px'
		}
		
	set4ByteVal: (bytes, value) ->
		value = parseInt value
		$('#byte' + bytes[0]).val @paddedHex(value & 0xff)
		$('#byte' + bytes[1]).val @paddedHex((value >> 8) & 0xff)
		$('#byte' + bytes[2]).val @paddedHex((value >> 16) & 0xff)
		$('#byte' + bytes[3]).val @paddedHex((value >> 24) & 0xff)
			
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
	
	