import 'dart:math';

/// Generates a random 10-character password that always contains at least one
/// letter and one number (matching the app's password policy). Uses
/// [Random.secure] so admin-generated passwords are not guessable.
String generatePassword({Random? random}) {
  const letters = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ';
  const digits = '23456789';
  const all = '$letters$digits';
  final rng = random ?? Random.secure();

  final chars = <String>[
    letters[rng.nextInt(letters.length)], // guaranteed letter
    digits[rng.nextInt(digits.length)], // guaranteed number
    ...List.generate(8, (_) => all[rng.nextInt(all.length)]),
  ]..shuffle(rng);

  return chars.join();
}
