import 'package:flutter/material.dart';
import 'dart:async';

/// Types of toast messages.
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Positions where toasts can appear.
enum ToastPosition {
  top,
  bottom,
}

/// Controller to manage toast notifications.
class ToastController {
  static final ToastController _instance = ToastController._internal();
  
  /// Get the singleton instance of the toast controller.
  factory ToastController() => _instance;
  
  ToastController._internal();

  final _streamController = StreamController<ToastNotification>.broadcast();
  
  /// Stream of toast notifications.
  Stream<ToastNotification> get stream => _streamController.stream;

  /// Show a toast notification.
  void show({
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final notification = ToastNotification(
      message: message,
      title: title,
      type: type,
      duration: duration,
      position: position,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
    _streamController.add(notification);
  }

  /// Show a success toast.
  void success(String message, {
    String? title,
    Duration? duration,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.success,
      duration: duration ?? const Duration(seconds: 3),
      position: position,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an error toast.
  void error(String message, {
    String? title,
    Duration? duration,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.error,
      duration: duration ?? const Duration(seconds: 4),
      position: position,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a warning toast.
  void warning(String message, {
    String? title,
    Duration? duration,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.warning,
      duration: duration ?? const Duration(seconds: 3),
      position: position,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an info toast.
  void info(String message, {
    String? title,
    Duration? duration,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      message: message,
      title: title,
      type: ToastType.info,
      duration: duration ?? const Duration(seconds: 3),
      position: position,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Dispose the controller.
  void dispose() {
    _streamController.close();
  }
}

/// Data class for a toast notification.
class ToastNotification {
  final String message;
  final String? title;
  final ToastType type;
  final Duration duration;
  final ToastPosition position;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  ToastNotification({
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    required this.position,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });
}

/// Toast manager widget that displays toast notifications.
class ToastManager extends StatefulWidget {
  /// The child widget that the toast will be displayed over.
  final Widget child;
  
  /// Maximum number of toasts to show at once.
  final int maxToasts;

  const ToastManager({
    Key? key,
    required this.child,
    this.maxToasts = 3,
  }) : super(key: key);

  @override
  State<ToastManager> createState() => _ToastManagerState();
}

class _ToastManagerState extends State<ToastManager> with SingleTickerProviderStateMixin {
  final List<ToastNotification> _topNotifications = [];
  final List<ToastNotification> _bottomNotifications = [];
  final ToastController _controller = ToastController();
  
  /// Map to track toast timers for auto-dismissal
  final Map<ToastNotification, Timer> _toastTimers = {};
  
  /// Animation controller for toasts
  late AnimationController _animationController;
  final Map<ToastNotification, Animation<double>> _animations = {};

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _controller.stream.listen((notification) {
      setState(() {
        if (notification.position == ToastPosition.top) {
          if (_topNotifications.length >= widget.maxToasts) {
            // Remove the oldest toast
            _removeToast(_topNotifications.first);
          }
          _topNotifications.add(notification);
        } else {
          if (_bottomNotifications.length >= widget.maxToasts) {
            // Remove the oldest toast
            _removeToast(_bottomNotifications.first);
          }
          _bottomNotifications.add(notification);
        }
        
        // Create animation for this toast
        final animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ));
        
        _animations[notification] = animation;
        _animationController.forward(from: 0.0);
        
        // Auto-dismiss after duration
        _toastTimers[notification] = Timer(notification.duration, () {
          _removeToast(notification);
        });
      });
    });
  }

  @override
  void dispose() {
    // Cancel all timers
    for (final timer in _toastTimers.values) {
      timer.cancel();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _removeToast(ToastNotification notification) {
    // Cancel the timer if it exists
    if (_toastTimers.containsKey(notification)) {
      _toastTimers[notification]!.cancel();
      _toastTimers.remove(notification);
    }
    
    setState(() {
      if (notification.position == ToastPosition.top) {
        _topNotifications.remove(notification);
      } else {
        _bottomNotifications.remove(notification);
      }
      _animations.remove(notification);
    });
    
    if (notification.onDismiss != null) {
      notification.onDismiss!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Top toasts
        if (_topNotifications.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              children: _topNotifications.map((notification) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final animation = _animations[notification] ?? const AlwaysStoppedAnimation(1.0);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildToast(notification),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        // Bottom toasts
        if (_bottomNotifications.isNotEmpty)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Column(
              children: _bottomNotifications.map((notification) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final animation = _animations[notification] ?? const AlwaysStoppedAnimation(1.0);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildToast(notification),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildToast(ToastNotification notification) {
    // Get style based on type
    final style = _getToastStyle(notification.type);

    return Dismissible(
      key: ObjectKey(notification),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        _removeToast(notification);
      },
      child: Material(
        elevation: 6.0,
        borderRadius: BorderRadius.circular(8.0),
        color: style.backgroundColor,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Row(
            children: [
              Icon(
                style.icon,
                color: style.iconColor,
                size: 24.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (notification.title != null)
                      Text(
                        notification.title!,
                        style: TextStyle(
                          color: style.titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    if (notification.title != null) const SizedBox(height: 4.0),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: style.messageColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (notification.onAction != null && notification.actionLabel != null)
                TextButton(
                  onPressed: () {
                    notification.onAction!();
                    _removeToast(notification);
                  },
                  child: Text(
                    notification.actionLabel!,
                    style: TextStyle(
                      color: style.actionColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                color: style.iconColor.withOpacity(0.7),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 18.0,
                onPressed: () {
                  _removeToast(notification);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ToastStyle _getToastStyle(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastStyle(
          backgroundColor: Colors.green[50]!,
          icon: Icons.check_circle,
          iconColor: Colors.green[700]!,
          titleColor: Colors.green[900]!,
          messageColor: Colors.green[800]!,
          actionColor: Colors.green[700]!,
        );
      case ToastType.error:
        return _ToastStyle(
          backgroundColor: Colors.red[50]!,
          icon: Icons.error,
          iconColor: Colors.red[700]!,
          titleColor: Colors.red[900]!,
          messageColor: Colors.red[800]!,
          actionColor: Colors.red[700]!,
        );
      case ToastType.warning:
        return _ToastStyle(
          backgroundColor: Colors.orange[50]!,
          icon: Icons.warning,
          iconColor: Colors.orange[700]!,
          titleColor: Colors.orange[900]!,
          messageColor: Colors.orange[800]!,
          actionColor: Colors.orange[700]!,
        );
      case ToastType.info:
      default:
        return _ToastStyle(
          backgroundColor: Colors.blue[50]!,
          icon: Icons.info,
          iconColor: Colors.blue[700]!,
          titleColor: Colors.blue[900]!,
          messageColor: Colors.blue[800]!,
          actionColor: Colors.blue[700]!,
        );
    }
  }
}

class _ToastStyle {
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final Color titleColor;
  final Color messageColor;
  final Color actionColor;

  _ToastStyle({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.titleColor,
    required this.messageColor,
    required this.actionColor,
  });
}

/// Global function to show a toast with default settings.
void showToast(
  String message, {
  String? title,
  ToastType type = ToastType.info,
  Duration? duration,
  ToastPosition position = ToastPosition.top,
  VoidCallback? onDismiss,
  VoidCallback? onAction,
  String? actionLabel,
}) {
  ToastController().show(
    message: message,
    title: title,
    type: type,
    duration: duration ?? const Duration(seconds: 3),
    position: position,
    onDismiss: onDismiss,
    onAction: onAction,
    actionLabel: actionLabel,
  );
}

/// Global functions for convenience.
void showSuccessToast(String message, {String? title, Duration? duration}) {
  ToastController().success(message, title: title, duration: duration);
}

void showErrorToast(String message, {String? title, Duration? duration}) {
  ToastController().error(message, title: title, duration: duration);
}

void showWarningToast(String message, {String? title, Duration? duration}) {
  ToastController().warning(message, title: title, duration: duration);
}

void showInfoToast(String message, {String? title, Duration? duration}) {
  ToastController().info(message, title: title, duration: duration);
}