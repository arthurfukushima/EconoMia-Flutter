/// Which of the two scanning moments the user is in.
///
/// These are distinct intents — filing a receipt is bookkeeping, checking a
/// barcode is an in-the-moment price check — so the chooser asks first and the
/// camera configures itself for one symbology.
///
/// It only steers the camera, never the outcome: routing after a successful
/// decode is decided by what was actually read, so a mis-tap still lands on the
/// right screen.
enum ScanMode {
  /// The QR on an NFC-e cupom fiscal.
  nota,

  /// A product barcode (EAN-8/13).
  produto,
}
