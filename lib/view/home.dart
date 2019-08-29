import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/auth/authentication.dart';
import 'package:oshid_list_v1/model/qrUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;

import '../constants.dart';
import 'onegaiPage.dart';

import "package:intl/intl.dart";

final _onegaiReference = Firestore.instance.collection(constants.onegai);
final _userReference = Firestore.instance.collection(constants.users);
final auth = Authentication();
final user = User();
final qr = QRUtils();
final formatter = DateFormat('E: M/d', "ja");
final constants = Constants();

var test = 'hello';

class MyHomePage extends StatefulWidget {
//  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  // 以下をStateの中に記述
  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  final List<Tab> tabs = <Tab> [
    Tab(
      key: Key('0'),
      text: '自分',
        ),
    Tab(
      key: Key('1'),
      text: 'パートナー',
    )
  ];
  TabController _tabController;
  SharedPreferences preferences;

  ///起動時に呼ばれる
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences pref) {
      preferences = pref;
      setState(() {
        user.uuid = preferences.getString(constants.uuid);
        user.hasPartner = preferences.getBool(constants.hasPartner);
        user.partnerId = preferences.getString(constants.partnerId);
        print("home initState() is called: uuid " + user.uuid + ", hasPartner: " + user.hasPartner.toString() + ", partnerId: " + user.partnerId);

        //TODO:リファクタ partnerId取得のためここで初期化しているが気持ち悪い
        if (user.hasPartner) {
          //FCM設定
          _firebaseMessaging.configure(
            onMessage: (Map<String, dynamic> message) async {
              print("onMessage: $message");
              _buildDialog(context, "onMessage");
            },
            onLaunch: (Map<String, dynamic> message) async {
              print("onLaunch: $message");
              _buildDialog(context, "onLaunch");
            },
            onResume: (Map<String, dynamic> message) async {
              print("onResume: $message");
              _buildDialog(context, "onResume");
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
      });
    });

    //タブ生成
    _tabController = TabController(length: tabs.length, vsync: this);

  }
  void _buildDialog(BuildContext context, String message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            content: new Text("Message: $message"),
            actions: <Widget>[
              new FlatButton(
                child: const Text('パートナーと繋がりました'),
                onPressed: () {
                  _userReference.document(user.uuid).updateData({
                    'hasPartner': user.hasPartner,
                    'partnerId': user.partnerId
                  });
                },
              ),
            ],
          );
        }
    );
  }

  postQrScannedNotification() async {

    test = 'postQr is called';

    var serverKey = constants.serverKey;
    final postUrl = 'https://fcm.googleapis.com/fcm/send';

    final notification = {
      "to": "/topics/" + user.partnerId,
      "notification": {"title": "テストです", "body": "Titileです"},
      "priority": 10,
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization':
      'key=$serverKey'
    };

    final response = await http.post(
      postUrl,
      body: json.encode(notification),
      headers: headers,
    );

    if (response.statusCode == 200) {
      print("pushed notification successfully");
      test = "pushed notification successfully";
    } else {
      print("failed push notification");
      test = "failed push notification";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Oshid-List'),
        backgroundColor: constants.violet,
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.map((tab) {
          return _createTab(tab, context);
        }).toList()
      ),
      endDrawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  height: 100,
                  child: DrawerHeader(
                    child: Row(
                      children: <Widget>[
                        Container(
                          alignment: Alignment.topLeft,
                          width: 220,
                          child: Text('メニュー', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                        color: constants.violet
                    ),
                  ),
                ),

                Container(
                  child: RaisedButton(
                    child: Text('パートナーと繋がる'),
                    onPressed: () {
                      qr.readQr().then((partnerId) {
                        /**
                         *  TODO: パートナーIDをローカルストレージ保存
                         */
                        auth.saveHasPartnerFlag(true);
                        auth.savePartnerInfo(partnerId);
                        user.hasPartner = true;
                        user.partnerId = partnerId;

                        _userReference.document(user.uuid).updateData({
                              'hasPartner': user.hasPartner,
                              'partnerId': user.partnerId
                            }).whenComplete(() {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return new AlertDialog(
                                      content: new Text("test"),
                                      actions: <Widget>[
                                        new FlatButton(
                                          child: const Text('繋がる'),
                                          onPressed: () {
                                            //TODO!!!!!!!!!!
                                            postQrScannedNotification();
                                          }
                                        ),
                                      ],
                                    );
                                  }
                              );
                        });

                      });
                    },
                  ),
                ),

                Container(
                  child: qr.generateQr(user.uuid),
                ),

                Container(
                  child: Text(test)
                )
              ],
            ),

          ),


      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add, size: 30),
        backgroundColor: constants.violet,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OnegaiCreator()),
          );
        },
      ),

      //タブ生成
      bottomNavigationBar: TabBar(
        tabs: tabs,
        controller: _tabController,
        unselectedLabelColor: Colors.grey,
        indicatorColor: constants.violet,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 2,
        indicatorPadding: EdgeInsets.symmetric(
          horizontal: 18.0,
          vertical: 8
        ),
        labelColor: Colors.black,
      ),

    );
  }

  Widget _createTab(Tab tab, BuildContext context) {

    var uuid;

    if (tab.key == Key('0')) {
      uuid = user.uuid;
    } else {
      uuid = user.partnerId;

    }
    return StreamBuilder<QuerySnapshot> (
      stream: _onegaiReference.where('owerRef', isEqualTo: _userReference.document(uuid)).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return _buildList(context, sortByDate(snapshot.data.documents));
      },
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> sortedList) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: sortedList.map((data) => _buildListItem(context,data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, dynamic data) {
    final record = Record.fromMap(data);
    return Padding(
      key: ValueKey(record.content),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: LabeledCheckbox(
          label: record.content,
          subtitle:formatter.format(record.dueDate),
          padding:EdgeInsets.all(10.0),
          value: record.status,
          onChanged: (bool newValue) {
            setState(() {
              /**
               * TODO: 削除周り精査
               * 今はとりあえずFirestoreのドキュメントを物理削除している
               */
//              _onegaiReference.document(record.reference.documentID).updateData({'status': e});
              _onegaiReference.document(record.onegaiId).delete().then((value) {
                print("deleted");
              }).catchError((error) {
                print(error);
              });

            });
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> sortByDate(List<DocumentSnapshot> list) {
    List<Map<String, dynamic>>  sortedList = [];

    list.forEach((snapshot) {
      sortedList.add(snapshot.data);
    });

    sortedList.sort((a, b) {
      DateTime dueDateA = a['dueDate'].toDate();
      DateTime dueDateB = b['dueDate'].toDate();
      return dueDateA.compareTo(dueDateB);
    });

    return sortedList;
  }
}

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    this.label,
    this.value,
    this.onChanged,
    this.subtitle,
    this.padding,
  });

  final String label;
  final bool value;
  final Function onChanged;
  final String subtitle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding:padding,
        child: Row(
          children: <Widget>[
            Expanded(
              child:Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
              Text(label,
              style:TextStyle(fontSize: 25.0)),
              Text(subtitle),]
             ),),
              Checkbox(
              value: value,
              activeColor: constants.violet,
              onChanged: (bool newValue) {
                onChanged(newValue);
              },
            ),
          ],
        ),
    );
  }
}

class Record {
  final String onegaiId;
  final String content;
  final DateTime dueDate;
  bool status = true;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference}) :
      assert(map['onegaiId'] != null),
      assert(map['content'] != null),
      assert((map['dueDate']) != null),
      assert((map['status']) != null),
      onegaiId = map['onegaiId'],
      content = map['content'],
      dueDate = DateTime.fromMillisecondsSinceEpoch(map['dueDate'].millisecondsSinceEpoch),
      status = map['status'];

//  Record.fromSnapshot(dynamic snapshot): this.fromMap(
//      snapshot.data,
//      reference: snapshot.reference
//  );

  @override
  String toString() => "Record<$content: $dueDate>";
}
