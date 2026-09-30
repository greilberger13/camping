import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/guest_order_link.dart';

Future<void> showGuestOrderLink(BuildContext context, int siteNumber) async {
  final link = GuestOrderLink.forSite(siteNumber);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Gastbestellung · Platz $siteNumber'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: link.url,
            size: 220,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          SelectableText(link.url),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link.url));
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bestelllink kopiert.')),
              );
            }
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Link kopieren'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Schließen'),
        ),
      ],
    ),
  );
}