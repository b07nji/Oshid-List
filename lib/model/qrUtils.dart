import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'auth/authentication.dart';

class QRUtils {

  final auth = Authentication();


  QrImage generateQr(var uuid) {
    return QrImage(
      size: 200.0,
      data: uuid,
    );
  }

  Future<String> readQr() async {
    String partnerId = '';
    try {
      print("readOr() is calld");
      partnerId = await BarcodeScanner.scan();

    } catch (e) {
      if (e is PlatformException &&
          e.code == BarcodeScanner.CameraAccessDenied) {
        print("Error occuered");
        print(e.code);
        print(e.details);
      }
    }
    return partnerId;
  }
}