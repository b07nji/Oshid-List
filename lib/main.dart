import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oshid_list_v1/view/home.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'entity/user.dart';
import 'package:oshid_list_v1/view/loginPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final user = User();
  Widget _defaultHome = MyHomePage();

  SharedPreferences preferences;

  //起動時に呼ばれる
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences pref) {
      preferences = pref;
      setState(() {
        user.uuid = preferences.getString('uuid');
      });

      if (user.uuid == null) {
        _defaultHome = LoginPage();
      }
      print("this is uuid: " + user.uuid);
    });
  }


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Oshid-List',
      home: _defaultHome,
      routes: <String, WidgetBuilder> {
        '/home': (BuildContext context) => MyHomePage(),
      },
      localizationsDelegates: [
       GlobalMaterialLocalizations.delegate,
       GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale("en"),
        const Locale("ja"),
      ],
    );
  }
}