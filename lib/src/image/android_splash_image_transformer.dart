import 'dart:typed_data';

import 'package:image/image.dart' as img;

const _maxImageDimension = 768;
const _canvasDimension = 1152;

/// Transforms encoded image bytes into the current Android splash image raster.
///
/// The output preserves the source aspect ratio, normalizes its orientation,
/// and centers the result on a transparent square canvas.
Uint8List transformAndroidSplashImage(Uint8List sourceBytes) {
  final img.Image? image;
  try {
    image = img.decodeImage(sourceBytes);
  } on Object {
    throw const FormatException('Could not decode image');
  }
  if (image == null) {
    throw const FormatException('Could not decode image');
  }

  final normalized = img.bakeOrientation(image);

  final img.Image resized;
  if (normalized.width >= normalized.height) {
    resized = img.copyResize(normalized, width: _maxImageDimension);
  } else {
    resized = img.copyResize(normalized, height: _maxImageDimension);
  }

  final canvas = img.Image(
    width: _canvasDimension,
    height: _canvasDimension,
    numChannels: 4,
  );
  img.fill(canvas, color: img.ColorUint8.rgba(0, 0, 0, 0));

  final offsetX = (_canvasDimension - resized.width) ~/ 2;
  final offsetY = (_canvasDimension - resized.height) ~/ 2;

  for (var y = 0; y < resized.height; y++) {
    for (var x = 0; x < resized.width; x++) {
      canvas.setPixel(x + offsetX, y + offsetY, resized.getPixel(x, y));
    }
  }

  return img.encodePng(canvas);
}
