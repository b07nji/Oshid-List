import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OshidPoint(),
    );
  }
}

class OshidPoint extends StatefulWidget {
  @override
  _OshidPointState createState() => _OshidPointState();
}

class _OshidPointState extends State<OshidPoint> {
  @override


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OshidPoint'),
      ),
      body: ListView(
        children:PointImages,
      ),
    );
  }}


String getDonguriFile1(int index) {
  if (index == 5 || index == 9 || index == 10 || index == 11 || index == 13 || index == 14) {
    return 'images/donguri_blanck.png';
  }
  return 'images/donguri.png';
}

String getDonguriFile2(int index) {
  if (index == 5 || index == 9 || index == 10 || index == 11 || index == 13 || index == 14) {
    return 'images/donguri_blanck.png';
  }
  return 'images/donguri.png';
}

String getDonguriFile3(int index) {
  if (index == 5 || index == 9 || index == 10 || index == 11 || index == 13 || index == 14) {
    return 'images/donguri_blanck.png';
  }
  return 'images/donguri.png';
}


List<Widget> PointImages =  <Widget>[
  Text("頑張りポイント"),
  Row(children: <Widget>[
    Expanded(
        child:Text("自分")),
    Expanded(
        child:Text("パートナー")),],),
  OnegaiPointer(
//    width: 200.0,
//    height: 170.0,
//    minWidth: 100,
//    maxHeight: 100,
//    minHeight: 100,
//    maxWidth: 100,
  ),
//  Text("ありさん夫婦"),
  OnegaiPointer(
//    width: 200.0,
//    height: 170.0,
//    minWidth: 100,
//    maxHeight: 100,
//    minHeight: 100,
//    maxWidth: 100,
  ),
//  Text("くまさん夫婦"),
  OnegaiPointer(
//    width: 200.0,
//    height: 170.0,
//    minWidth: 100,
//    maxHeight: 100,
//    minHeight: 100,
//    maxWidth: 100,
  ),
//  Text("とりさん夫婦"),
];
const int onegai =8;

//Map myMap = {"Points": [
//
//  {"classname": "ありさん", "pointImage":getDonguriFile1},
//  {"class": "くまさん", "pointImage":getDonguriFile2},
//  {"class": "キリンさん", "pointImage":getDonguriFile2},
//]
//};
//
//class MyData {
//  String classname;
////  int pointCount;
//  String pointImage;
//
//  MyData.fromJson(Map json){
//    this.classname = json["classname"];
////    this.pointCount = json ["pointCount"];
//    this.pointImage = json["pointImage"];
//  }
//}

class OnegaiPointer extends StatelessWidget {
//  const OnegaiPointer({
//    this.width,
//    this.height,
//    this.padding,
//    this.minWidth,
//    this.maxHeight,
//    this.minHeight,
//    this.maxWidth,
////    this.data
//  });
//
//  final EdgeInsets padding;
//  final double width;
//  final double height;
//  final double minWidth;
//  final double maxHeight;
//  final double minHeight;
//  final double maxWidth;
//  final MyData data;


  @override
  Widget build(BuildContext context) {
    if (onegai > 0) return  Column(
      children: <Widget>[
        Container(
          width: 200.0,
          height: 170.0,
          padding: EdgeInsets.only(top: 50.0),
          child:GridView.count(
            crossAxisCount: 5,
            reverse: true,
            children: List.generate(onegai, (index) {
              return OverflowBox(
                minWidth: 100,
                maxHeight: 100,
                minHeight: 100,
                maxWidth: 100,
                child:Image.asset(getDonguriFile1(index)),
              );}),),),
        Text("ありさん"),
      ],); else return Container();}}