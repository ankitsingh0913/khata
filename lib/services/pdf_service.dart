import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../config/app_constants.dart';

class PdfService {
  static Future<File> generateBillPdf(Bill bill, {String? shopName, String? shopPhone}) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName ?? 'Smart Shopkeeper',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (shopPhone != null)
                        pw.Text('Phone: $shopPhone'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.Text('# ${bill.billNumber}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 20),

              // Bill Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(bill.customerName ?? 'Walk-in Customer'),
                      if (bill.customerPhone != null)
                        pw.Text(bill.customerPhone!),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(dateFormat.format(bill.createdAt)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Payment:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(bill.paymentType),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                    children: [
                      _buildTableCell('#', isHeader: true),
                      _buildTableCell('Item', isHeader: true),
                      _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Price', isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Items
                  ...bill.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                      ),
                      children: [
                        _buildTableCell('${index + 1}'),
                        _buildTableCell(item.productName),
                        _buildTableCell('${item.quantity}', align: pw.TextAlign.center),
                        _buildTableCell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                        _buildTableCell(currencyFormat.format(item.total), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              // Totals
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 200,
                  child: pw.Column(
                    children: [
                      _buildTotalRow('Subtotal', currencyFormat.format(bill.subtotal)),
                      if (bill.discount > 0)
                        _buildTotalRow('Discount', '- ${currencyFormat.format(bill.discount)}'),
                      if (bill.tax > 0)
                        _buildTotalRow('Tax', currencyFormat.format(bill.tax)),
                      pw.Divider(),
                      _buildTotalRow('Total', currencyFormat.format(bill.total), isBold: true),
                      if (bill.paymentType == AppConstants.paymentCredit) ...[
                        _buildTotalRow('Paid', currencyFormat.format(bill.paidAmount)),
                        _buildTotalRow('Balance', currencyFormat.format(bill.pendingAmount),
                            isBold: true, color: PdfColors.red),
                      ],
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Status Badge
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: bill.isPaid ? PdfColors.green100 : PdfColors.red100,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    bill.status,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: bill.isPaid ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ),
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated by Smart Shopkeeper App',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill_${bill.billNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildTableCell(
      String text, {
        bool isHeader = false,
        pw.TextAlign align = pw.TextAlign.left,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(
      String label,
      String value, {
        bool isBold = false,
        PdfColor? color,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}