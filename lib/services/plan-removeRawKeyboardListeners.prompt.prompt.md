# Plan: Remove RawKeyboardListener Wrappers

## Root cause
Every `RawKeyboardListener(focusNode: FocusNode(), ...)` creates a **new, undisposed `FocusNode` on every rebuild**. Flutter's `InheritedElement.deactivate()` fires the `_dependents.isEmpty` assertion when those orphaned nodes still hold widget dependencies as the tree updates.

## Fix: Remove all 7 `RawKeyboardListener` wrappers

They're dead code — the inner fields have their own `focusNode` and `onFieldSubmitted`. Make these 7 replacements in `lib/screens/orders/new_order_screen.dart`:

---

### 1. Customer Name (opening)
**Find:**
```dart
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) => _handleKeyNavigation(event, _customerNameFocus),
                  child: TextFormField(
                    controller: _customerNameController,
```
**Replace with:**
```dart
                child: TextFormField(
                    controller: _customerNameController,
```
**Find the closing `),` after** `onFieldSubmitted: (_) => _focusNextField(_customerNameFocus),`:
```dart
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Phone Number field
```
**Replace with:**
```dart
                  ),
              ),
              const SizedBox(width: 8),
              // Phone Number field
```

---

### 2. Customer Phone (same pattern)
**Find:**
```dart
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) => _handleKeyNavigation(event, _customerPhoneFocus),
                  child: TextFormField(
                    controller: _customerPhoneController,
```
**Replace with:**
```dart
                child: TextFormField(
                    controller: _customerPhoneController,
```
**Find the closing `),` after** `onFieldSubmitted: (_) => _focusNextField(_customerPhoneFocus),`:
```dart
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Address field
```
**Replace with:**
```dart
                  ),
              ),
              const SizedBox(width: 8),
              // Address field
```

---

### 3. Customer Address (same pattern)
**Find:**
```dart
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) => _handleKeyNavigation(event, _customerAddressFocus),
                  child: TextFormField(
                    controller: _customerAddressController,
```
**Replace with:**
```dart
                child: TextFormField(
                    controller: _customerAddressController,
```
Remove the extra `),` after `onFieldSubmitted: (_) => _focusNextField(_customerAddressFocus),`

---

### 4. Item dropdown
**Find:**
```dart
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (event) => _handleKeyNavigation(event, orderItem.itemDropdownFocus),
                            child: DropdownButtonFormField<Map<String, dynamic>>(
```
**Replace with:**
```dart
                          child: DropdownButtonFormField<Map<String, dynamic>>(
```
Closing — find after `style: const TextStyle(fontSize: 11 ...`:
```dart
                          ),   // closes DropdownButtonFormField
                          ),   // closes RawKeyboardListener  ← DELETE THIS LINE
                        ),     // closes Expanded
```

---

### 5. Item Name field
**Find:**
```dart
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (event) => _handleKeyNavigation(event, orderItem.itemNameFocus),
                            child: TextFormField(
                              controller: orderItem.itemNameController,
```
**Replace with:**
```dart
                          child: TextFormField(
                              controller: orderItem.itemNameController,
```
Remove the extra `),` after `onFieldSubmitted: (_) => _focusNextField(orderItem.itemNameFocus),`

---

### 6. Quantity field
**Find:**
```dart
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _handleKeyNavigation(event, orderItem.quantityFocus),
                          child: TextFormField(
                            controller: orderItem.quantityController,
```
**Replace with:**
```dart
                        child: TextFormField(
                            controller: orderItem.quantityController,
```
Remove extra `),` after `onFieldSubmitted: (_) => _focusNextField(orderItem.quantityFocus),`

---

### 7. Price field
**Find:**
```dart
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _handleKeyNavigation(event, orderItem.priceFocus),
                          child: TextFormField(
                            controller: orderItem.unitPriceController,
```
**Replace with:**
```dart
                        child: TextFormField(
                            controller: orderItem.unitPriceController,
```
Remove extra `),` after `onFieldSubmitted: (_) => _showAddItemDialog(),`
