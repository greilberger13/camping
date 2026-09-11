import '../../models/booking.dart';

abstract interface class FeratelGateway {
  Future<FeratelSubmissionResult> submitGuestReport(Booking booking);
}

class FeratelSubmissionResult {
  const FeratelSubmissionResult({
    required this.success,
    this.reference,
    this.message,
  });

  final bool success;
  final String? reference;
  final String? message;
}

class FeratelExportGateway implements FeratelGateway {
  const FeratelExportGateway();

  @override
  Future<FeratelSubmissionResult> submitGuestReport(Booking booking) async {
    return FeratelSubmissionResult(
      success: true,
      reference: 'EXPORT-${booking.siteNumber}-${booking.guestName}',
      message: 'Gästemeldung für den Export vorbereitet.',
    );
  }
}
