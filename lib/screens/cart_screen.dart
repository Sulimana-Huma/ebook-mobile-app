import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../utils/theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _items = [];
  final Set<int> _selected = {}; // cartIds currently checked
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiClient.getCart();
      setState(() {
        _items = items;
        // Pre-select everything by default
        _selected
          ..clear()
          ..addAll(items.map((i) => i['cartId'] as int));
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _remove(int cartId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from cart?'),
        content: const Text('This book will be removed from your cart.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await ApiClient.removeFromCart(cartId);
    if (ok) {
      setState(() => _selected.remove(cartId));
      _loadCart();
    }
  }

  Future<void> _checkout() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one book')),
      );
      return;
    }

    final selectedIds = _items
        .where((i) => _selected.contains(i['cartId']))
        .map((i) => i['bookId'] as int)
        .toList();

    // Confirm dialog showing payment reminder + vendor info
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Purchase Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Have you completed the payment to the vendor account shown above?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('You selected ${_selected.length} book(s).'),
              const SizedBox(height: 8),
              const Text(
                'After you send the request, the vendor will verify your payment and approve your books. Once approved, the books will appear in My Books.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Payment Done, Send Request')),
        ],
      ),
    );
    if (proceed != true) return;

    try {
      final result = await ApiClient.createPurchaseRequest(selectedIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Request sent to vendor')),
      );
      _loadCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')),
      );
    }
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_items.map((i) => i['cartId'] as int));
    });
  }

  void _deselectAll() {
    setState(() => _selected.clear());
  }

  double get _total => _items
      .where((i) => _selected.contains(i['cartId']))
      .fold(0.0, (sum, i) => sum + (i['price'] ?? 0).toDouble());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCart),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Your cart is empty',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Add books from categories to buy them',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Select all / deselect all bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                  '${_selected.length} of ${_items.length} selected',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              TextButton(
                                  onPressed: _selectAll,
                                  child: const Text('Select All')),
                              TextButton(
                                  onPressed: _deselectAll,
                                  child: const Text('Clear')),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Books list with checkboxes + delete
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _items.length,
                            itemBuilder: (context, i) {
                              final item = _items[i];
                              final cartId = item['cartId'] as int;
                              final isSelected = _selected.contains(cartId);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true)
                                        _selected.add(cartId);
                                      else
                                        _selected.remove(cartId);
                                    });
                                  },
                                  title: Text(item['title'] ?? 'Unknown'),
                                  subtitle: Text(
                                      '\$${(item['price'] ?? 0).toStringAsFixed(2)}'),
                                  secondary: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    tooltip: 'Remove from cart',
                                    onPressed: () => _remove(cartId),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Vendor account details
                        _VendorAccountCard(items: _items, selected: _selected),

                        // Total + Request button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text('\$${_total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _selected.isEmpty ? null : _checkout,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Payment Done? Request Book then',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// ============================================
// VENDOR ACCOUNT DETAILS CARD
// ============================================
class _VendorAccountCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Set<int> selected;

  const _VendorAccountCard({required this.items, required this.selected});

  @override
  Widget build(BuildContext context) {
    // Group selected items by vendor
    final selectedItems = items.where((i) => selected.contains(i['cartId']));
    final vendors = <String>{};
    for (final item in selectedItems) {
      final vendor =
          item['vendorName'] ?? item['vendorId']?.toString() ?? 'Unknown';
      vendors.add(vendor);
    }

    if (vendors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Pay the vendor before requesting',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          if (vendors.length == 1)
            _vendorDetails(context, vendors.first)
          else
            ...vendors.map((v) => _vendorDetails(context, v)),
          const SizedBox(height: 8),
          const Text(
            'After sending the request, the vendor will verify payment and approve your books. Then they will appear in My Books.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _vendorDetails(BuildContext context, String vendorName) {
    // Look up the vendor's bank details from the first matching item.
    // If the backend returns more fields (bank, account number, jazzcash, easyPaisa),
    // display them. Otherwise show a message.
    final vendorItem = items.firstWhere(
      (i) =>
          (i['vendorName'] ?? i['vendorId']?.toString() ?? 'Unknown') ==
          vendorName,
      orElse: () => <String, dynamic>{},
    );

    final bankName = vendorItem['bankName'] as String?;
    final accountName = vendorItem['accountName'] as String?;
    final accountNo = vendorItem['accountNumber'] as String?;
    final jazzCash = vendorItem['jazzCash'] as String?;
    final easyPaisa = vendorItem['easyPaisa'] as String?;
    final contact = vendorItem['vendorContact'] as String?;
    final email = vendorItem['vendorEmail'] as String?;

    final rows = <Widget>[
      Text(vendorName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ];

    if (bankName != null) rows.add(_row('Bank', bankName));
    if (accountName != null) rows.add(_row('Account Name', accountName));
    if (accountNo != null) rows.add(_row('Account #', accountNo));
    if (jazzCash != null) rows.add(_row('JazzCash', jazzCash));
    if (easyPaisa != null) rows.add(_row('EasyPaisa', easyPaisa));
    if (contact != null) rows.add(_row('Contact', contact));
    if (email != null) rows.add(_row('Email', email));

    // If backend has none of these fields, show a hint
    if (rows.length == 1) {
      rows.add(const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'Contact the vendor directly for payment details.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            Expanded(
              child: SelectableText(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
