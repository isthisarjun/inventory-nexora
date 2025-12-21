import 'package:flutter/material.dart';

/// A card component that provides a flexible container with various sections.
class Card extends StatelessWidget {
  /// The main content of the card.
  final Widget? child;
  
  /// Header content displayed at the top of the card.
  final Widget? header;
  
  /// Title content displayed below the header.
  final Widget? title;
  
  /// Description content displayed below the title.
  final Widget? description;
  
  /// Footer content displayed at the bottom of the card.
  final Widget? footer;
  
  /// Whether the card should have a border.
  final bool hasBorder;
  
  /// Elevation level of the card, providing shadow depth.
  final double elevation;
  
  /// Background color of the card.
  final Color? backgroundColor;
  
  /// Custom padding for the card content.
  final EdgeInsetsGeometry? padding;
  
  /// Custom margin around the card.
  final EdgeInsetsGeometry? margin;
  
  /// Border radius of the card.
  final double borderRadius;
  
  const Card({
    super.key,
    this.child,
    this.header,
    this.title,
    this.description,
    this.footer,
    this.hasBorder = true,
    this.elevation = 1.0,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: Colors.grey[200]!,
                width: 1.0,
              )
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) _buildHeader(header!),
            if (title != null || description != null) _buildTitleSection(),
            if (child != null) _buildContent(child!),
            if (footer != null) _buildFooter(footer!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Widget header) {
    return header;
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: padding ??
          const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 8.0,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) title!,
          if (title != null && description != null) const SizedBox(height: 4.0),
          if (description != null) description!,
        ],
      ),
    );
  }

  Widget _buildContent(Widget content) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: content,
    );
  }

  Widget _buildFooter(Widget footer) {
    return footer;
  }
}

/// A specialized header component for the Card.
class CardHeader extends StatelessWidget {
  final Widget? child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const CardHeader({
    super.key,
    this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1.0,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// A specialized footer component for the Card.
class CardFooter extends StatelessWidget {
  final Widget? child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const CardFooter({
    super.key,
    this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1.0,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// A specialized title component for the Card.
class CardTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const CardTitle({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ??
          const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

/// A specialized description component for the Card.
class CardDescription extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const CardDescription({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ??
          TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
    );
  }
}