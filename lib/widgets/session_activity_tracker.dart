import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class SessionActivityTracker extends StatefulWidget {
  final Widget child;
  const SessionActivityTracker({super.key, required this.child});

  @override
  State<SessionActivityTracker> createState() => _SessionActivityTrackerState();
}

class _SessionActivityTrackerState extends State<SessionActivityTracker> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (mounted) {
      context.read<AuthNotifier>().recordActivity();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => auth.recordActivity(),
      onPointerMove: (_) => auth.recordActivity(),
      onPointerHover: (_) => auth.recordActivity(),
      onPointerSignal: (_) => auth.recordActivity(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            widget.child,
            if (auth.isWarningActive)
              Positioned(
                top: 16,
                left: 24,
                right: 24,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.amber.shade900,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Внимание! Сессия завершится через ${auth.secondsUntilLogout} сек. из-за неактивности.',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => auth.recordActivity(),
                          child: const Text('Я здесь!'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
