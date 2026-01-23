// lib/screens/billing/bill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/bill.dart';
import '../../models/payment.dart';
import '../../providers/bill_provider.dart';
import '../../Config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../loans/payment_screen.dart';

class BillDetailScreen extends StatefulWidget {
  final String billId;

  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  Bill? _bill;
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    setState(() => _isLoading = true);

    final billProvider = context.read<BillProvider>();
    _bill = await billProvider.getBillById(widget.billId);
    if (_bill != null) {
      _payments = await billProvider.getPaymentsForBill(widget.billId);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _shareBill() async {
    if (_bill == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppTheme.errorColor),
              title: const Text('Share as PDF'),
              onTap: () async {
                Navigator.pop(context);
                final file = await PdfService.generateBillPdf(_bill!);
                await ShareService.sharePdf(file, text: 'Invoice ${_bill!.billNumber}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: AppTheme.successColor),
              title: const Text('Share via WhatsApp'),
              onTap: () async {
                Navigator.pop(context);
                await ShareService.shareViaWhatsApp(_bill!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_bill == null) return;

    try {
      final file = await PdfService.generateBillPdf(_bill!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved: ${file.path}'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => ShareService.sharePdf(file),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(child: Text('Bill not found')),
      );
    }

    final bill = _bill!;

    Color statusColor;
    switch (bill.status) {
      case AppConstants.billPaid:
        statusColor = AppTheme.successColor;
        break;
      case AppConstants.billPartial:
        statusColor = AppTheme.warningColor;
        break;
      default:
        statusColor = AppTheme.errorColor;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareBill,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Bill Number & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.billNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(bill.createdAt),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bill.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Customer Info
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            (bill.customerName ?? 'W').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.customerName ?? 'Walk-in Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (bill.customerPhone != null)
                              Text(
                                bill.customerPhone!,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (bill.paymentType == AppConstants.paymentCredit
                              ? AppTheme.warningColor
                              : AppTheme.primaryColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bill.paymentType,
                          style: TextStyle(
                            color: bill.paymentType == AppConstants.paymentCredit
                                ? AppTheme.warningColor
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bill.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = bill.items[index];
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${currencyFormat.format(item.price)} × ${item.quantity}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(item.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text(currencyFormat.format(bill.subtotal)),
                    ],
                  ),
                  if (bill.discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount'),
                        Text(
                          '- ${currencyFormat.format(bill.discount)}',
                          style: const TextStyle(color: AppTheme.successColor),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(bill.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (!bill.isPaid) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Paid'),
                        Text(currencyFormat.format(bill.paidAmount)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pending',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                          ),
                        ),
                        Text(
                          currencyFormat.format(bill.pendingAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment History
            if (_payments.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _payments.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.successColor,
                            ),
                          ),
                          title: Text(currencyFormat.format(payment.amount)),
                          subtitle: Text(
                            '${payment.paymentType} • ${DateFormat('dd MMM, hh:mm a').format(payment.createdAt)}',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Collect Payment Button
            if (!bill.isPaid)
              CustomButton(
                text: 'Collect Payment',
                icon: Icons.payments_outlined,
                backgroundColor: AppTheme.successColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(bill: bill),
                    ),
                  ).then((_) => _loadBill());
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}