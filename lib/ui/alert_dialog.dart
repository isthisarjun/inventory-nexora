import 'package:flutter/material.dart';

/// A customizable alert dialog.
class AlertDialog extends StatelessWidget {
  /// The title of the dialog.
  final String? title;
  
  /// The description or content of the dialog.
  final String? description;
  
  /// A custom widget to use instead of the description text.
  final Widget? content;
  
  /// The primary action button.
  final AlertDialogAction? primaryAction;
  
  /// The secondary (cancel) action button.
  final AlertDialogAction? secondaryAction;
  
  /// Additional action buttons to display.
  final List<AlertDialogAction>? additionalActions;
  
  /// Icon to display at the top of the dialog.
  final IconData? icon;
  
  /// Color of the icon.
  final Color? iconColor;
  
  /// Background color of the icon container.
  final Color? iconBackgroundColor;
  
  /// Border radius of the dialog.
  final double borderRadius;
  
  /// Whether the dialog is dismissible by clicking outside.
  final bool isDismissible;
  
  /// Padding around the dialog content.
  final EdgeInsets contentPadding;
  
  /// Width of the dialog.
  final double? width;
  
  /// Max width of the dialog.
  final double? maxWidth;
  
  /// Whether to use a full-width button for the action(s).
  final bool useFullWidthButton;

  const AlertDialog({
    super.key,
    this.title,
    this.description,
    this.content,
    this.primaryAction,
    this.secondaryAction,
    this.additionalActions,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.borderRadius = 12.0,
    this.isDismissible = true,
    this.contentPadding = const EdgeInsets.all(24.0),
    this.width,
    this.maxWidth = 480.0,
    this.useFullWidthButton = false,
  });

  /// Show an alert dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? description,
    Widget? content,
    AlertDialogAction? primaryAction,
    AlertDialogAction? secondaryAction,
    List<AlertDialogAction>? additionalActions,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    double borderRadius = 12.0,
    bool isDismissible = true,
    EdgeInsets contentPadding = const EdgeInsets.all(24.0),
    double? width,
    double? maxWidth = 480.0,
    bool useFullWidthButton = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AlertDialog(
        title: title,
        description: description,
        content: content,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
        additionalActions: additionalActions,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        borderRadius: borderRadius,
        isDismissible: isDismissible,
        contentPadding: contentPadding,
        width: width,
        maxWidth: maxWidth,
        useFullWidthButton: useFullWidthButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button for dismissible dialogs
            if (isDismissible)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              )
            else
              const SizedBox(height: 16),
              
            // Icon if provided
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor ?? Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 28,
                      color: iconColor ?? Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              
            // Dialog content
            Padding(
              padding: contentPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        description!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                  if (content != null) content!,
                ],
              ),
            ),
            
            // Action buttons
            if (primaryAction != null || secondaryAction != null || (additionalActions?.isNotEmpty ?? false))
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: useFullWidthButton ? 0 : 24,
                  vertical: 24,
                ),
                child: _buildActions(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final allActions = <AlertDialogAction>[];
    
    if (secondaryAction != null) {
      allActions.add(secondaryAction!);
    }
    
    if (additionalActions != null) {
      allActions.addAll(additionalActions!);
    }
    
    if (primaryAction != null) {
      allActions.add(primaryAction!);
    }
    
    if (useFullWidthButton) {
      return Column(
        children: allActions.map((action) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24, 
              vertical: 4,
            ),
            child: SizedBox(
              width: double.infinity,
              child: _buildActionButton(context, action),
            ),
          );
        }).toList(),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: allActions.map((action) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(context, action),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildActionButton(BuildContext context, AlertDialogAction action) {
    final isPrimary = action == primaryAction;
    
    if (isPrimary) {
      return ElevatedButton(
        onPressed: () {
          if (action.onPressed != null) {
            action.onPressed!();
          }
          if (action.closeOnPress) {
            Navigator.of(context).pop(action.value);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: action.color ?? Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          action.label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: () {
          if (action.onPressed != null) {
            action.onPressed!();
          }
          if (action.closeOnPress) {
            Navigator.of(context).pop(action.value);
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: action.color ?? Colors.grey[300]!,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          action.label,
          style: TextStyle(
            color: action.color ?? Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}

/// Action button configuration for alert dialogs.
class AlertDialogAction {
  /// The label text of the button.
  final String label;
  
  /// Called when the button is pressed.
  final VoidCallback? onPressed;
  
  /// Whether to close the dialog when the button is pressed.
  final bool closeOnPress;
  
  /// The value to return when the dialog is closed by this action.
  final dynamic value;
  
  /// The color of the button.
  final Color? color;
  
  /// Whether this is a destructive action (e.g., delete).
  final bool isDestructive;

  AlertDialogAction({
    required this.label,
    this.onPressed,
    this.closeOnPress = true,
    this.value,
    this.color,
    this.isDestructive = false,
  });
}