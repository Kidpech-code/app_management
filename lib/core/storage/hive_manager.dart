import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';
import 'hive_boxes.dart';

class HiveManager {
  HiveManager({required FlutterSecureStorage secureStorage, required AppLogger logger})
      : _secureStorage = secureStorage,
        _logger = logger;

  final FlutterSecureStorage _secureStorage;
  final AppLogger _logger;

  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<void> openCoreBoxes() async {
    await Hive.openBox<dynamic>(HiveBoxes.appPrefs);
    await _openSecureBox();
    await Hive.openBox<dynamic>(HiveBoxes.todosCache);
  }

  Future<Box<dynamic>> _openSecureBox() async {
    final key = await _readOrCreateEncryptionKey();
    return Hive.openBox<dynamic>(
      HiveBoxes.secureTokens,
      encryptionCipher: HiveAesCipher(key),
    );
  }

  Future<List<int>> _readOrCreateEncryptionKey() async {
    const storageKey = 'hive_encryption_key';
    final stored = await _secureStorage.read(key: storageKey);
    if (stored != null) {
      return base64Url.decode(stored);
    }
    final key = Hive.generateSecureKey();
    await _secureStorage.write(key: storageKey, value: base64Url.encode(key));
    _logger.info('Generated new Hive encryption key.');
    return key;
  }
}
