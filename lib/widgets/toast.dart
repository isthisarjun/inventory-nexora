import 'package:flutter/material.dart';
import 'dart:async';

/// Types of toast messages.
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Position for the toast on the screen.
enum ToastPosition {
  top,
  bottom,
}

/// Controller to manage toast notifications.
class ToastController {
  static final ToastController _instance = ToastController._internal();
  factory ToastController() => _instance;
  ToastController._internal();

  final _streamController = StreamController<ToastNotification>.broadcast();
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
  void success(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      title: title,
      type: ToastType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Show an error toast.
  void error(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      title: title,
      type: ToastType.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Show a warning toast.
  void warning(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      title: title,
      type: ToastType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Show an info toast.
  void info(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      title: title,
      type: ToastType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

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
  final Widget child;

  const ToastManager({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ToastManager> createState() => _ToastManagerState();
}

class _ToastManagerState extends State<ToastManager> {
  final List<ToastNotification> _topNotifications = [];
  final List<ToastNotification> _bottomNotifications = [];
  final ToastController _controller = ToastController();

  @override
  void initState() {
    super.initState();
    _controller.stream.listen((notification) {
      setState(() {
        if (notification.position == ToastPosition.top) {
          _topNotifications.add(notification);
        } else {
          _bottomNotifications.add(notification);
        }
      });

      // Auto-dismiss after duration
      Future.delayed(notification.duration, () {
        setState(() {
          if (notification.position == ToastPosition.top) {
            _topNotifications.remove(notification);
          } else {
            _bottomNotifications.remove(notification);
          }
        });
        if (notification.onDismiss != null) {
          notification.onDismiss!();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_topNotifications.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              children: _topNotifications.map((notification) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildToast(notification),
                );
              }).toList(),
            ),
          ),
        if (_bottomNotifications.isNotEmpty)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Column(
              children: _bottomNotifications.map((notification) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildToast(notification),
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

    return Material(
      elevation: 6.0,
      borderRadius: BorderRadius.circular(8.0),
      color: style.backgroundColor,
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.horizontal,
        onDismissed: (_) {
          setState(() {
            if (notification.position == ToastPosition.top) {
              _topNotifications.remove(notification);
            } else {
              _bottomNotifications.remove(notification);
            }
          });
          if (notification.onDismiss != null) {
            notification.onDismiss!();
          }
        },
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
                    setState(() {
                      if (notification.position == ToastPosition.top) {
                        _topNotifications.remove(notification);
                      } else {
                        _bottomNotifications.remove(notification);
                      }
                    });
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
                onPressed: () {
                  setState(() {
                    if (notification.position == ToastPosition.top) {
                      _topNotifications.remove(notification);
                    } else {
                      _bottomNotifications.remove(notification);
                    }
                  });
                  if (notification.onDismiss != null) {
                    notification.onDismiss!();
                  }
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

/// Global toast function for easy access.
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