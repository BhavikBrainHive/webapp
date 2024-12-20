import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pointy;
import 'package:fernet/fernet.dart' as fernett;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webapp/const/pref_const.dart';

class VerifyPhraseDialog extends StatefulWidget {
  final String salt;

  const VerifyPhraseDialog({
    super.key,
    required this.salt,
  });

  @override
  State<VerifyPhraseDialog> createState() => _VerifyPhraseDialogState();
}

class _VerifyPhraseDialogState extends State<VerifyPhraseDialog> {
  final controller = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Card(
        color: const Color(0xff000000),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 25.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 15,
              ),
              TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Paste your phrase separated by space',
                  hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.6),
                  ),
                ),
              ),
              SizedBox(
                height: 25,
              ),
              if (isLoading)
                Text(
                  "Hold on!! let me verify",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              SizedBox(
                height: 7,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });
                              final wordPhrase = controller.text;
                              final encryptedUserShare =
                                  (await SharedPreferences.getInstance())
                                      .getString(PrefConst.userSharePrefKey);
                              if (wordPhrase.isNotEmpty &&
                                  encryptedUserShare != null) {
                                final result = await compute(
                                  _verifyUserShare,
                                  _DecryptParams(
                                    saltHex: widget.salt,
                                    phrase: wordPhrase,
                                    encryptedShare: encryptedUserShare,
                                  ),
                                );
                                Navigator.pop(
                                  context,
                                  result,
                                );
                              }
                              setState(() {
                                isLoading = false;
                              });
                            },
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              7,
                            ),
                          ),
                        ),
                      ),
                      child: Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.black.withOpacity(
                            0.7,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _verifyUserShare(_DecryptParams params) async {
    String saltHex = params.saltHex;
    String phrase = params.phrase;
    String encryptedShare = params.encryptedShare;
    try {
      // Convert hex salt to bytes
      Uint8List salt = hexToBytes(saltHex);
      print("Salt Bytes: $salt");

      // Derive the same key as Python
      Uint8List derivedKey = generateKey(phrase, salt);
      String keyBase64 = base64UrlEncode(derivedKey);
      print("Derived Key (Base64): $keyBase64");

      // Initialize Fernet with the derived key
      final fernet = fernett.Fernet(keyBase64);

      // Decrypt the token
      final decryptedBytes = fernet.decrypt(encryptedShare);
      // Step 5: Convert decrypted bytes to String
      final decryptedString = utf8.decode(decryptedBytes);
      print("Decrypted User Share: $decryptedString");
      return decryptedString;
    } catch (e) {
      print("Failed to decrypt user share: $e");
      return null;
    }
  }

  Uint8List hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw FormatException("Invalid hex string: length must be even.");
    }
    final validHexPattern = RegExp(r'^[0-9a-fA-F]+$');
    if (!validHexPattern.hasMatch(hex)) {
      throw FormatException("Invalid hex string: contains non-hex characters.");
    }

    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      final byteStr = hex.substring(i, i + 2);
      final byte = int.parse(byteStr, radix: 16);
      result[i ~/ 2] = byte;
    }
    return result;
  }

  Uint8List generateKey(String password, Uint8List salt) {
    final pbkdf2 =
        pointy.PBKDF2KeyDerivator(pointy.HMac(pointy.SHA256Digest(), 64))
          ..init(pointy.Pbkdf2Parameters(
              salt, 100000, 32)); // 100,000 iterations, 32-byte key

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }
}

class _DecryptParams {
  final String saltHex;
  final String phrase;
  final String encryptedShare;

  _DecryptParams({
    required this.saltHex,
    required this.phrase,
    required this.encryptedShare,
  });
}
