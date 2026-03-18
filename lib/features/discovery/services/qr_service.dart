import 'dart:convert';
import 'package:linksync/features/discovery/models/device.dart';

class QrService {
  static String generatePayload(Device me) {
    final data = {
      'id': me.id,
      'name': me.name,
      'ip': me.ip,
      'port': me.port,
      'os': me.os,
      if (me.pin != null) 'pin': me.pin,
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  static Device parsePayload(String code) {
    final decoded = utf8.decode(base64Decode(code));
    final data = jsonDecode(decoded);
    return Device.fromJson(data);
  }
}
