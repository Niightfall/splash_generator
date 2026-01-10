import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:image/image.dart' as img;
import 'package:mason_logger/mason_logger.dart';

class TransformImageCommand extends Command<int> {

  TransformImageCommand({required Logger logger}) : _logger = logger;
  final Logger _logger;
  @override
  String get description => 'Transforms a png image into the dimensions needed for an android 12 flutter splash screen.';

  @override
  String get name => 'transform';

  @override
  Future<int> run() async {
    final validImagePathRegex = RegExp(r'^(?:/|[a-zA-Z]:[\\/])(?:[\w\-\s.]+[\\/])*[\w\-\s.]+\.(png|jpg|jpeg|gif)$', caseSensitive: false);
    _logger.info('Transforming image, please provide the full path to the image:');
    final input = stdin.readLineSync(encoding: utf8);
    _logger.info(input ?? 'No input provided');
    if (input == null) {
      return ExitCode.ioError.code;
    }
    if (!validImagePathRegex.hasMatch(input)) {
      _logger.info('invalid format: $input');
      return ExitCode.osFile.code;
    }
    final file = File(input);
    if (! file.existsSync()) {
      _logger.info('File does not exist: $input');
      return ExitCode.osFile.code;
    }
    _logger.info('File exists: $input');
    try {
      await scaleImageTo768(input);
      _logger.info('Image transformed successfully.');
    } on Exception catch (e) {
      _logger.err('Error transforming image: $e');
      return ExitCode.software.code;
    }
    return ExitCode.success.code;
  }

  Future<void> scaleImageTo768(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Could not decode image');

    // Normalize orientation if needed
    final normalized = img.bakeOrientation(image);

    // Resize to 768x768
    final resized = img.copyResize(normalized, width: 768, height: 768);

    // Create a new 1152x1152 transparent image
    final bolstered = img.Image(width: 1152, height: 1152, numChannels: 4);

    // Fill with transparent pixels
    img.fill(bolstered, color: img.ColorUint8.rgba(0, 0, 0, 0));


    // Calculate top-left position to center the resized image
    const offset = (1152 - 768) ~/ 2;

    // Manually copy pixels from resized to bolstered
    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        bolstered.setPixel(x + offset, y + offset, resized.getPixel(x, y));
      }
    }


    // Encode and save
    final outBytes = img.encodePng(bolstered);
    await file.writeAsBytes(outBytes);
  }

}
