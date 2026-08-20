

String amountToWords(double amount) {
  if (amount <= 0) return 'Zero Birr';

  final intPart = amount.floor();
  final cents = ((amount - intPart) * 100).round();

  final birrWords = _numberInWords(intPart);
  final birrText = '$birrWords Birr';

  if (cents <= 0) return birrText;

  final centText = '${_numberInWords(cents)} Cent${cents == 1 ? '' : 's'}';
  return '$birrText and $centText';
}

String _numberInWords(int n) {
  if (n == 0) return 'Zero';

  const units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen',
  ];
  const tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy',
    'Eighty', 'Ninety',
  ];

  String below1000(int value) {
    if (value == 0) return '';
    if (value < 20) return units[value];
    if (value < 100) {
      final t = tens[value ~/ 10];
      final rest = value % 10;
      return rest > 0 ? '$t ${units[rest]}' : t;
    }
    final h = units[value ~/ 100];
    final rest = value % 100;
    return rest > 0 ? '$h Hundred ${below1000(rest)}' : '$h Hundred';
  }

  const scales = ['', 'Thousand', 'Million'];
  final chunks = <int>[];
  var value = n;
  while (value > 0) {
    chunks.add(value % 1000);
    value ~/= 1000;
  }

  final parts = <String>[];
  for (var i = chunks.length - 1; i >= 0; i--) {
    final chunk = chunks[i];
    if (chunk == 0) continue;
    final words = below1000(chunk);
    final scale = scales[i];
    parts.add(scale.isEmpty ? words : '$words $scale');
  }

  return parts.join(' ');
}
