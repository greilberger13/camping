enum PaymentMethod {
  cash,
  card,
  bankTransfer,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Barzahlung';
      case PaymentMethod.card:
        return 'Kartenzahlung';
      case PaymentMethod.bankTransfer:
        return 'Überweisung';
    }
  }
}
