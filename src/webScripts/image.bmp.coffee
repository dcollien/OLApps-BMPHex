convertToBinary = (hex) ->
  bin = ''
  bin += String.fromCharCode(parseInt(val, 16)) for val in hex
  return bin
 
response.setHeader 'Content-Type', 'image/bmp'
response.writeData convertToBinary(JSON.parse request.data.bmpHex)
