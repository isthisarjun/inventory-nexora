import 'package:flutter/material.dart' as flutter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form container widget that handles validation and submission.
class Form extends StatefulWidget {
  /// Child widgets within the form.
  final Widget child;
  
  /// Called when the form is submitted and valid.
  final Function(Map<String, dynamic>)? onSubmit;
  
  /// Default values for form fields.
  final Map<String, dynamic>? defaultValues;
  
  /// Whether the form has a submit button.
  final bool hasSubmitButton;
  
  /// Text for the submit button.
  final String submitButtonText;
  
  /// Color for the submit button.
  final Color? submitButtonColor;
  
  /// Whether the form is currently submitting.
  final bool isSubmitting;
  
  const Form({
    Key? key,
    required this.child,
    this.onSubmit,
    this.defaultValues,
    this.hasSubmitButton = true,
    this.submitButtonText = 'Submit',
    this.submitButtonColor,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<Form> createState() => _FormState();
}

class _FormState extends State<Form> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formValues = {};

  @override
  void initState() {
    super.initState();
    if (widget.defaultValues != null) {
      _formValues.addAll(widget.defaultValues!);
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (widget.onSubmit != null) {
        widget.onSubmit!(_formValues);
      }
    }
  }

  void setFieldValue(String name, dynamic value) {
    setState(() {
      _formValues[name] = value;
    });
  }

  dynamic getFieldValue(String name) {
    return _formValues[name];
  }

  @override
  Widget build(BuildContext context) {
    return FormProvider(
      state: this,
      child: Column(
        children: [
          Flutter.Form(
            key: _formKey,
            child: widget.child,
          ),
          if (widget.hasSubmitButton) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.submitButtonColor ?? Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: widget.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.submitButtonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Provider to access form state from descendant widgets.
class FormProvider extends InheritedWidget {
  final _FormState state;

  const FormProvider({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  static _FormState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<FormProvider>();
    if (provider == null) {
      throw Exception('FormProvider not found in the widget tree');
    }
    return provider.state;
  }

  @override
  bool updateShouldNotify(FormProvider oldWidget) {
    return oldWidget.state != state;
  }
}

/// Label widget for form fields.
class FormLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final bool isOptional;
  final TextStyle? style;

  const FormLabel({
    Key? key,
    required this.text,
    this.isRequired = false,
    this.isOptional = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            text,
            style: style ??
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
          ),
          if (isRequired)
            Text(
              ' *',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          if (isOptional)
            Text(
              ' (Optional)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

/// Description text below form fields.
class FormDescription extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const FormDescription({
    Key? key,
    required this.text,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(
        text,
        style: style ??
            TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
      ),
    );
  }
}

/// Error message for form fields.
class FormError extends StatelessWidget {
  final String text;

  const FormError({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 14,
            color: Colors.red[700],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Input field for forms.
class FormInput extends StatelessWidget {
  final String name;
  final String? label;
  final String? placeholder;
  final String? description;
  final bool isRequired;
  final bool isDisabled;
  final bool isReadOnly;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String?)? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? prefix;
  final Widget? suffix;
  final String? error;
  final int? maxLength;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final Color? fillColor;
  final double borderRadius;

  const FormInput({
    Key? key,
    required this.name,
    this.label,
    this.placeholder,
    this.description,
    this.isRequired = false,
    this.isDisabled = false,
    this.isReadOnly = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.prefix,
    this.suffix,
    this.error,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formState = FormProvider.of(context);
    TextEditingController effectiveController = controller ?? TextEditingController();
    
    // Set initial value from form default values if controller is not provided
    if (controller == null && formState.getFieldValue(name) != null) {
      effectiveController.text = formState.getFieldValue(name).toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          FormLabel(
            text: label!,
            isRequired: isRequired,
          ),
        TextFormField(
          controller: effectiveController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: prefix,
            suffixIcon: suffix,
            filled: true,
            fillColor: isDisabled ? Colors.grey[100] : (fillColor ?? Colors.grey[50]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.green[700]!,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.red[700]!,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.red[700]!,
                width: 2.0,
              ),
            ),
            errorText: error,
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: isReadOnly || isDisabled,
          enabled: !isDisabled,
          maxLength: maxLength,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (validator != null) {
              return validator!(value);
            }
            return null;
          },
          onChanged: (value) {
            formState.setFieldValue(name, value);
            if (onChanged != null) {
              onChanged!(value);
            }
          },
          onSaved: (value) {
            formState.setFieldValue(name, value);
          },
        ),
        if (description != null) FormDescription(text: description!),
      ],
    );
  }
}

/// Textarea field for multi-line text input.
class FormTextarea extends StatelessWidget {
  final String name;
  final String? label;
  final String? placeholder;
  final String? description;
  final bool isRequired;
  final bool isDisabled;
  final bool isReadOnly;
  final String? Function(String?)? validator;
  final Function(String?)? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? error;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final Color? fillColor;
  final double borderRadius;

  const FormTextarea({
    Key? key,
    required this.name,
    this.label,
    this.placeholder,
    this.description,
    this.isRequired = false,
    this.isDisabled = false,
    this.isReadOnly = false,
    this.validator,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.error,
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 5,
    this.textCapitalization = TextCapitalization.sentences,
    this.fillColor,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormInput(
      name: name,
      label: label,
      placeholder: placeholder,
      description: description,
      isRequired: isRequired,
      isDisabled: isDisabled,
      isReadOnly: isReadOnly,
      validator: validator,
      onChanged: onChanged,
      controller: controller,
      focusNode: focusNode,
      error: error,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      fillColor: fillColor,
      borderRadius: borderRadius,
      keyboardType: TextInputType.multiline,
    );
  }
}

/// Select dropdown for forms.
class FormSelect extends StatelessWidget {
  final String name;
  final String? label;
  final String? placeholder;
  final String? description;
  final List<FormSelectOption> options;
  final bool isRequired;
  final bool isDisabled;
  final String? Function(String?)? validator;
  final Function(String?)? onChanged;
  final String? error;
  final Color? fillColor;
  final double borderRadius;

  const FormSelect({
    Key? key,
    required this.name,
    this.label,
    this.placeholder,
    this.description,
    required this.options,
    this.isRequired = false,
    this.isDisabled = false,
    this.validator,
    this.onChanged,
    this.error,
    this.fillColor,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formState = FormProvider.of(context);
    final currentValue = formState.getFieldValue(name) as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          FormLabel(
            text: label!,
            isRequired: isRequired,
          ),
        DropdownButtonFormField<String>(
          value: currentValue,
          hint: placeholder != null
              ? Text(placeholder!)
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDisabled ? Colors.grey[100] : (fillColor ?? Colors.grey[50]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.green[700]!,
                width: 2.0,
              ),
            ),
            errorText: error,
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label),
            );
          }).toList(),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (validator != null) {
              return validator!(value);
            }
            return null;
          },
          onChanged: isDisabled
              ? null
              : (value) {
                  formState.setFieldValue(name, value);
                  if (onChanged != null) {
                    onChanged!(value);
                  }
                },
          onSaved: (value) {
            formState.setFieldValue(name, value);
          },
        ),
        if (description != null) FormDescription(text: description!),
      ],
    );
  }
}

/// Option for select dropdown.
class FormSelectOption {
  final String value;
  final String label;

  FormSelectOption({
    required this.value,
    required this.label,
  });
}

/// Checkbox input for forms.
class FormCheckbox extends StatefulWidget {
  final String name;
  final String label;
  final String? description;
  final bool isRequired;
  final bool isDisabled;
  final bool? defaultValue;
  final Function(bool?)? onChanged;
  final String? error;

  const FormCheckbox({
    Key? key,
    required this.name,
    required this.label,
    this.description,
    this.isRequired = false,
    this.isDisabled = false,
    this.defaultValue,
    this.onChanged,
    this.error,
  }) : super(key: key);

  @override
  State<FormCheckbox> createState() => _FormCheckboxState();
}

class _FormCheckboxState extends State<FormCheckbox> {
  bool? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final formState = FormProvider.of(context);
    
    // If form has a value for this field, use it
    if (formState.getFieldValue(widget.name) != null) {
      _value = formState.getFieldValue(widget.name) as bool?;
    }

    return FormField<bool>(
      initialValue: _value ?? false,
      validator: (value) {
        if (widget.isRequired && (value == null || value == false)) {
          return 'This field is required';
        }
        return null;
      },
      onSaved: (value) {
        formState.setFieldValue(widget.name, value);
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _value ?? false,
                  onChanged: widget.isDisabled
                      ? null
                      : (value) {
                          setState(() {
                            _value = value;
                          });
                          formState.setFieldValue(widget.name, value);
                          state.didChange(value);
                          if (widget.onChanged != null) {
                            widget.onChanged!(value);
                          }
                        },
                  activeColor: Colors.green[700],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isDisabled ? Colors.grey[500] : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.description != null)
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: FormDescription(text: widget.description!),
              ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: FormError(text: state.errorText!),
              ),
          ],
        );
      },
    );
  }
}

/// Radio group for forms.
class FormRadioGroup extends StatefulWidget {
  final String name;
  final String? label;
  final List<FormRadioOption> options;
  final String? description;
  final bool isRequired;
  final bool isDisabled;
  final String? defaultValue;
  final Function(String?)? onChanged;
  final String? error;

  const FormRadioGroup({
    Key? key,
    required this.name,
    this.label,
    required this.options,
    this.description,
    this.isRequired = false,
    this.isDisabled = false,
    this.defaultValue,
    this.onChanged,
    this.error,
  }) : super(key: key);

  @override
  State<FormRadioGroup> createState() => _FormRadioGroupState();
}

class _FormRadioGroupState extends State<FormRadioGroup> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final formState = FormProvider.of(context);
    
    // If form has a value for this field, use it
    if (formState.getFieldValue(widget.name) != null) {
      _value = formState.getFieldValue(widget.name) as String?;
    }

    return FormField<String>(
      initialValue: _value,
      validator: (value) {
        if (widget.isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      onSaved: (value) {
        formState.setFieldValue(widget.name, value);
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null)
              FormLabel(
                text: widget.label!,
                isRequired: widget.isRequired,
              ),
            ...widget.options.map((option) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Radio<String>(
                      value: option.value,
                      groupValue: _value,
                      onChanged: widget.isDisabled
                          ? null
                          : (value) {
                              setState(() {
                                _value = value;
                              });
                              formState.setFieldValue(widget.name, value);
                              state.didChange(value);
                              if (widget.onChanged != null) {
                                widget.onChanged!(value);
                              }
                            },
                      activeColor: Colors.green[700],
                    ),
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: widget.isDisabled ? Colors.grey[500] : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (widget.description != null)
              FormDescription(text: widget.description!),
            if (state.hasError) FormError(text: state.errorText!),
          ],
        );
      },
    );
  }
}

/// Option for radio group.
class FormRadioOption {
  final String value;
  final String label;

  FormRadioOption({
    required this.value,
    required this.label,
  });
}

/// Date picker for forms.
class FormDatePicker extends StatefulWidget {
  final String name;
  final String? label;
  final String? placeholder;
  final String? description;
  final bool isRequired;
  final bool isDisabled;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime?)? onChanged;
  final String? error;
  final String? dateFormat;
  final Color? fillColor;
  final double borderRadius;

  const FormDatePicker({
    Key? key,
    required this.name,
    this.label,
    this.placeholder,
    this.description,
    this.isRequired = false,
    this.isDisabled = false,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.error,
    this.dateFormat,
    this.fillColor,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  State<FormDatePicker> createState() => _FormDatePickerState();
}

class _FormDatePickerState extends State<FormDatePicker> {
  DateTime? _selectedDate;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _updateDateDisplay();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDateDisplay() {
    if (_selectedDate != null) {
      // Basic implementation - in real app, use intl package for proper formatting
      String formattedDate = '${_selectedDate!.month.toString().padLeft(2, '0')}/'
          '${_selectedDate!.day.toString().padLeft(2, '0')}/'
          '${_selectedDate!.year}';
          
      _controller.text = formattedDate;
    } else {
      _controller.clear();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (widget.isDisabled) return;

    final DateTime now = DateTime.now();
    final DateTime firstDate = widget.firstDate ?? DateTime(now.year - 100, 1, 1);
    final DateTime lastDate = widget.lastDate ?? DateTime(now.year + 100, 12, 31);
    final DateTime initialDate = _selectedDate ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _updateDateDisplay();
      
      final formState = FormProvider.of(context);
      formState.setFieldValue(widget.name, _selectedDate);
      
      if (widget.onChanged != null) {
        widget.onChanged!(_selectedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = FormProvider.of(context);
    
    // If form has a value for this field, use it
    if (formState.getFieldValue(widget.name) != null) {
      _selectedDate = formState.getFieldValue(widget.name) as DateTime?;
      _updateDateDisplay();
    }

    return FormField<DateTime>(
      initialValue: _selectedDate,
      validator: (value) {
        if (widget.isRequired && value == null) {
          return 'This field is required';
        }
        return null;
      },
      onSaved: (value) {
        formState.setFieldValue(widget.name, value);
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null)
              FormLabel(
                text: widget.label!,
                isRequired: widget.isRequired,
              ),
            TextField(
              controller: _controller,
              readOnly: true,
              enabled: !widget.isDisabled,
              decoration: InputDecoration(
                hintText: widget.placeholder ?? 'Select date',
                suffixIcon: const Icon(Icons.calendar_today),
                filled: true,
                fillColor: widget.isDisabled ? Colors.grey[100] : (widget.fillColor ?? Colors.grey[50]),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Colors.green[700]!,
                    width: 2.0,
                  ),
                ),
                errorText: widget.error ?? (state.hasError ? state.errorText : null),
              ),
              onTap: () => _selectDate(context),
            ),
            if (widget.description != null) FormDescription(text: widget.description!),
          ],
        );
      },
    );
  }
}
// Use Flutter namespace to avoid naming conflicts with our custom Form
class Flutter {
  static Widget Form({
    Key? key,
    required Widget child,
    AutovalidateMode? autovalidateMode,
    WillPopCallback? onWillPop,
    VoidCallback? onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: flutter.Form(
        key: key,
        autovalidateMode: autovalidateMode,
        onWillPop: onWillPop,
        onChanged: onChanged,
        child: child,
      ),
    );
  }
}