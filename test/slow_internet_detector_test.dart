import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:slow_internet_detector/slow_internet_detector.dart';

void main() {
  group('SlowInternetInterceptor', () {
    late SlowInternetInterceptor interceptor;
    late Dio dio;

    setUp(() {
      interceptor = SlowInternetInterceptor(
        maxResponseDelayMs: 100,
      ); // 100ms threshold
      dio = Dio();
      dio.interceptors.add(interceptor);
    });

    test('should initialize notifier as false', () {
      expect(SlowInternetInterceptor.slowNetworkNotifier.value, false);
    });

    test('should detect slow request', () async {
      // Simulate request start
      interceptor.onRequest(
        RequestOptions(path: '/test'),
        RequestInterceptorHandler(),
      );

      // Wait longer than threshold
      await Future.delayed(const Duration(milliseconds: 200));

      // Simulate response after delay
      interceptor.onResponse(
        Response(requestOptions: RequestOptions(path: '/test')),
        ResponseInterceptorHandler(),
      );

      // Give async warning handler time to trigger
      await Future.delayed(const Duration(milliseconds: 300));

      expect(SlowInternetInterceptor.slowNetworkNotifier.value, true);
    });

    test('should reset notifier after settling time', () async {
      interceptor.onRequest(
        RequestOptions(path: '/test'),
        RequestInterceptorHandler(),
      );
      await Future.delayed(const Duration(milliseconds: 200));
      interceptor.onResponse(
        Response(requestOptions: RequestOptions(path: '/test')),
        ResponseInterceptorHandler(),
      );

      // Wait for slow detection
      await Future.delayed(const Duration(milliseconds: 300));
      expect(SlowInternetInterceptor.slowNetworkNotifier.value, true);

      // Wait for reset after 5s (settling time)
      await Future.delayed(const Duration(milliseconds: 5200));
      expect(SlowInternetInterceptor.slowNetworkNotifier.value, false);
    });

    test('should not trigger slow warning for fast request', () async {
      interceptor.onRequest(
        RequestOptions(path: '/test'),
        RequestInterceptorHandler(),
      );

      // Simulate fast response (< threshold)
      await Future.delayed(const Duration(milliseconds: 50));
      interceptor.onResponse(
        Response(requestOptions: RequestOptions(path: '/test')),
        ResponseInterceptorHandler(),
      );

      await Future.delayed(const Duration(milliseconds: 150));
      expect(SlowInternetInterceptor.slowNetworkNotifier.value, false);
    });
  });
}
