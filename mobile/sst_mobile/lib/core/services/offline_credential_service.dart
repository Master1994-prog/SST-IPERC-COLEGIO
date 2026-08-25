import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ===============================================================
/// OFFLINE CREDENTIAL SERVICE - SST EDURISK
/// ===============================================================
///
/// Permite validar la contraseña del usuario cuando no existe
/// conexión con la API.
///
/// SEGURIDAD:
/// - Nunca guarda la contraseña en texto plano.
/// - Genera un salt aleatorio por dispositivo.
/// - Usa PBKDF2-HMAC-SHA256 con 100 000 iteraciones.
/// - Guarda solamente el verificador derivado en Secure Storage.
/// - Compara el resultado en tiempo constante.
///
/// Formato almacenado:
/// v1$100000$ salt-base64 $ hash-base64
/// ===============================================================
class OfflineCredentialService {
  OfflineCredentialService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _offlineVerifierKey = 'offline_password_verifier';

  static const int _iterations = 100000;
  static const int _saltLength = 16;
  static const int _derivedKeyLength = 32;

  /// Guarda un nuevo verificador de contraseña para uso offline.
  Future<void> guardarPasswordOffline(String password) async {
    if (password.length < 8) {
      throw ArgumentError('La contraseña debe tener al menos 8 caracteres.');
    }

    final Uint8List salt = _generarSalt(_saltLength);

    final Uint8List derivedKey = _pbkdf2HmacSha256(
      password: password,
      salt: salt,
      iterations: _iterations,
      derivedKeyLength: _derivedKeyLength,
    );

    final String value = <String>[
      'v1',
      _iterations.toString(),
      base64Encode(salt),
      base64Encode(derivedKey),
    ].join(r'$');

    await _storage.write(key: _offlineVerifierKey, value: value);
  }

  /// Verifica la contraseña escrita contra el verificador local.
  Future<bool> validarPasswordOffline(String password) async {
    if (password.isEmpty) {
      return false;
    }

    final String? stored = await _storage.read(key: _offlineVerifierKey);

    if (stored == null || stored.trim().isEmpty) {
      return false;
    }

    try {
      final List<String> parts = stored.split(r'$');

      if (parts.length != 4 || parts[0] != 'v1') {
        return false;
      }

      final int? iterations = int.tryParse(parts[1]);

      if (iterations == null || iterations <= 0) {
        return false;
      }

      final Uint8List salt = Uint8List.fromList(base64Decode(parts[2]));

      final Uint8List expected = Uint8List.fromList(base64Decode(parts[3]));

      if (salt.isEmpty || expected.isEmpty) {
        return false;
      }

      final Uint8List actual = _pbkdf2HmacSha256(
        password: password,
        salt: salt,
        iterations: iterations,
        derivedKeyLength: expected.length,
      );

      return _constantTimeEquals(actual, expected);
    } catch (_) {
      return false;
    }
  }

  /// Indica si existe credencial offline configurada.
  Future<bool> tienePasswordOffline() async {
    final String? value = await _storage.read(key: _offlineVerifierKey);

    return value != null && value.trim().isNotEmpty;
  }

  /// Elimina únicamente el verificador offline.
  Future<void> eliminarPasswordOffline() {
    return _storage.delete(key: _offlineVerifierKey);
  }

  Uint8List _generarSalt(int length) {
    final Random random = Random.secure();

    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// Implementación PBKDF2-HMAC-SHA256.
  Uint8List _pbkdf2HmacSha256({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int derivedKeyLength,
  }) {
    final List<int> passwordBytes = utf8.encode(password);

    final Hmac hmac = Hmac(sha256, passwordBytes);

    const int hashLength = 32;

    final int blockCount = (derivedKeyLength / hashLength).ceil();

    final BytesBuilder output = BytesBuilder(copy: false);

    for (int blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final BytesBuilder initialData = BytesBuilder(copy: false)
        ..add(salt)
        ..add(<int>[
          (blockIndex >> 24) & 0xff,
          (blockIndex >> 16) & 0xff,
          (blockIndex >> 8) & 0xff,
          blockIndex & 0xff,
        ]);

      List<int> u = hmac.convert(initialData.takeBytes()).bytes;

      final List<int> t = List<int>.from(u);

      for (int iteration = 1; iteration < iterations; iteration++) {
        u = hmac.convert(u).bytes;

        for (int i = 0; i < t.length; i++) {
          t[i] ^= u[i];
        }
      }

      output.add(t);
    }

    final Uint8List result = output.takeBytes();

    return Uint8List.fromList(result.sublist(0, derivedKeyLength));
  }

  bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) {
      return false;
    }

    int difference = 0;

    for (int i = 0; i < first.length; i++) {
      difference |= first[i] ^ second[i];
    }

    return difference == 0;
  }
}
