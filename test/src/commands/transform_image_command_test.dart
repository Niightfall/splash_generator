import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:splash_generator/src/command_runner.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockStdin extends Mock implements Stdin {}

void main() {
  group('transform', () {
    late Logger logger;
    late SplashGeneratorCommandRunner commandRunner;
    final stdin = _MockStdin();

    setUp(() {
      logger = _MockLogger();
      commandRunner = SplashGeneratorCommandRunner(logger: logger);
    });

    test('missing stdin input', () async {
      when(() => stdin.readLineSync(encoding: utf8)).thenReturn(null);
      final exitCode = await IOOverrides.runZoned(
        () async => commandRunner.run(['transform']),
        stdin: () => stdin,
      );

      expect(exitCode, ExitCode.ioError.code);

      verify(
        () => logger.info('Transforming image, please provide the full path to the image:'),
      ).called(1);
      verify(() => stdin.readLineSync(encoding: utf8)).called(1);
      verify(() => logger.info('No input provided')).called(1);
    });

    test('invalid image path format', () async {
      const invalidInput = 'input';
      when(() => stdin.readLineSync(encoding: utf8)).thenReturn(invalidInput);
      final exitCode = await IOOverrides.runZoned(
        () async => commandRunner.run(['transform']),
        stdin: () => stdin,
      );

      expect(exitCode, ExitCode.osFile.code);

      verify(
        () => logger.info('Transforming image, please provide the full path to the image:'),
      ).called(1);
      verify(() => stdin.readLineSync(encoding: utf8)).called(1);
      verify(() => logger.info('invalid format: $invalidInput')).called(1);
    });

    test('non-existent image path input', () async {
      const nonExistentPath = '/path/to/nonexistent/image.png';
      when(() => stdin.readLineSync(encoding: utf8))
          .thenReturn(nonExistentPath);
      final exitCode = await IOOverrides.runZoned(
        () async => commandRunner.run(['transform']),
        stdin: () => stdin,
      );

      expect(exitCode, ExitCode.osFile.code);

      verify(() => logger.info('Transforming image, please provide the full path to the image:')).called(1);
      verify(() => stdin.readLineSync(encoding: utf8)).called(1);
      verify(() => logger.info('File does not exist: $nonExistentPath'))
          .called(1);
    });

    test('throws decoding exception for invalid image file', () async {
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/invalid.png');

      // Write invalid (non-image) data
      await tempFile.writeAsBytes([0, 1, 2, 3, 4, 5]);

      when(() => stdin.readLineSync(encoding: utf8)).thenReturn(tempFile.path);

      final exitCode = await IOOverrides.runZoned(
            () async => commandRunner.run(['transform']),
        stdin: () => stdin,
      );

      expect(exitCode, ExitCode.software.code);

      verify(() => logger.info('Transforming image, please provide the full path to the image:')).called(1);
      verify(() => stdin.readLineSync(encoding: utf8)).called(1);
      verify(() => logger.info('File exists: ${tempFile.path}')).called(1);
      verify(() => logger.err('Error transforming image: Exception: Could not decode image')).called(1);

      await tempDir.delete(recursive: true);
    });


    test('successful image path input, open file and transform it to 768x768', () async {
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/test.png');

      // Create a valid 1x1 PNG image
      final testImage = img.Image(width: 1, height: 1);
      final pngBytes = img.encodePng(testImage);
      await tempFile.writeAsBytes(pngBytes);

      when(() => stdin.readLineSync(encoding: utf8)).thenReturn(tempFile.path);

      final exitCode = await IOOverrides.runZoned(
            () async => commandRunner.run(['transform']),
        stdin: () => stdin,
      );

      expect(exitCode, ExitCode.success.code);

      verify(() => logger.info('Transforming image, please provide the full path to the image:')).called(1);
      verify(() => stdin.readLineSync(encoding: utf8)).called(1);
      verify(() => logger.info('File exists: ${tempFile.path}')).called(1);

      // Check image size
      final resultBytes = await tempFile.readAsBytes();
      final image = img.decodeImage(resultBytes);
      expect(image, isNotNull);
      expect(image!.width, equals(1152));
      expect(image.height, equals(1152));

      // Check that the corners are transparent
      expect(image.getPixel(0, 0).a, equals(0));
      expect(image.getPixel(1151, 0).a, equals(0));
      expect(image.getPixel(0, 1151).a, equals(0));
      expect(image.getPixel(1151, 1151).a, equals(0));


      await tempDir.delete(recursive: true);
    });

    test('wrong usage', () async {
      final exitCode = await commandRunner.run(['transform', '-p']);

      expect(exitCode, ExitCode.usage.code);

      verify(
        () => logger.err('Could not find an option or flag "-p".'),
      ).called(1);
      verify(
        () => logger.info('''
Usage: $executableName transform [arguments]
-h, --help    Print this usage information.

Run "$executableName help" to see global options.'''),
      ).called(1);
    });
  });
}
