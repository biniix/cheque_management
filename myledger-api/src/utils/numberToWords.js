function numberToWords(num) {
  const ones = ['','One','Two','Three','Four','Five','Six','Seven','Eight','Nine'];
  const teens = ['Ten','Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eighteen','Nineteen'];
  const tens = ['','','Twenty','Thirty','Forty','Fifty','Sixty','Seventy','Eighty','Ninety'];
  const thousands = ['','Thousand','Million','Billion'];

  function convertLessThanThousand(n) {
    if (n === 0) return '';
    if (n < 10) return ones[n];
    if (n < 20) return teens[n - 10];
    if (n < 100) return tens[Math.floor(n / 10)] + (n % 10 !== 0 ? ' ' + ones[n % 10] : '');
    return ones[Math.floor(n / 100)] + ' Hundred' + (n % 100 !== 0 ? ' and ' + convertLessThanThousand(n % 100) : '');
  }

  if (num === 0) return 'Zero';

  const parts = num.toString().split('.');
  const whole = parseInt(parts[0]);
  const decimal = parts[1] ? parts[1].padEnd(2, '0').substring(0, 2) : '00';

  let result = '';
  let n = whole;
  let group = 0;

  while (n > 0) {
    const chunk = n % 1000;
    if (chunk !== 0) {
      const chunkWords = convertLessThanThousand(chunk);
      result = chunkWords + (thousands[group] ? ' ' + thousands[group] : '') + (result ? ' ' + result : '');
    }
    n = Math.floor(n / 1000);
    group++;
  }

  return result.trim() + ' Birr and ' + decimal + '/100 Cents Only';
}

module.exports = { numberToWords };
