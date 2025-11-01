import 'package:flutter/material.dart';

class CustomCheckbox extends StatefulWidget {
  /// Whether the checkbox is checked or not
  final bool? checked;

  /// Callback when the checkbox state changes
  final ValueChanged<bool>? onChanged;

  /// Label text to display next to the checkbox
  final String? label;

  /// Whether the checkbox is disabled
  final bool disabled;

  /// Size of the checkbox
  final double size;

  /// Custom widget to use instead of the standard checkbox
  final Widget? icon;

  /// Whether the checkbox is in indeterminate state
  final bool? indeterminate;

  /// The color to use when the checkbox is checked
  final Color? activeColor;

  /// The color to use for the checkbox border when unchecked
  final Color? borderColor;

  /// Text style for the label
  final TextStyle? labelStyle;

  const CustomCheckbox({
    Key? key,
    this.checked,
    this.onChanged,
    this.label,
    this.disabled = false,
    this.size = 20.0,
    this.icon,
    this.indeterminate,
    this.activeColor,
    this.borderColor,
    this.labelStyle,
  }) : super(key: key);

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.checked ?? false;
  }

  @override
  void didUpdateWidget(CustomCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked != oldWidget.checked && widget.checked != null) {
      _checked = widget.checked!;
    }
  }

  void _handleTap() {
    if (widget.disabled) return;
    
    final newValue = !_checked;
    
    setState(() {
      _checked = newValue;
    });
    
    if (widget.onChanged != null) {
      widget.onChanged!(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveActiveColor = widget.activeColor ?? theme.colorScheme.primary;
    final effectiveBorderColor = widget.borderColor ?? Colors.grey.shade500;
    
    // Custom checkbox representation
    Widget checkboxWidget;
    
    if (widget.icon != null) {
      // Use custom icon if provided
      checkboxWidget = widget.icon!;
    } else if (widget.indeterminate == true) {
      // Indeterminate state
      checkboxWidget = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.disabled ? Colors.grey.shade300 : effectiveActiveColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.disabled ? Colors.grey.shade400 : effectiveActiveColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: widget.size * 0.6,
            height: 2,
            color: Colors.white,
          ),
        ),
      );
    } else {
      // Regular checkbox
      checkboxWidget = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _checked 
              ? (widget.disabled ? Colors.grey.shade300 : effectiveActiveColor) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _checked 
                ? (widget.disabled ? Colors.grey.shade400 : effectiveActiveColor)
                : (widget.disabled ? Colors.grey.shade400 : effectiveBorderColor),
            width: 2,
          ),
        ),
        child: _checked
            ? Icon(
                Icons.check,
                size: widget.size * 0.7,
                color: Colors.white,
              )
            : null,
      );
    }
    
    // If no label, just return the checkbox
    if (widget.label == null) {
      return GestureDetector(
        onTap: _handleTap,
        child: checkboxWidget,
      );
    }
    
    // With label
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkboxWidget,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label!,
              style: widget.labelStyle?.copyWith(
                color: widget.disabled ? Colors.grey.shade500 : widget.labelStyle?.color,
              ) ?? TextStyle(
                color: widget.disabled ? Colors.grey.shade500 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Checkbox Group widget to manage a group of related checkboxes
class CheckboxGroup<T> extends StatefulWidget {
  /// List of options to display
  final List<CheckboxOption<T>> options;
  
  /// Currently selected values
  final List<T>? value;
  
  /// Callback when selection changes
  final ValueChanged<List<T>>? onChanged;
  
  /// Whether the checkbox group is disabled
  final bool disabled;
  
  /// Layout direction (vertical or horizontal)
  final Axis direction;
  
  /// Spacing between checkboxes
  final double spacing;
  
  /// Label for the entire group
  final String? label;
  
  /// Style for the group label
  final TextStyle? labelStyle;

  const CheckboxGroup({
    Key? key,
    required this.options,
    this.value,
    this.onChanged,
    this.disabled = false,
    this.direction = Axis.vertical,
    this.spacing = 8.0,
    this.label,
    this.labelStyle,
  }) : super(key: key);

  @override
  State<CheckboxGroup<T>> createState() => _CheckboxGroupState<T>();
}

class _CheckboxGroupState<T> extends State<CheckboxGroup<T>> {
  late List<T> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = widget.value?.toList() ?? [];
  }

  @override
  void didUpdateWidget(CheckboxGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedValues = widget.value?.toList() ?? [];
    }
  }

  void _handleValueChange(T value, bool checked) {
    if (widget.disabled) return;
    
    final newValues = List<T>.from(_selectedValues);
    
    if (checked) {
      if (!newValues.contains(value)) {
        newValues.add(value);
      }
    } else {
      newValues.remove(value);
    }
    
    setState(() {
      _selectedValues = newValues;
    });
    
    if (widget.onChanged != null) {
      widget.onChanged!(newValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.options.map((option) {
      return CustomCheckbox(
        checked: _selectedValues.contains(option.value),
        onChanged: (checked) => _handleValueChange(option.value, checked),
        label: option.label,
        disabled: widget.disabled || option.disabled,
        activeColor: option.activeColor,
        labelStyle: option.labelStyle,
      );
    }).toList();

    Widget result;
    
    if (widget.direction == Axis.vertical) {
      result = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((checkbox) {
          return Padding(
            padding: EdgeInsets.only(bottom: widget.spacing),
            child: checkbox,
          );
        }).toList(),
      );
    } else {
      result = Row(
        children: children.map((checkbox) {
          return Padding(
            padding: EdgeInsets.only(right: widget.spacing),
            child: checkbox,
          );
        }).toList(),
      );
    }

    if (widget.label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: widget.labelStyle ?? const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          result,
        ],
      );
    }

    return result;
  }
}

/// Option data for checkbox group
class CheckboxOption<T> {
  /// Value that this option represents
  final T value;
  
  /// Display label
  final String label;
  
  /// Whether this option is disabled
  final bool disabled;
  
  /// Custom color when checked
  final Color? activeColor;
  
  /// Text style for the label
  final TextStyle? labelStyle;

  CheckboxOption({
    required this.value,
    required this.label,
    this.disabled = false,
    this.activeColor,
    this.labelStyle,
  });
}