import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// A Dio interceptor that detects slow internet connections
/// and exposes notifiers to help update your Flutter UI.
///
/// This class is part of the `slow_internet_detector` package.
/// It listens to network request durations and triggers a notifier
/// if a response takes longer than the configured threshold.
///
/// You can use [SlowInternetInterceptor.slowNetworkNotifier]
/// to display a banner, toast, or warning in your app UI
/// when the network is slow.
class SlowInternetInterceptor extends Interceptor {
  /// Notifies listeners when a slow internet connection is detected.
  ///
  /// Use this to reactively update your UI.
  /// Example:
  /// ```dart
  /// ValueListenableBuilder(
  ///   valueListenable: SlowInternetInterceptor.slowNetworkNotifier,
  ///   builder: (context, isSlow, _) {
  ///     if (isSlow) return Text('Slow internet detected');
  ///     return SizedBox.shrink();
  ///   },
  /// );
  /// ```
  static final slowNetworkNotifier = ValueNotifier(false);

  /// Tracks whether the home screen is currently visible.
  ///
  /// Used internally to prevent displaying warnings when the user
  /// is not on the home screen.
  static final isHomeScreenVisible = ValueNotifier(false);

  /// Singleton instance of [SlowInternetInterceptor].
  static final SlowInternetInterceptor instance =
      SlowInternetInterceptor._internal();

  SlowInternetInterceptor._internal();

  /// Factory constructor that initializes or updates the
  /// maximum response delay threshold in milliseconds.
  ///
  /// Example:
  /// ```dart
  /// final dio = Dio();
  /// dio.interceptors.add(SlowInternetInterceptor(maxResponseDelayMs: 3000));
  /// ```
  factory SlowInternetInterceptor({int maxResponseDelayMs = 3000}) {
    instance._maxResponseDelayMs = maxResponseDelayMs;
    return instance;
  }

  /// Maximum allowed time (in milliseconds) for a network request
  /// before it is considered "slow".
  int _maxResponseDelayMs = 0;

  /// The timestamp when the request started.
  int? _startTime;

  /// Whether a slow network warning is currently visible.
  bool _isWarningVisible = false;

  /// Time (in milliseconds) for which the warning remains visible
  /// after detection, to prevent flickering.
  static const int _settlingTimeMs = 5000;

  /// Called when a new request starts.
  ///
  /// Records the start time and checks if there are any slow requests.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _startTime ??= DateTime.now().millisecondsSinceEpoch;
    super.onRequest(options, handler);
    checkSlowRequests();
  }

  /// Called when a response is received successfully.
  ///
  /// Marks the end of the request and checks whether it was slow.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    checkSlowRequests(requestFinished: true);
    super.onResponse(response, handler);
  }

  /// Called when an error occurs during the request.
  ///
  /// Ensures slow network detection is still processed even if the request fails.
  @override
  void onError(err, ErrorInterceptorHandler handler) {
    checkSlowRequests(requestFinished: true);
    super.onError(err, handler);
  }

  /// Core function that measures elapsed request time
  /// and determines if the internet is slow.
  ///
  /// [requestFinished] resets the start time after the request completes.
  /// [updateHomeScreenVisibility] updates screen visibility state.
  void checkSlowRequests({
    bool requestFinished = false,
    bool updateHomeScreenVisibility = false,
  }) {
    int? localStartTime = _startTime;

    if (requestFinished) {
      _startTime = null;
    }

    if (updateHomeScreenVisibility) {
      _updateHomeScreenVisibility();
    }

    if (localStartTime == null) return;

    final elapsed = DateTime.now().millisecondsSinceEpoch - localStartTime;

    if (elapsed > _maxResponseDelayMs && !_isWarningVisible) {
      _handleSlowInternetWarning(localStartTime);
    } else {
      if (updateHomeScreenVisibility) {
        _updateHomeScreenVisibility();
      }
    }
  }

  /// Updates whether the home screen is currently visible.
  ///
  /// Used internally to control visibility-based behavior.
  void _updateHomeScreenVisibility({bool alwaysCheck = false}) {
    if (slowNetworkNotifier.value || alwaysCheck) {
      isHomeScreenVisible.value = _getIsHomeScreenVisible();
    }
  }

  /// Handles slow internet detection and triggers the warning notifier.
  ///
  /// Keeps the notifier active for a short "settling" period to prevent
  /// flickering between fast and slow states.
  Future<void> _handleSlowInternetWarning(int time) async {
    await Future.delayed(const Duration(milliseconds: 250));

    _updateHomeScreenVisibility(alwaysCheck: true);
    slowNetworkNotifier.value = true;
    _isWarningVisible = true;

    Future.delayed(const Duration(milliseconds: _settlingTimeMs), () {
      if (time == _startTime) {
        _startTime = null;
      }
      slowNetworkNotifier.value = false;
      _isWarningVisible = false;
    });
  }

  /// Optional reference to the home screen's [BuildContext].
  ///
  /// This can be used to detect if the home screen is currently visible.
  BuildContext? homeScreenContext;

  /// Determines if the current home screen route is visible.
  ///
  /// Returns `true` if the provided context corresponds to the
  /// currently active route.
  bool _getIsHomeScreenVisible() {
    try {
      final context = homeScreenContext;
      if (context != null && context.mounted) {
        if (ModalRoute.of(context)?.isCurrent == true) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
}
