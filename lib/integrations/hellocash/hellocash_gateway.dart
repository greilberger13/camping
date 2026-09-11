import '../../models/invoice.dart';

abstract interface class HelloCashGateway {
  Future<HelloCashSubmissionResult> submitInvoice(Invoice invoice);
}

class HelloCashSubmissionResult {
  const HelloCashSubmissionResult({
    required this.success,
    this.reference,
    this.message,
  });

  final bool success;
  final String? reference;
  final String? message;
}

class HelloCashExportGateway implements HelloCashGateway {
  const HelloCashExportGateway();

  @override
  Future<HelloCashSubmissionResult> submitInvoice(Invoice invoice) async {
    return HelloCashSubmissionResult(
      success: true,
      reference: 'KASSA-${invoice.siteNumber}-${invoice.guestName}',
      message: 'Rechnung für die Kassenübergabe vorbereitet.',
    );
  }
}
