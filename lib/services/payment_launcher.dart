import 'package:url_launcher/url_launcher.dart';

class PaymentLauncher {
  PaymentLauncher._();

  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    var launched = await launchUrl(
      uri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (!launched) {
      launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
    if (!launched) {
      launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    }
    if (!launched) {
      throw Exception('Khong mo duoc ung dung thanh toan');
    }
  }
}
