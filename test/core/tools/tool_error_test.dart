import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/core/tools/tool_error.dart';

void main() {
  test('exposes exactly the six canonical codes', () {
    expect(kToolErrorCodes, {
      'InvalidInput',
      'InputTooLarge',
      'UnsupportedTool',
      'Cancelled',
      'ConverterUnavailable',
      'NetworkError',
    });
  });

  test('every canonical code has readable Chinese copy', () {
    for (final code in kToolErrorCodes) {
      final message = toolErrorMessage(code);
      expect(message, isNotEmpty, reason: code);
      expect(
        message.codeUnits.any((unit) => unit > 0x2e80),
        isTrue,
        reason: '$code must render Chinese, got "$message"',
      );
    }
  });

  test('normalises snake_case, kebab-case and PascalCase codes', () {
    expect(canonicalToolErrorCode('input_too_large'), 'InputTooLarge');
    expect(canonicalToolErrorCode('INPUT-TOO-LARGE'), 'InputTooLarge');
    expect(canonicalToolErrorCode('InvalidInput'), 'InvalidInput');
    expect(canonicalToolErrorCode('unsupported_format'), 'UnsupportedTool');
    expect(canonicalToolErrorCode('conversion_timeout'), 'ConverterUnavailable');
    expect(canonicalToolErrorCode('offline'), 'NetworkError');
    expect(canonicalToolErrorCode('mystery'), isNull);
    expect(canonicalToolErrorCode(null), isNull);
  });

  group('conversionFailureFor', () {
    test('uses the status when the server code is unknown', () {
      expect(
        conversionFailureFor(statusCode: 413).code,
        'InputTooLarge',
      );
      expect(
        conversionFailureFor(statusCode: 415).code,
        'UnsupportedTool',
      );
      expect(
        conversionFailureFor(statusCode: 400).code,
        'InvalidInput',
      );
      expect(
        conversionFailureFor(statusCode: 500).code,
        'ConverterUnavailable',
      );
      expect(
        conversionFailureFor(statusCode: 504).code,
        'ConverterUnavailable',
      );
    });

    test('keeps a readable detail but rejects stack traces and JSON', () {
      final withDetail = conversionFailureFor(
        statusCode: 502,
        detail: '渲染失败，请重试',
      );
      expect(withDetail.message, contains('渲染失败'));

      final withTrace = conversionFailureFor(
        statusCode: 500,
        detail: 'Traceback (most recent call last): File "x.py"',
      );
      expect(withTrace.message, isNot(contains('Traceback')));

      final withJson = conversionFailureFor(
        statusCode: 500,
        detail: '{"detail":"boom"}',
      );
      expect(withJson.message, isNot(contains('detail')));
    });
  });
}