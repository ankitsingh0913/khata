import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../config/app_constants.dart';

class ShareService {
  static Future<void> sharePdf(File file, {String? text}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
    );
  }

  static Future<void> shareViaWhatsApp(Bill bill, {File? pdfFile}) async {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 2);

    final message = '''
🧾 *Invoice: ${bill.billNumber}*
━━━━━━━━━━━━━━━━━━━━

${bill.items.map((item) => '• ${item.productName} x${item.quantity} = ${currencyFormat.format(item.total)}').join('\n')}

━━━━━━━━━━━━━━━━━━━━
*Subtotal:* ${currencyFormat.format(bill.subtotal)}
${bill.discount > 0 ? '*Discount:* -${currencyFormat.format(bill.discount)}\n' : ''}*Total:* ${currencyFormat.format(bill.total)}
${bill.isCredit ? '*Pending:* ${currencyFormat.format(bill.pendingAmount)}' : ''}

*Payment:* ${bill.paymentType}
*Status:* ${bill.status}

Thank you for your purchase! 🙏
''';

    final encodedMessage = Uri.encodeComponent(message);
    final phone = bill.customerPhone?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

    final whatsappUrl = phone.isNotEmpty
        ? 'https://wa.me/$phone?text=$encodedMessage'
        : 'https://wa.me/?text=$encodedMessage';

    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> sendSmsReminder(String phone, double amount) async {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 2);
    final message = 'Reminder: You have a pending payment of ${currencyFormat.format(amount)}. Please clear your dues at your earliest convenience. - Smart Shopkeeper';

    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}