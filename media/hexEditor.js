var BMPHexEditor;

BMPHexEditor = (function() {

  BMPHexEditor.WIDTH_BYTES = [18, 19, 20, 21];

  BMPHexEditor.HEIGHT_BYTES = [22, 23, 24, 25];

  BMPHexEditor.FILE_LENGTH_BYTES = [2, 3, 4, 5];

  BMPHexEditor.PIXEL_ARRAY_LENGTH_BYTES = [34, 35, 36, 37];

  BMPHexEditor.BYTES_PER_PIXEL = 3;

  BMPHexEditor.HEX = 16;

  BMPHexEditor.MAX_DIMENSION = 8;

  BMPHexEditor.MAX_SIZE = 150;

  function BMPHexEditor(width, height) {
    var $dropZone,
      _this = this;
    this.width = width;
    this.height = height;
    this.canvas = $('#bitmapCanvas')[0];
    this.ctx = this.canvas.getContext('2d');
    $dropZone = $('#dropZone');
    this.canvas.width = BMPHexEditor.MAX_SIZE;
    this.canvas.height = BMPHexEditor.MAX_SIZE;
    this.bitsPerPixel = BMPHexEditor.BYTES_PER_PIXEL * 8;
    this.bmpHeaderLength = 14;
    this.dibHeaderLength = 40;
    this.headerLength = this.bmpHeaderLength + this.dibHeaderLength;
    this.resetImage();
    $('.headerInput').bind('change', function() {
      return _this.resetImage();
    });
    $dropZone.bind('drop', function(event) {
      return _this.handleDrop(event);
    });
    $('#selectImage').bind('change', function(event) {
      return _this.handleDrop(event);
    });
    $('.hexConst, .headerInput').mouseover(function() {
      var byte, id;
      id = $(this).attr('id');
      byte = parseInt(id.replace('byte', ''));
      return $('#byteDisplay' + byte).addClass('highlighted');
    });
    $('.hexConst, .headerInput').mouseout(function() {
      var byte, id;
      id = $(this).attr('id');
      byte = parseInt(id.replace('byte', ''));
      return $('#byteDisplay' + byte).removeClass('highlighted');
    });
  }

  BMPHexEditor.prototype.encodeDataURI = function(input) {
    var bytebuffer, encodedCharIndexes, inx, jnx, keyString, output, paddingBytes, _ref, _ref2;
    keyString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    output = "";
    encodedCharIndexes = new Array(4);
    inx = 0;
    paddingBytes = 0;
    while (inx < input.length) {
      bytebuffer = new Array(3);
      for (jnx = 0, _ref = bytebuffer.length; 0 <= _ref ? jnx < _ref : jnx > _ref; 0 <= _ref ? jnx++ : jnx--) {
        if (inx < input.length) {
          bytebuffer[jnx] = input[inx++] & 0xff;
        } else {
          bytebuffer[jnx] = 0;
        }
      }
      encodedCharIndexes[0] = bytebuffer[0] >> 2;
      encodedCharIndexes[1] = ((bytebuffer[0] & 0x3) << 4) | (bytebuffer[1] >> 4);
      encodedCharIndexes[2] = ((bytebuffer[1] & 0x0f) << 2) | (bytebuffer[2] >> 6);
      encodedCharIndexes[3] = bytebuffer[2] & 0x3f;
      paddingBytes = inx - (input.length - 1);
      switch (paddingBytes) {
        case 2:
          encodedCharIndexes[3] = 64;
          encodedCharIndexes[2] = 64;
          break;
        case 1:
          encodedCharIndexes[3] = 64;
      }
      for (jnx = 0, _ref2 = encodedCharIndexes.length; 0 <= _ref2 ? jnx < _ref2 : jnx > _ref2; 0 <= _ref2 ? jnx++ : jnx--) {
        output += keyString.charAt(encodedCharIndexes[jnx]);
      }
    }
    return output;
  };

  BMPHexEditor.prototype.handleDrop = function(event) {
    var dropEvent, file, files, reader, supported,
      _this = this;
    supported = window.File && window.FileReader && window.FileList && window.Blob;
    if (!supported) {
      alert("Your browser can't do this. Upgrade to a more recent or capable browser.");
    }
    event.preventDefault();
    dropEvent = event.originalEvent;
    files = dropEvent.target.files || dropEvent.dataTransfer.files;
    file = files[0];
    reader = new FileReader();
    reader.onload = function(readerEvent) {
      var image;
      image = new Image();
      image.onload = function(imageEvent) {
        if (image.width <= BMPHexEditor.MAX_DIMENSION && image.height <= BMPHexEditor.MAX_DIMENSION) {
          return _this.updateWithImage(image);
        } else {
          return alert('Image is too large for this activity (' + BMPHexEditor.MAX_DIMENSION + ' x ' + BMPHexEditor.MAX_DIMENSION + 'px maximum)');
        }
      };
      return image.src = readerEvent.target.result;
    };
    reader.onerror = function(readerEvent) {
      return console.log(readerEvent);
    };
    reader.readAsDataURL(file);
    return false;
  };

  BMPHexEditor.prototype.updateWithImage = function(image) {
    var imageData;
    this.canvas.width = image.width;
    this.canvas.height = image.height;
    this.width = image.width;
    this.height = image.height;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.ctx.drawImage(image, 0, 0);
    imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
    this.pixels = imageData.data;
    this.rebuild();
    return this.redraw();
  };

  BMPHexEditor.prototype.updatePixels = function() {
    var bytes, i, _ref;
    bytes = this.getBytes();
    this.pixels = [];
    for (i = 0, _ref = this.width * this.height * 4; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
      this.pixels.push(this.getPixelFromBMPBytes(i, bytes));
    }
    return this.redraw();
  };

  BMPHexEditor.prototype.redraw = function() {
    var b, g, heightPixelSize, i, pixelSize, r, widthPixelSize, x, y, _ref, _results;
    this.updateFileDisplay();
    widthPixelSize = Math.floor(BMPHexEditor.MAX_SIZE / this.width);
    heightPixelSize = Math.floor(BMPHexEditor.MAX_SIZE / this.height);
    pixelSize = Math.min(widthPixelSize, heightPixelSize);
    this.canvas.width = pixelSize * this.width;
    this.canvas.height = pixelSize * this.height;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    _results = [];
    for (x = 0, _ref = this.width; 0 <= _ref ? x < _ref : x > _ref; 0 <= _ref ? x++ : x--) {
      _results.push((function() {
        var _ref2, _results2;
        _results2 = [];
        for (y = 0, _ref2 = this.height; 0 <= _ref2 ? y < _ref2 : y > _ref2; 0 <= _ref2 ? y++ : y--) {
          i = 4 * (y * this.width + x);
          r = this.pixels[i + 0];
          g = this.pixels[i + 1];
          b = this.pixels[i + 2];
          this.ctx.fillStyle = "rgba(" + r + "," + g + "," + b + ", 255)";
          _results2.push(this.ctx.fillRect(x * pixelSize, y * pixelSize, pixelSize, pixelSize));
        }
        return _results2;
      }).call(this));
    }
    return _results;
  };

  BMPHexEditor.prototype.hexArrayToDec = function(bytes) {
    return bytes.map(function(x) {
      return parseInt(x, BMPHexEditor.HEX);
    });
  };

  BMPHexEditor.prototype.updateFileDisplay = function() {
    var $byteField, $fileByteDisplay, bytes, className, i, _ref;
    $fileByteDisplay = $('#fileView');
    $fileByteDisplay.empty();
    bytes = this.getBytes();
    for (i = 0, _ref = bytes.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
      if (i < this.bmpHeaderLength) {
        className = "displayByte bmpHeaderByte";
      } else if (i < (this.bmpHeaderLength + this.dibHeaderLength)) {
        className = "displayByte dibHeaderByte";
      } else {
        className = "displayByte pixelByte";
      }
      $byteField = $('<span id="byteDisplay' + i + '" class="' + className + '">');
      $byteField.text(this.paddedHex(bytes[i].toString(BMPHexEditor.HEX)));
      $fileByteDisplay.append($byteField);
    }
    $('#downloadLink').attr('href', 'data:image/x-bmp;base64,' + this.encodeDataURI(this.hexArrayToDec(bytes)));
    $('.displayByte').mouseover(function() {
      var byte, id;
      id = $(this).attr('id');
      byte = parseInt(id.replace('byteDisplay', ''));
      return $('#byte' + byte).addClass('highlighted');
    });
    return $('.displayByte').mouseout(function() {
      var byte, id;
      id = $(this).attr('id');
      byte = parseInt(id.replace('byteDisplay', ''));
      return $('#byte' + byte).removeClass('highlighted');
    });
  };

  BMPHexEditor.prototype.getBytes = function() {
    var $byteDisplay, byteValue, bytes, i, _ref;
    bytes = [];
    for (i = 0, _ref = this.getFileLength(); 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
      $byteDisplay = $('#byte' + i);
      if ($byteDisplay.is('input')) {
        byteValue = $byteDisplay.val();
      } else {
        byteValue = $byteDisplay.text();
      }
      bytes.push(byteValue);
    }
    return bytes;
  };

  BMPHexEditor.prototype.rebuild = function() {
    var arrayLength, fileLength;
    fileLength = this.getFileLength();
    arrayLength = this.getPixelArrayLength();
    this.set4ByteText(BMPHexEditor.FILE_LENGTH_BYTES, fileLength);
    this.set4ByteText(BMPHexEditor.PIXEL_ARRAY_LENGTH_BYTES, arrayLength);
    this.set4ByteVal(BMPHexEditor.WIDTH_BYTES, this.width);
    this.set4ByteVal(BMPHexEditor.HEIGHT_BYTES, this.height);
    $('#imageWidth').text(this.width);
    $('#imageHeight').text(this.height);
    $('#pixelArraySize').text(arrayLength);
    $('#fileSize').text(fileLength);
    return this.rebuildPixelArrayInput();
  };

  BMPHexEditor.prototype.rebuildPixelArrayInput = function() {
    var $input, $pixelArray, byteValue, col, i, paddingPerRow, value, _ref,
      _this = this;
    $pixelArray = $('#pixelArrayData');
    $pixelArray.empty();
    for (i = 0, _ref = this.getPixelArrayLength(); 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
      value = this.getBMPByteFromPixels(i);
      $input = $('<input id="byte' + (this.headerLength + i) + '" class="pixelInput" maxlength="2">');
      col = i % this.getRowLength();
      if (col >= this.width * BMPHexEditor.BYTES_PER_PIXEL) {
        $input.css({
          'border': '1px solid #aaa',
          'margin-right': '2px'
        });
      } else if (col % BMPHexEditor.BYTES_PER_PIXEL === 0) {
        $input.css({
          'border': '1px solid #bbe',
          'margin-right': '2px',
          'background-color': '#eef'
        });
      } else if (col % BMPHexEditor.BYTES_PER_PIXEL === 1) {
        $input.css({
          'border': '1px solid #beb',
          'margin-right': '2px',
          'background-color': '#efe'
        });
      } else if (col % BMPHexEditor.BYTES_PER_PIXEL === 2) {
        $input.css({
          'border': '1px solid #ebb',
          'margin-right': '8px',
          'background-color': '#fee'
        });
      }
      byteValue = this.paddedHex(value);
      $input.val(byteValue);
      $pixelArray.append($input);
    }
    $('.pixelInput').bind('blur change', function() {
      return _this.updatePixels();
    });
    $('.pixelInput').mouseover(function() {
      var byte, id;
      id = $(this).attr('id');
      byte = parseInt(id.replace('byte', ''));
      return $('#byteDisplay' + byte).addClass('highlighted');
    });
    $('.pixelInput').mouseout(function() {
      var byte, id;
      id = $(this).attr('id');
      byte = parseInt(id.replace('byte', ''));
      return $('#byteDisplay' + byte).removeClass('highlighted');
    });
    paddingPerRow = this.getRowLength() - this.width * BMPHexEditor.BYTES_PER_PIXEL;
    return $pixelArray.width(this.width * 102 + 32 * paddingPerRow);
  };

  BMPHexEditor.prototype.resetImage = function() {
    var height, i, width, _ref;
    width = this.get4ByteVal(BMPHexEditor.WIDTH_BYTES);
    height = this.get4ByteVal(BMPHexEditor.HEIGHT_BYTES);
    if (width > BMPHexEditor.MAX_DIMENSION || height > BMPHexEditor.MAX_DIMENSION) {
      this.set4ByteVal(BMPHexEditor.WIDTH_BYTES, this.width);
      this.set4ByteVal(BMPHexEditor.HEIGHT_BYTES, this.height);
      alert('This activity can only be used with ' + BMPHexEditor.MAX_DIMENSION + 'x' + BMPHexEditor.MAX_DIMENSION + ' pixel images or smaller.');
      return;
    }
    this.width = width;
    this.height = height;
    this.pixels = [];
    for (i = 0, _ref = this.width * this.height * 4; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
      this.pixels.push(255);
    }
    this.rebuild();
    this.redraw();
    return $('#content').css({
      'position': 'relative',
      'top': ($('#header').height() + 20) + 'px'
    });
  };

  BMPHexEditor.prototype.set4ByteVal = function(bytes, value) {
    value = parseInt(value);
    $('#byte' + bytes[0]).val(this.paddedHex(value & 0xff));
    $('#byte' + bytes[1]).val(this.paddedHex((value >> 8) & 0xff));
    $('#byte' + bytes[2]).val(this.paddedHex((value >> 16) & 0xff));
    return $('#byte' + bytes[3]).val(this.paddedHex((value >> 24) & 0xff));
  };

  BMPHexEditor.prototype.get4ByteVal = function(bytes) {
    var value;
    value = parseInt($('#byte' + bytes[0]).val(), BMPHexEditor.HEX);
    value += parseInt($('#byte' + bytes[1]).val(), BMPHexEditor.HEX) << 8;
    value += parseInt($('#byte' + bytes[2]).val(), BMPHexEditor.HEX) << 16;
    value += parseInt($('#byte' + bytes[3]).val(), BMPHexEditor.HEX) << 24;
    return value;
  };

  BMPHexEditor.prototype.set4ByteText = function(bytes, value) {
    value = parseInt(value);
    $('#byte' + bytes[0]).text(this.paddedHex(value & 0xff));
    $('#byte' + bytes[1]).text(this.paddedHex((value >> 8) & 0xff));
    $('#byte' + bytes[2]).text(this.paddedHex((value >> 16) & 0xff));
    return $('#byte' + bytes[3]).text(this.paddedHex((value >> 24) & 0xff));
  };

  BMPHexEditor.prototype.getPixelFromBMPBytes = function(pixelIndex, bytes) {
    var byte, col, colorField, row, value, x, y;
    x = Math.floor(pixelIndex / 4) % this.width;
    y = Math.floor(Math.floor(pixelIndex / 4) / this.width);
    switch (pixelIndex % 4) {
      case 0:
        colorField = 2;
        break;
      case 1:
        colorField = 1;
        break;
      case 2:
        colorField = 0;
        break;
      case 3:
        return 0;
    }
    row = this.height - y - 1;
    col = x * BMPHexEditor.BYTES_PER_PIXEL;
    byte = (row * this.getRowLength()) + col + colorField;
    value = parseInt(bytes[this.headerLength + byte], BMPHexEditor.HEX);
    return value;
  };

  BMPHexEditor.prototype.getBMPByteFromPixels = function(byteIndex) {
    var byteCol, col, offset, row, rowLength, value, x, y;
    rowLength = this.getRowLength();
    byteCol = byteIndex % rowLength;
    col = Math.floor(byteCol / BMPHexEditor.BYTES_PER_PIXEL);
    row = Math.floor(byteIndex / rowLength);
    if (col >= this.width) return 0;
    x = col;
    y = this.height - row - 1;
    offset = 4 * ((y * this.width) + x);
    value = 0;
    switch (byteCol % BMPHexEditor.BYTES_PER_PIXEL) {
      case 0:
        value = this.pixels[2 + offset];
        break;
      case 1:
        value = this.pixels[1 + offset];
        break;
      case 2:
        value = this.pixels[0 + offset];
    }
    return value;
  };

  BMPHexEditor.prototype.paddedHex = function(n) {
    var hex;
    hex = n.toString(16);
    if (hex.length === 1) hex = '0' + hex;
    return hex;
  };

  BMPHexEditor.prototype.getRowLength = function() {
    return Math.ceil((this.bitsPerPixel * this.width) / 32) * 4;
  };

  BMPHexEditor.prototype.getPixelArrayLength = function() {
    return this.getRowLength() * this.height;
  };

  BMPHexEditor.prototype.getFileLength = function() {
    return this.headerLength + this.getPixelArrayLength();
  };

  return BMPHexEditor;

})();
