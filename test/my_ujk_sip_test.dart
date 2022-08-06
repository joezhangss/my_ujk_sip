import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ujk_sip/my_ujk_sip.dart';

void main() {
  const MethodChannel channel = MethodChannel('my_ujk_sip');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  // test('getPlatformVersion', () async {
  //   expect(await MyUjkSip.platformVersion, '42');
  // });
}
