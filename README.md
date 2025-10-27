# slow_internet_detector

A Flutter package that detects **slow internet connections** in real-time using a Dio interceptor.  
Easily display UI warnings (like banners, toasts, or snackbars) when network speed is poor.

---

## ✨ Features

- Detects slow internet connections automatically  
- Works with **Dio v4 to v5.9.0**  
- Provides `ValueNotifier` objects to update your UI reactively  
- Lightweight and dependency-free (besides Dio & Flutter)  
- No background timers — detection is event-driven  
- Can manually trigger detection anytime (e.g., on navigation or user actions)

---

## 🚀 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  slow_internet_detector: ^0.0.1
```

## 🧩 Usage

### Add the interceptor to Dio
```dart
final dio = Dio();
dio.interceptors.add(SlowInternetInterceptor(maxResponseDelayMs: 3000));
```

### Listen to slow network events
```dart
ValueListenableBuilder(
  valueListenable: SlowInternetInterceptor.slowNetworkNotifier,
  builder: (context, isSlow, _) {
    if (isSlow) return Text('⚠️ Slow Internet Detected');
    return SizedBox.shrink();
  },
);
```

### Manually check for slow network
```dart
SlowInternetInterceptor.instance.checkSlowRequests(
  updateHomeScreenVisibility: true,
);
```

### Example: GestureDetector or Navigation
NavigatorObserver Example
```dart
GestureDetector(
  onTap: () {
    // Manually check internet speed when user interacts
    SlowInternetInterceptor.instance.checkSlowRequests(
      updateHomeScreenVisibility: true,
    );
  },
  child: MyHomePage(),
);
```
NavigatorObserver Example
```dart
class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    // Re-check slow network when route changes
    SlowInternetInterceptor.instance.checkSlowRequests(
      updateHomeScreenVisibility: true,
    );
  }
}

```
