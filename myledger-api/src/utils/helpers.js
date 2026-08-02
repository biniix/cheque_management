const { v4: uuidv4 } = require('uuid');

function generateRef(prefix = 'RCT') {
  const timestamp = Date.now().toString(36).toUpperCase();
  return `${prefix}-${timestamp}`;
}

function generateChequeNumber(startNum, offset) {
  const num = parseInt(startNum) + offset;
  return num.toString().padStart(startNum.length, '0');
}

module.exports = { generateRef, generateChequeNumber };
