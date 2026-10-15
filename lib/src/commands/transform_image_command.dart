import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:splash_generator/src/image/android_splash_image_transformer.dart';

class TransformImageCommand extends Command<int> {
  TransformImageCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'image-path',
      abbr: 'p',
      help: 'The path to the image file.',
    );
  }
  final Logger _logger;

  @override
  String get description =>
      'Prepares an Android splash image raster for Flutter projects.';

  @override
  String get name => 'transform';

  @override
  Future<int> run() async {
    final validImagePathRegex = RegExp(
      r'^(?:/|[a-zA-Z]:[\\/])(?:[\w\-\s.]+[\\/])*[\w\-\s.]+\.(png|jpg|jpeg|gif)$',
      caseSensitive: false,
    );

    // Use only the --image-path/-p option
    var input = argResults!['image-path'] as String?;

    if (input == null) {
      _logger.info(
        'Transforming image, please provide the full path to the image:',
      );
      input = stdin.readLineSync(encoding: utf8);
      _logger.info(input ?? 'No input provided');
      if (input == null) {
        return ExitCode.ioError.code;
      }
    }

    if (!validImagePathRegex.hasMatch(input)) {
      _logger.info('invalid format: $input');
      return ExitCode.osFile.code;
    }
    final file = File(input);
    if (!file.existsSync()) {
      _logger.info('File does not exist: $input');
      return ExitCode.osFile.code;
    }
    _logger.info('File exists: $input');
    try {
      final sourceBytes = await file.readAsBytes();
      final transformedBytes = transformAndroidSplashImage(sourceBytes);
      await file.writeAsBytes(transformedBytes);
      _logger.info('Image transformed successfully.');
    } on FormatException catch (e) {
      _logger.err('Error transforming image: Exception: ${e.message}');
      return ExitCode.software.code;
    } on Exception catch (e) {
      _logger.err('Error transforming image: $e');
      return ExitCode.software.code;
    }
    return ExitCode.success.code;
  }
}
