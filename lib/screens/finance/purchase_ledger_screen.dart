// This screen has been merged into `ledger_screen.dart`.
// The purchase ledger UI is now served from `LedgerScreen`.
// Keep this file as a lightweight stub to avoid breaking imports elsewhere.

import 'package:flutter/material.dart';

class PurchaseLedgerScreenDeprecated extends StatelessWidget {
  const PurchaseLedgerScreenDeprecated({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Deprecated: Use Ledger (VAT Filing -> Ledger) instead.'),
      ),
    );
  }
}
