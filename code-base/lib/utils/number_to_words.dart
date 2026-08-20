class NumberToWords {

  static String convert(double amount) {
    if (amount == 0) return 'Zero';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen',
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy',
      'Eighty', 'Ninety',
    ];

    String convertLessThan1000(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) {
        return '${tens[n ~/ 10]}${n % 10 > 0 ? ' ${units[n % 10]}' : ''}';
      }
      return '${units[n ~/ 100]} Hundred${n % 100 > 0 ? ' ${convertLessThan1000(n % 100)}' : ''}';
    }

    String convertThousands(int n) {
      if (n == 0) return '';
      final thousands = ['', 'Thousand', 'Million', 'Billion'];
      int i = 0;
      String result = '';
      while (n > 0) {
        final chunk = n % 1000;
        if (chunk > 0) {
          result =
              '${convertLessThan1000(chunk)} ${thousands[i]} $result';
        }
        n ~/= 1000;
        i++;
      }
      return result.trim();
    }

    final intPart = amount.floor();
    final decPart = ((amount - intPart) * 100).round();

    var result = convertThousands(intPart);
    if (decPart > 0) {
      result += ' and $decPart/100';
    }
    return 'ETB $result Only';
  }
}
