import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:splash_generator/src/image/android_splash_image_transformer.dart';
import 'package:test/test.dart';

void main() {
  group('transformAndroidSplashImage', () {
    test('preserves landscape geometry and centers it', () {
      final source = _solidImage(width: 4, height: 2);

      final result = _decode(transformAndroidSplashImage(_encodePng(source)));

      expect(result.width, 1152);
      expect(result.height, 1152);
      expect(result.getPixel(193, 385).a, 255);
      expect(result.getPixel(958, 766).a, 255);
      expect(result.getPixel(191, 385).a, 0);
      expect(result.getPixel(193, 383).a, 0);
      expect(result.getPixel(960, 766).a, 0);
      expect(result.getPixel(958, 768).a, 0);
    });

    test('preserves portrait geometry and centers it', () {
      final source = _solidImage(width: 2, height: 4);

      final result = _decode(transformAndroidSplashImage(_encodePng(source)));

      expect(result.width, 1152);
      expect(result.height, 1152);
      expect(result.getPixel(384, 192).a, 255);
      expect(result.getPixel(767, 959).a, 255);
      expect(result.getPixel(383, 192).a, 0);
      expect(result.getPixel(384, 191).a, 0);
      expect(result.getPixel(768, 959).a, 0);
      expect(result.getPixel(767, 960).a, 0);
    });

    test('preserves transparent pixels inside the source image', () {
      final source = img.Image(width: 2, height: 2, numChannels: 4)
        ..setPixel(0, 0, img.ColorUint8.rgba(255, 0, 0, 0))
        ..setPixel(1, 0, img.ColorUint8.rgba(255, 0, 0, 255))
        ..setPixel(0, 1, img.ColorUint8.rgba(255, 0, 0, 255))
        ..setPixel(1, 1, img.ColorUint8.rgba(255, 0, 0, 0));

      final result = _decode(transformAndroidSplashImage(_encodePng(source)));

      expect(result.getPixel(192, 192).a, 0);
      expect(result.getPixel(959, 192).a, 255);
      expect(result.getPixel(192, 959).a, 255);
      expect(result.getPixel(959, 959).a, 0);
    });

    test('normalizes EXIF orientation before fitting', () {
      final result = _decode(
        transformAndroidSplashImage(base64Decode(_exifOrientationFixture)),
      );

      // Orientation 6 turns the 2x3 source into a 3x2 landscape image.
      expect(result.getPixel(192, 320).a, 255);
      expect(result.getPixel(320, 192).a, 0);
    });

    test('throws FormatException for invalid bytes', () {
      expect(
        () => transformAndroidSplashImage(Uint8List.fromList([0, 1, 2, 3])),
        throwsFormatException,
      );
    });
  });
}

img.Image _solidImage({required int width, required int height}) {
  return img.Image(width: width, height: height, numChannels: 4)
    ..clear(img.ColorUint8.rgba(255, 0, 0, 255));
}

Uint8List _encodePng(img.Image image) => img.encodePng(image);

img.Image _decode(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw StateError('Test fixture could not be decoded');
  }
  return image;
}

const _exifOrientationFixture =
    '/9j/4AAQSkZJRgABAQAAAQABAAD/4QAiRXhpZgAATU0AKgAAAAgAAQESAAMAAAABAAYAAAAAAAD/2wCEAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAf/AABEIAAMAAgMBEQACEQEDEQH/xAGiAAABBQEBAQEBAQAAAAAAAAAAAQIDBAUGBwgJCgsQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+gEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoLEQACAQIEBAMEBwUEBAABAncAAQIDEQQFITEGEkFRB2FxEyIygQgUQpGhscEJIzNS8BVictEKFiQ04SXxFxgZGiYnKCkqNTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqCg4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2dri4+Tl5ufo6ery8/T19vf4+fr/2gAMAwEAAhEDEQA/APxfr/Kc/wC/g//Z';
