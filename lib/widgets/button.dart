import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  link,
  destructive,
  success,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class Button extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isFullWidth;
  final bool isLoading;
  final bool disabled;

  const Button({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectivelyDisabled = disabled || isLoading;
    
    // Get style properties based on variant
    final styleProps = _getStyleProperties();
    
    // Get size properties
    final sizeProps = _getSizeProperties();
    
    // Determine content padding
    final contentPadding = _getContentPadding();
    
    // Build button
    Widget button;
    
    switch (variant) {
      case ButtonVariant.link:
        button = TextButton(
          onPressed: effectivelyDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: styleProps.textColor,
            padding: contentPadding,
            textStyle: TextStyle(
              fontSize: sizeProps.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: _buildButtonContent(styleProps, sizeProps),
        );
        break;
        
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        button = OutlinedButton(
          onPressed: effectivelyDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: styleProps.textColor,
            side: variant == ButtonVariant.outline
                ? BorderSide(color: styleProps.borderColor!)
                : null,
            backgroundColor: variant == ButtonVariant.ghost 
                ? Colors.transparent 
                : null,
            padding: contentPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sizeProps.borderRadius),
            ),
          ),
          child: _buildButtonContent(styleProps, sizeProps),
        );
        break;
        
      default:
        button = ElevatedButton(
          onPressed: effectivelyDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: styleProps.backgroundColor,
            foregroundColor: styleProps.textColor,
            padding: contentPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sizeProps.borderRadius),
            ),
          ),
          child: _buildButtonContent(styleProps, sizeProps),
        );
    }
    
    // Apply full width if needed
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
  
  Widget _buildButtonContent(_StyleProperties styleProps, _SizeProperties sizeProps) {
    if (isLoading) {
      return SizedBox(
        width: sizeProps.iconSize,
        height: sizeProps.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(styleProps.textColor),
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: sizeProps.iconSize,
          ),
          SizedBox(width: sizeProps.iconSpacing),
          Text(
            text,
            style: TextStyle(
              fontSize: sizeProps.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    
    return Text(
      text,
      style: TextStyle(
        fontSize: sizeProps.fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  _StyleProperties _getStyleProperties() {
    switch (variant) {
      case ButtonVariant.primary:
        return _StyleProperties(
          backgroundColor: Colors.green[700]!,
          textColor: Colors.white,
          borderColor: Colors.green[700],
        );
      
      case ButtonVariant.secondary:
        return _StyleProperties(
          backgroundColor: Colors.grey[200]!,
          textColor: Colors.grey[800]!,
          borderColor: Colors.grey[300],
        );
      
      case ButtonVariant.outline:
        return _StyleProperties(
          backgroundColor: Colors.transparent,
          textColor: Colors.green[700]!,
          borderColor: Colors.green[700],
        );
      
      case ButtonVariant.ghost:
        return _StyleProperties(
          backgroundColor: Colors.transparent,
          textColor: Colors.green[700]!,
          borderColor: Colors.transparent,
        );
      
      case ButtonVariant.link:
        return _StyleProperties(
          backgroundColor: Colors.transparent,
          textColor: Colors.blue[700]!,
          borderColor: Colors.transparent,
        );
      
      case ButtonVariant.destructive:
        return _StyleProperties(
          backgroundColor: Colors.red[600]!,
          textColor: Colors.white,
          borderColor: Colors.red[600],
        );
      
      case ButtonVariant.success:
        return _StyleProperties(
          backgroundColor: Colors.green[600]!,
          textColor: Colors.white,
          borderColor: Colors.green[600],
        );
      
      default:
        return _StyleProperties(
          backgroundColor: Colors.green[700]!,
          textColor: Colors.white,
          borderColor: Colors.green[700],
        );
    }
  }
  
  _SizeProperties _getSizeProperties() {
    switch (size) {
      case ButtonSize.small:
        return _SizeProperties(
          height: 32,
          fontSize: 12,
          iconSize: 16,
          iconSpacing: 6,
          borderRadius: 4,
        );
      
      case ButtonSize.medium:
        return _SizeProperties(
          height: 40,
          fontSize: 14,
          iconSize: 18,
          iconSpacing: 8,
          borderRadius: 6,
        );
      
      case ButtonSize.large:
        return _SizeProperties(
          height: 48,
          fontSize: 16,
          iconSize: 20,
          iconSpacing: 10,
          borderRadius: 8,
        );
      
      default:
        return _SizeProperties(
          height: 40,
          fontSize: 14,
          iconSize: 18,
          iconSpacing: 8,
          borderRadius: 6,
        );
    }
  }
  
  EdgeInsets _getContentPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    }
  }
}

class _StyleProperties {
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  
  _StyleProperties({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });
}

class _SizeProperties {
  final double height;
  final double fontSize;
  final double iconSize;
  final double iconSpacing;
  final double borderRadius;
  
  _SizeProperties({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.iconSpacing,
    required this.borderRadius,
  });
}