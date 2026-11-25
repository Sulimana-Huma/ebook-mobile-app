import 'dart:convert';
import 'dart:typed_data';

class OfflineBook {
  final String protectedKey;
  final String protectedIv;
  final Uint8List ciphertext;

  OfflineBook(this.protectedKey, this.protectedIv, this.ciphertext);

  static OfflineBook parse(Uint8List bytes) {
    if (bytes.length < 8) throw FormatException('bad .mybook header');
    final magic = String.fromCharCodes(bytes.sublist(0, 4));
    if (magic != 'MBK1') throw FormatException('wrong magic: $magic');

    final keyLen = (bytes[4] << 8) | bytes[5];
    final ivLen = (bytes[6] << 8) | bytes[7];

    final keyStart = 8;
    final ivStart = keyStart + keyLen;
    final ctStart = ivStart + ivLen;
    if (bytes.length <= ctStart) throw FormatException('truncated .mybook');

    final key = utf8.decode(bytes.sublist(keyStart, ivStart));
    final iv = utf8.decode(bytes.sublist(ivStart, ctStart));
    final ct = bytes.sublist(ctStart);
    return OfflineBook(key, iv, Uint8List.fromList(ct));
  }
}











































/*import 'dart:convert';
import 'dart:typed_data';

/// Layout:
///  [4]  "MBK1"
///  [2]  keyLen (big-endian)
///  [2]  ivLen  (big-endian)
///  [keyLen]  protected key (base64 string)
///  [ivLen]   protected iv  (base64 string)
///  [rest]    AES-256-CBC ciphertext
class OfflineBook {
  final String protectedKey;
  final String protectedIv;
  final Uint8List ciphertext;

  OfflineBook(this.protectedKey, this.protectedIv, this.ciphertext);

  static OfflineBook parse(Uint8List bytes) {
    if (bytes.length < 8) throw FormatException('bad .mybook header');
    final magic = String.fromCharCodes(bytes.sublist(0, 4));
    if (magic != 'MBK1') throw FormatException('wrong magic: $magic');

    final keyLen = (bytes[4] << 8) | bytes[5];
    final ivLen = (bytes[6] << 8) | bytes[7];

    final keyStart = 8;
    final ivStart = keyStart + keyLen;
    final ctStart = ivStart + ivLen;
    if (bytes.length <= ctStart) throw FormatException('truncated .mybook');

    final key = utf8.decode(bytes.sublist(keyStart, ivStart));
    final iv = utf8.decode(bytes.sublist(ivStart, ctStart));
    final ct = bytes.sublist(ctStart);
    return OfflineBook(key, iv, Uint8List.fromList(ct));
  }
}
*/