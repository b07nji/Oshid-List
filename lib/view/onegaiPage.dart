import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:oshid_list_v1/entity/onegai.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:intl/intl.dart";
import 'dart:convert' show json;
import 'package:http/http.dart' as http;

import '../constants.dart';

final _onegaiReference = Firestore.instance.collection(constants.onegai);
final _userReference = Firestore.instance.collection(constants.users);
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
final user = User();
final store = Store();
final constants = Constants();
var userName = 'user';
var partnerName = 'パートナー';

class OnegaiCreator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: constants.darkGold),
        title: Text(
          'おねがいする',
          style: TextStyle(color: constants.darkGold),
        ),
//        backgroundColor: Colors.white,
      ),
      body: Center(
        child: OnegaiForm(),
      ),
    );
  }
}

class OnegaiForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => OnegaiFormState();
}

class OnegaiFormState extends State<OnegaiForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _onegai = OnegaiRequest();
  // 日付の表示変換
  final formatter = DateFormat('M/d E', "ja");
  var _radVal = Status.Mine;

  SharedPreferences preferences;

  ///起動時に呼ばれる
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences pref) {
      preferences = pref;
      setState(() {
        initUserInfo();
        initFCM();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380.0,
      child: Form(
        key: this._formKey,
        child: ListView(
          padding: EdgeInsets.all(30),
          children: <Widget>[
            SizedBox(height: 20),
            TextFormField(
                cursorColor: Colors.deepPurpleAccent,
                validator: (value) {
                  if (value.isEmpty) return "おねがいを入れてね";
                  return null;
                },
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'おねがい',
                  labelStyle: TextStyle(color: constants.ivyGrey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
                  ),
                ),
                onSaved: (value) => (setState(() => _onegai.content = value))),
            SizedBox(height: 10),
            Text(
              '誰に?',
              style: TextStyle(color: constants.ivyGrey),
            ),
            Center(
              child: Column(
                children: <Widget>[
                  RadioListTile(
                      title: Text(
                        partnerName,
                        style:
                            TextStyle(color: constants.ivyGrey, fontSize: 20.0),
                      ),
                      value: Status.Yours,
                      groupValue: _radVal,
//                    activeColor: constants.violet,
                      onChanged: _onChanged),
                  RadioListTile(
                      title: Text(
                        'ふたりで',
                        style:
                            TextStyle(color: constants.ivyGrey, fontSize: 20.0),
                      ),
                      value: Status.Together,
                      groupValue: _radVal,
//                    activeColor: constants.violet,
                      onChanged: _onChanged),
                  RadioListTile(
                      title: Text(
                        user.userName,
                        style:
                            TextStyle(color: constants.ivyGrey, fontSize: 20.0),
                      ),
                      value: Status.Mine,
                      groupValue: _radVal,
//                    activeColor: constants.violet,
                      onChanged: _onChanged),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'いつまでに?',
              style: TextStyle(color: constants.ivyGrey),
            ),
            SizedBox(
              width: 150,
              child: RaisedButton.icon(
                color: Colors.white,
                onPressed: _selectDate,
                icon: Icon(Icons.date_range),
                label: Text(
                  formatter.format(_onegai.dueDate),
                  style: Theme.of(context).textTheme.display1,
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            SizedBox(
              width: 150,
              child: RaisedButton(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'おねがいする',
                  style: TextStyle(color: Colors.white),
                ),
                color: constants.violet,
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Container(
                        height: 65,
                        child: Text(
                          '送信しています',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ));
                    _formKey.currentState.save();

                    // 自分
                    if (_radVal == Status.Mine) {
                      _onegaiReference.add({
                        'content': _onegai.content,
                        'dueDate': _onegai.dueDate,
                        'status': false,
                        'owerRef': _userReference.document(user.uuid)
                      }).then((docRef) {
                        _onegaiReference
                            .document(docRef.documentID)
                            .updateData({'onegaiId': docRef.documentID});
                        Navigator.of(context).pop('/home');
                      });

                      // パートナー
                    } else if (_radVal == Status.Yours) {
                      _onegaiReference.add({
                        'content': _onegai.content,
                        'dueDate': _onegai.dueDate,
                        'status': false,
                        'owerRef': _userReference.document(user.partnerId)
                      }).then((docRef) {
                        _onegaiReference
                            .document(docRef.documentID)
                            .updateData({'onegaiId': docRef.documentID});
                        postAddOnegaiNotification(_onegai.content);
                        Navigator.of(context).pop('/home');
                      });
                      // ふたりで
                    } else {
                      [user.uuid, user.partnerId].forEach((uuid) {
                        _onegaiReference.add({
                          'content': _onegai.content,
                          'dueDate': _onegai.dueDate,
                          'status': false,
                          'owerRef': _userReference.document(uuid)
                        }).then((docRef) {
                          _onegaiReference
                              .document(docRef.documentID)
                              .updateData({'onegaiId': docRef.documentID});
                        });
                      });

                      postAddOnegaiNotification(_onegai.content);
                      Timer(Duration(milliseconds: 1000), () {
                        Navigator.of(context).pop('/home');
                      });
                    }
                  }
                },
              ),
            ),
            SizedBox(
              height: 200,
            ),
          ],
        ),
      ),
    );
  }

  void initUserInfo() {
    user.hasPartner = preferences.getBool(constants.hasPartner);
    if (user.hasPartner) {
      _radVal = Status.Yours;
      store.getPartnerName().then((value) {
        partnerName = value;
      });
    }
    user.uuid = preferences.getString(constants.uuid);
    user.userName = preferences.getString(constants.userName);
    userName = user.userName;
    user.partnerId = preferences.getString(constants.partnerId);
  }

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
        locale: Locale("ja"),
        context: context,
        initialDate: new DateTime.now(),
        firstDate: DateTime(1994),
        lastDate: DateTime(2025));
    if (picked != null) {
      setState(() => _onegai.dueDate = picked);
    }
  }

  void _buildNoPartnerDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: ListTile(
                title: Text('パートナーと繋がってね'),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ));
  }

  void _buildPushDialog(BuildContext context, Map<String, dynamic> message) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
              content: ListTile(
                title: Text(message['notification']['title']),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            ));
  }

  void initFCM() {
    //FCM設定
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        _buildPushDialog(context, message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        _buildPushDialog(context, message);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        _buildPushDialog(context, message);
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      print("Push Messaging token: $token");
    });
    _firebaseMessaging.subscribeToTopic("/topics/" + user.uuid);
  }

  void postAddOnegaiNotification(String onegai) async {
    var serverKey = constants.serverKey;
    final notification = {
      "to": "/topics/" + user.partnerId,
      "notification": {"title": "$userNameが$onegaiをお願いしました"},
      "priority": 10,
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization': 'key=$serverKey'
    };

    final response = await http.post(
      constants.url,
      body: json.encode(notification),
      headers: headers,
    );

    if (response.statusCode == 200) {
      print("pushed notification successfully");
    } else {
      print("failed push notification");
    }
  }

  void _onChanged(value) {
    setState(() {
      switch (_radVal) {
        case Status.Mine:
          if (user.hasPartner) {
            _radVal = value;
            user.uuid = preferences.getString(constants.uuid);
          } else {
            _buildNoPartnerDialog(context);
          }

          break;
        case Status.Yours:
          //パートナーが自分と繋がっているか
          _userReference.document(user.uuid).snapshots().forEach((snapshots) {
            Map<String, dynamic> data =
                Map<String, dynamic>.from(snapshots.data);
            if (data[constants.hasPartner] == false ||
                data[constants.partnerId] == "no partner") {
              _buildNoPartnerDialog(context);
            }
          });

          //自分がパートナーと繋がっているか
          if (user.hasPartner) {
            _radVal = value;
            user.partnerId = preferences.getString(constants.partnerId);
          } else {
            _buildNoPartnerDialog(context);
          }
          break;
        case Status.Together:
          //パートナーが自分と繋がっているか
          _userReference.document(user.uuid).snapshots().forEach((snapshots) {
            Map<String, dynamic> data =
                Map<String, dynamic>.from(snapshots.data);
            if (data[constants.hasPartner] == false ||
                data[constants.partnerId] == "no partner") {
              _buildNoPartnerDialog(context);
            }
          });

          //自分がパートナーと繋がっているか
          if (user.hasPartner) {
            _radVal = value;
            user.uuid = preferences.getString(constants.uuid);
            user.partnerId = preferences.getString(constants.partnerId);
          } else {
            _buildNoPartnerDialog(context);
          }
          break;
      }
    });
  }
}
