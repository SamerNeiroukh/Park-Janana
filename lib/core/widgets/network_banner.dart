import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Displays a slim banner at the top when the device has no internet connection.
/// Automatically hides when connectivity is restored.
class NetworkBanner extends StatefulWidget {
  const NetworkBanner({super.key});

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Check current state immediately
    Connectivity().checkConnectivity().then(_handleResult);
    // Then listen for changes
    _sub = Connectivity()
        .onConnectivityChanged
        .listen(_handleResult);
  }

  void _handleResult(List<ConnectivityResult> results) {
    final offline = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);
    if (mounted && offline != _isOffline) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: const Color(0xFFDC2626), // red-600
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'אין חיבור לאינטרנט',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
