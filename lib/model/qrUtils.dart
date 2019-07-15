import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRUtils {
  var qr = QrImage(
    data: "1234567890",
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