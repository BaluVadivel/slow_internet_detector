import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:slow_internet_detector/slow_internet_detector.dart';

void main() {
  runApp(const SlowInternetExampleApp());
}

class SlowInternetExampleApp extends StatefulWidget {
  const SlowInternetExampleApp({super.key});

  @override
  State<SlowInternetExampleApp> createState() => _SlowInternetExampleAppState();
}

class _SlowInternetExampleAppState extends State<SlowInternetExampleApp> {
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(SlowInternetInterceptor(maxResponseDelayMs: 3000));
  }

  Future<void> _makeRequest() async {
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/todos/1');
    } catch (e) {
      debugPrint('Request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Manually check for slow internet when user taps
        SlowInternetInterceptor.instance.checkSlowRequests(
          updateHomeScreenVisibility: true,
        );
      },
      child: MaterialApp(
        title: 'Slow Internet Detector Example',
        home: Scaffold(
          appBar: AppBar(title: const Text('Slow Internet Detector Example')),
          body: Stack(
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: _makeRequest,
                  child: const Text('Make Network Request'),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: SlowInternetInterceptor.slowNetworkNotifier,
                builder: (context, isSlow, _) {
                  if (!isSlow) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '⚠️ Slow Internet Connection Detected',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
