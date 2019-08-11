import 'package:flutter/material.dart';

class OshidPoint extends StatefulWidget {
  @override
  _OshidPointState createState() => _OshidPointState();
}


class _OshidPointState extends State<OshidPoint> {
  @override
  final int onegai =15;
  final List<String> list=[
    "images/donguri.png",
  ];

  Widget build(BuildContext context) {
    final title = 'OshidPoint';
    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Container(
          width: 200.0,
          height: 500.0,
          padding: EdgeInsets.only(top: 50.0),
          child: GridView.count(
            crossAxisCount: 5,
            reverse: true,
            children: List.generate(onegai, (index) {
              return OverflowBox(
                minWidth: 100,
                maxHeight: 500,
                minHeight: 100,
                maxWidth: 500,
                child: Image.asset(getDonguriFile(index)),
              );
            }
            ),
          ),
        ),
      ),
    );
  }}

  String getDonguriFile(int index) {
    if (index == 5 || index == 9 || index == 10 || index == 11 || index == 13 || index == 14) {
      return 'images/donguri_blanck.png';
    }
    return 'images/donguri.png';
  }

