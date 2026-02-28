import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Global network status banner.
///
/// Uses a real DNS lookup to detect internet access (not just whether a
/// network interface is present — connectivity_plus reports "connected"
/// on Android emulators even with no real internet).
///
/// Slides in from the top when offline, flashes green for 2.5 s on reconnect.
/// Place once in MaterialApp.builder to cover all screens.
class NetworkBanner extends StatefulWidget {
  const NetworkBanner({super.key});

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  // null = banner hidden, false = showing offline, true = showing reconnected
  bool? _bannerState;
  bool _lastKnownOffline = false;
  bool _checking = false;

  Timer? _hideTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    // Check immediately on startup, then every 8 s
    _checkAndUpdate();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _checkAndUpdate(),
    );
  }

  /// Performs an actual DNS lookup to verify internet reachability.
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('firestore.googleapis.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkAndUpdate() async {
    if (_checking || !mounted) return;
    _checking = true;

    try {
      final online = await _hasInternet();
      if (!mounted) return;

      final nowOffline = !online;

      if (nowOffline && !_lastKnownOffline) {
        // Transition: online → offline
        _lastKnownOffline = true;
        _hideTimer?.cancel();
        setState(() => _bannerState = false);
        _ctrl.forward();
      } else if (!nowOffline && _lastKnownOffline) {
        // Transition: offline → online
        _lastKnownOffline = false;
        _hideTimer?.cancel();
        setState(() => _bannerState = true);
        _hideTimer = Timer(const Duration(milliseconds: 2500), () {
          if (!mounted) return;
          _ctrl.reverse().then((_) {
            if (mounted) setState(() => _bannerState = null);
          });
        });
      }
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pollTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerState == null) return const SizedBox.shrink();

    final topPad = MediaQuery.of(context).padding.top;
    final isOffline = _bannerState == false;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isOffline
                ? const Color(0xFFB91C1C)
                : const Color(0xFF15803D),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                isOffline ? 'אין חיבור לאינטרנט' : 'החיבור לאינטרנט שוחזר ✓',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              if (isOffline) ...[
                const SizedBox(width: 8),
                Text(
                  'פועל במצב לא מקוון',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
