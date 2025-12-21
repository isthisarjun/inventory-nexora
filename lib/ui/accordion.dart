import 'package:flutter/material.dart';

/// An accordion component that can expand and collapse content.
class Accordion extends StatefulWidget {
  /// The title displayed in the header.
  final String title;
  
  /// Optional subtitle displayed below the title.
  final String? subtitle;
  
  /// The content to show when expanded.
  final Widget content;
  
  /// Whether the accordion is initially expanded.
  final bool initiallyExpanded;
  
  /// Whether the accordion is disabled.
  final bool disabled;
  
  /// Custom icon for the expanded state.
  final IconData? expandedIcon;
  
  /// Custom icon for the collapsed state.
  final IconData? collapsedIcon;
  
  /// Custom header widget instead of the default one.
  final Widget? customHeader;
  
  /// Border radius of the accordion.
  final double borderRadius;
  
  /// Callback when expanded state changes.
  final Function(bool)? onToggle;
  
  /// Header background color.
  final Color? headerBackgroundColor;
  
  /// Content background color.
  final Color? contentBackgroundColor;
  
  /// Text style for the title.
  final TextStyle? titleStyle;
  
  /// Text style for the subtitle.
  final TextStyle? subtitleStyle;
  
  /// Color of the icon.
  final Color? iconColor;

  const Accordion({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.initiallyExpanded = false,
    this.disabled = false,
    this.expandedIcon,
    this.collapsedIcon,
    this.customHeader,
    this.borderRadius = 8.0,
    this.onToggle,
    this.headerBackgroundColor,
    this.contentBackgroundColor,
    this.titleStyle,
    this.subtitleStyle,
    this.iconColor,
  });

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    _iconTurns = _controller.drive(Tween<double>(begin: 0.0, end: 0.5)
      .chain(CurveTween(curve: Curves.easeInOut)));
    
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (widget.disabled) return;
    
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      
      if (widget.onToggle != null) {
        widget.onToggle!(_isExpanded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveHeaderColor = widget.headerBackgroundColor ?? Colors.grey[50];
    final effectiveContentColor = widget.contentBackgroundColor ?? Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.borderRadius),
              topRight: Radius.circular(widget.borderRadius),
              bottomLeft: Radius.circular(_isExpanded ? 0 : widget.borderRadius),
              bottomRight: Radius.circular(_isExpanded ? 0 : widget.borderRadius),
            ),
            child: widget.customHeader ?? Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: widget.disabled 
                    ? Colors.grey[100] 
                    : effectiveHeaderColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.borderRadius - 1),
                  topRight: Radius.circular(widget.borderRadius - 1),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : widget.borderRadius - 1),
                  bottomRight: Radius.circular(_isExpanded ? 0 : widget.borderRadius - 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: widget.titleStyle?.copyWith(
                            color: widget.disabled 
                                ? Colors.grey[500] 
                                : widget.titleStyle?.color,
                          ) ?? TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.disabled 
                                ? Colors.grey[500] 
                                : Colors.black87,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: widget.subtitleStyle?.copyWith(
                              color: widget.disabled 
                                  ? Colors.grey[400] 
                                  : widget.subtitleStyle?.color,
                            ) ?? TextStyle(
                              fontSize: 12,
                              color: widget.disabled 
                                  ? Colors.grey[400] 
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      widget.collapsedIcon ?? Icons.keyboard_arrow_down,
                      color: widget.disabled 
                          ? Colors.grey[400] 
                          : (widget.iconColor ?? Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _heightFactor,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveContentColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(widget.borderRadius - 1),
                    bottomRight: Radius.circular(widget.borderRadius - 1),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: widget.content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A group of accordions where only one can be expanded at a time.
class AccordionGroup extends StatefulWidget {
  /// List of accordion items.
  final List<AccordionItem> items;
  
  /// Index of the initially expanded accordion.
  final int? initiallyExpandedIndex;
  
  /// Spacing between accordions.
  final double spacing;
  
  /// Border radius for all accordions.
  final double borderRadius;
  
  /// Background color for accordion headers.
  final Color? headerBackgroundColor;
  
  /// Background color for accordion content.
  final Color? contentBackgroundColor;
  
  /// Called when an accordion is toggled.
  final Function(int, bool)? onToggle;

  const AccordionGroup({
    super.key,
    required this.items,
    this.initiallyExpandedIndex,
    this.spacing = 8.0,
    this.borderRadius = 8.0,
    this.headerBackgroundColor,
    this.contentBackgroundColor,
    this.onToggle,
  });

  @override
  State<AccordionGroup> createState() => _AccordionGroupState();
}

class _AccordionGroupState extends State<AccordionGroup> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.initiallyExpandedIndex;
  }

  void _handleToggle(int index, bool isExpanded) {
    if (isExpanded) {
      setState(() {
        _expandedIndex = index;
      });
    } else if (_expandedIndex == index) {
      setState(() {
        _expandedIndex = null;
      });
    }
    
    if (widget.onToggle != null) {
      widget.onToggle!(index, isExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < widget.items.length - 1 ? widget.spacing : 0,
          ),
          child: Accordion(
            title: item.title,
            subtitle: item.subtitle,
            content: item.content,
            initiallyExpanded: _expandedIndex == index,
            disabled: item.disabled,
            expandedIcon: item.expandedIcon,
            collapsedIcon: item.collapsedIcon,
            customHeader: item.customHeader,
            borderRadius: widget.borderRadius,
            headerBackgroundColor: widget.headerBackgroundColor,
            contentBackgroundColor: widget.contentBackgroundColor,
            titleStyle: item.titleStyle,
            subtitleStyle: item.subtitleStyle,
            iconColor: item.iconColor,
            onToggle: (isExpanded) {
              if (isExpanded) {
                // Close any other expanded accordion
                if (_expandedIndex != null && _expandedIndex != index) {
                  _handleToggle(_expandedIndex!, false);
                }
              }
              _handleToggle(index, isExpanded);
            },
          ),
        );
      }).toList(),
    );
  }
}

/// Configuration for an accordion item.
class AccordionItem {
  /// The title displayed in the header.
  final String title;
  
  /// Optional subtitle displayed below the title.
  final String? subtitle;
  
  /// The content to show when expanded.
  final Widget content;
  
  /// Whether the accordion is disabled.
  final bool disabled;
  
  /// Custom icon for the expanded state.
  final IconData? expandedIcon;
  
  /// Custom icon for the collapsed state.
  final IconData? collapsedIcon;
  
  /// Custom header widget instead of the default one.
  final Widget? customHeader;
  
  /// Text style for the title.
  final TextStyle? titleStyle;
  
  /// Text style for the subtitle.
  final TextStyle? subtitleStyle;
  
  /// Color of the icon.
  final Color? iconColor;

  AccordionItem({
    required this.title,
    this.subtitle,
    required this.content,
    this.disabled = false,
    this.expandedIcon,
    this.collapsedIcon,
    this.customHeader,
    this.titleStyle,
    this.subtitleStyle,
    this.iconColor,
  });
}