import 'package:flutter/material.dart';

/// A dropdown menu that displays a list of options.
class DropdownMenu<T> extends StatefulWidget {
  /// The currently selected value.
  final T? value;

  /// Callback when a new option is selected.
  final Function(T?)? onChanged;

  /// List of dropdown options to display.
  final List<DropdownOption<T>> options;

  /// Placeholder text when no option is selected.
  final String? placeholder;

  /// Whether the dropdown is disabled.
  final bool disabled;

  /// Width of the dropdown menu.
  final double? width;

  /// Max height of the dropdown menu when opened.
  final double? maxHeight;

  /// Border radius of the dropdown.
  final double borderRadius;

  /// Icon to display at the end of the dropdown.
  final IconData? icon;

  /// Color of the dropdown background.
  final Color? backgroundColor;

  /// Color of the dropdown text.
  final Color? textColor;

  /// Color of the dropdown border.
  final Color? borderColor;

  /// Style for the dropdown text.
  final TextStyle? textStyle;

  /// Whether to align the menu to the left or right.
  final bool alignMenuToLeft;

  /// A message to display when there are no options.
  final String? noOptionsMessage;

  const DropdownMenu({
    Key? key,
    this.value,
    this.onChanged,
    required this.options,
    this.placeholder,
    this.disabled = false,
    this.width,
    this.maxHeight,
    this.borderRadius = 6.0,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.textStyle,
    this.alignMenuToLeft = true,
    this.noOptionsMessage,
  }) : super(key: key);

  @override
  State<DropdownMenu<T>> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<DropdownMenu<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  
  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (widget.disabled) return;
    
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleDropdown,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Positioned(
                width: widget.width ?? size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, size.height + 4),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Container(
                      constraints: widget.maxHeight != null
                          ? BoxConstraints(maxHeight: widget.maxHeight!)
                          : null,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border: Border.all(
                          color: widget.borderColor ?? Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: _buildDropdownList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdownList() {
    if (widget.options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          widget.noOptionsMessage ?? 'No options available',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: widget.options.map((option) {
          final isSelected = option.value == widget.value;
          
          return _DropdownItem<T>(
            option: option,
            isSelected: isSelected,
            onTap: () {
              if (option.disabled) return;
              
              if (widget.onChanged != null) {
                widget.onChanged!(option.value);
              }
              
              _toggleDropdown();
            },
            textColor: widget.textColor,
            textStyle: widget.textStyle,
          );
        }).toList(),
      ),
    );
  }

  String _getDisplayValue() {
    if (widget.value == null) {
      return widget.placeholder ?? 'Select an option';
    }
    
    for (final option in widget.options) {
      if (option.value == widget.value) {
        return option.label;
      }
    }
    
    return widget.placeholder ?? 'Select an option';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ?? Colors.grey[300]!;
    final effectiveTextColor = widget.textColor ?? Colors.black87;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.disabled
                ? Colors.grey[100]
                : (widget.backgroundColor ?? Colors.white),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isOpen
                  ? Theme.of(context).primaryColor
                  : effectiveBorderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getDisplayValue(),
                  style: widget.textStyle?.copyWith(
                    color: widget.disabled
                        ? Colors.grey[500]
                        : effectiveTextColor,
                  ) ?? TextStyle(
                    color: widget.disabled
                        ? Colors.grey[500]
                        : effectiveTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                widget.icon ?? Icons.arrow_drop_down,
                color: widget.disabled
                    ? Colors.grey[500]
                    : Colors.grey[700],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single item in the dropdown menu.
class _DropdownItem<T> extends StatelessWidget {
  final DropdownOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? textColor;
  final TextStyle? textStyle;

  const _DropdownItem({
    Key? key,
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.textColor,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: option.disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        color: isSelected ? Colors.grey[100] : null,
        child: Row(
          children: [
            if (option.icon != null) ...[
              option.icon!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                option.label,
                style: textStyle?.copyWith(
                  color: option.disabled
                      ? Colors.grey[400]
                      : (isSelected ? Theme.of(context).primaryColor : textColor),
                  fontWeight: isSelected ? FontWeight.bold : null,
                ) ?? TextStyle(
                  color: option.disabled
                      ? Colors.grey[400]
                      : (isSelected ? Theme.of(context).primaryColor : textColor),
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

/// Option data for dropdown menu.
class DropdownOption<T> {
  /// Value that this option represents.
  final T value;
  
  /// Display label.
  final String label;
  
  /// Whether this option is disabled.
  final bool disabled;
  
  /// Optional icon to display next to the label.
  final Widget? icon;
  
  /// Optional description text.
  final String? description;

  DropdownOption({
    required this.value,
    required this.label,
    this.disabled = false,
    this.icon,
    this.description,
  });
}