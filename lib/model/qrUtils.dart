import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'auth/authentication.dart';

class QRUtils {

  final auth = Authentication();
//  var uuid = auth.getUuid().toString();

  var qr = QrImage(
    data: "test",
    size: 200.0,
  );

  void readQr() async {
    print("inside of readQr()");
    try {
      print("readOr() is calld");
      String id = await BarcodeScanner.scan();
      print(id);
    } catch (e) {
      if (e is PlatformException &&
          e.code == BarcodeScanner.CameraAccessDenied) {
        print("Error occuered");
        print(e.code);
        print(e.details);

      }
    }
  }
}