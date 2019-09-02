import 'dart:async';
import 'dart:convert' show json;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import "package:intl/intl.dart";
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/auth/authentication.dart';
import 'package:oshid_list_v1/model/qrUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'onegaiPage.dart';

final _onegaiReference = Firestore.instance.collection(constants.onegai);
final _userReference = Firestore.instance.collection(constants.users);
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

final auth = Authentication();
final user = User();
final qr = QRUtils();
final formatter = DateFormat('M/d E', "ja");
final constants = Constants();
var partnerName = 'パートナーがいません';

class MyHomePage extends StatefulWidget {
//  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  // 以下をStateの中に記述

  final List<Tab> tabs = <Tab> [
    Tab(
      key: Key('0'),
      text: constants.me,
        ),
    Tab(
      key: Key('1'),
      text: constants.partner,
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
        user.userName = preferences.getString(constants.userName);
        user.hasPartner = preferences.getBool(constants.hasPartner);
        user.partnerId = preferences.getString(constants.partnerId);
        if (user.hasPartner) partnerName = preferences.getString(constants.partnerName);
        print("home initState() is called: uuid " + user.uuid + ", hasPartner: " + user.hasPartner.toString() + ", partnerId: " + user.partnerId);

        //TODO:リファクタ partnerId取得のためここで初期化しているが気持ち悪い

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
      });
    });

    //タブ生成
    _tabController = TabController(length: tabs.length, vsync: this);

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
              fetchChangedUserInfo();
              Navigator.of(context).pop();
            },
          )
        ],
      )
    );
  }

  void postQrScannedNotification() async {
    var serverKey = constants.serverKey;

    final notification = {
      "to": "/topics/" + user.partnerId,
      "notification": {"title": user.userName + "さんと繋がりました！"},
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

  void fetchChangedUserInfo() {
    _userReference.document(user.uuid).snapshots().forEach((snapshots) {
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshots.data);

      auth.saveHasPartnerFlag(data[constants.hasPartner]);
      user.hasPartner = data[constants.hasPartner];
      print('tttttttttttttttttttttest' + user.hasPartner.toString());

      auth.savePartnerId(data[constants.partnerId]);
      user.partnerId = data[constants.partnerId];
      print('tttttttttttttttttttttest' + user.partnerId);

      _userReference.document(user.partnerId).snapshots().forEach((snapshots) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshots.data);
        auth.savePartnerName(data[constants.userName]);
        setState(() {
          partnerName = data[constants.userName];
        });
        print('tttttttttttttttttttttttttttest' + partnerName);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: Container(
          height: 50,
          width: 200,
          child: Image.asset(constants.flag),
        ),
//        backgroundColor: Colors.white,
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
              height: 90,
              child: DrawerHeader(
                decoration: BoxDecoration(
//                    color: Colors.white
                ),
              ),
            ),
            Container(
              child: Icon(
                const IconData(59475, fontFamily: 'MaterialIcons'),
                size: 77,
              )
            ),
            Container(
              child:Center(
                child: Text(user.userName, style: TextStyle(fontSize: 20, color: constants.violet),),
              ),
            ),
            SizedBox(width: 5.0),
            Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: user.hasPartner ? 20 : 0,
                    height: user.hasPartner ? 20 : 0,
                    child: user.hasPartner ? Image.asset(constants.oshidoriBlue) : null,
                  ),
                  SizedBox(width: user.hasPartner ? 10.0 : 0),
                  Container(
                    width: 20,
                    height: 20,
                    child: Image.asset(constants.oshidoriGreen),
                    ),
                ],
              ),

            Center(
              child: Text(partnerName),
            ),

            Center(
                child: Container(
                  padding: EdgeInsets.only(top:30.0),
                  child:Text(user.userName + 'のQRコード'),
                ),
            ),
            Center(
              child: qr.generateQr(user.uuid),
            ),
            Center(
              child: RaisedButton(
                child: Text('パートナーと繋がる'),
                onPressed: () {
                  qr.readQr().then((partnerId) {

                    if (partnerId.isEmpty || partnerId == null) {
                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            actions: <Widget>[
                              FlatButton(
                                child: Text('パートナーのQRコードを読み込んでね'),
                                onPressed: () {
                                  //push通知
                                  postQrScannedNotification();
                                  //更新した自分のパートナー情報をアプリに反映
                                  fetchChangedUserInfo();
                                  //ダイアログ閉じる
                                  Navigator.pop(context, false);
                                }
                              ),
                            ],
                          );
                        }
                      );
                      return null;
                    }
                    /**
                     * TODO: パートナー名取得
                     */
                    _userReference.document(partnerId).snapshots().forEach((snapshots) {
                      if (!snapshots.exists) {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              actions: <Widget>[
                                FlatButton(
                                  child: Text('パートナーのQRコードを読み込んでね'),
                                  onPressed: () {
                                    //push通知
                                    postQrScannedNotification();
                                    //更新した自分のパートナー情報をアプリに反映
                                    fetchChangedUserInfo();
                                    //ダイアログ閉じる
                                    Navigator.pop(context, false);
                                  }
                                ),
                              ],
                            );
                          }
                        );
                        return null;
                      }

                      Map<String, dynamic> data = Map<String, dynamic>.from(snapshots.data);
                      auth.savePartnerName(data[constants.userName]);

                      //TODO: リファクタ
                      //自分のパートナー情報更新
                      _userReference.document(user.uuid).updateData({
                        'hasPartner': true,
                        'partnerId': partnerId
                      }).whenComplete(() {
                        //相手のパートナー情報更新
                        _userReference.document(partnerId).updateData({
                          'hasPartner': true,
                          'partnerId': user.uuid
                        }).whenComplete(() {
                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(data[constants.userName] + 'さんを見つけました！'),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text('繋がる'),
                                    onPressed: () {
                                      //メニューバーのパートナー名反映
                                      setState(() {
                                        /**
                                         *  TODO: パートナーIDをローカルストレージ保存
                                         */
                                        auth.saveHasPartnerFlag(true);
                                        auth.savePartnerId(partnerId);
                                        user.hasPartner = true;
                                        user.partnerId = partnerId;
                                        partnerName = data[constants.userName];
                                      });
                                      //push通知
                                      postQrScannedNotification();
                                      //更新した自分のパートナー情報をアプリに反映
                                      fetchChangedUserInfo();
                                      //ダイアログ閉じる
                                      Navigator.pop(context, false);
                                    }
                                  ),
                                ],
                              );
                            }
                          );
                        });
                      });
                    });
                  });
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add, size: 30, color: constants.violet,),
        backgroundColor: constants.floatingButton,
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
//        indicatorColor: constants.violet,
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
      print(uuid);
    } else {
      uuid = user.partnerId;
      print(uuid);
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
          border: Border.all(color: constants.violet),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: LabeledCheckbox(
//          onTap:(value){
//            Navigator.push(
//              context,
//              MaterialPageRoute(builder: (context) => OnegaiCreator()),
//            );
//          },
          label: record.content,
          subtitle: formatter.format(record.dueDate),
          padding:EdgeInsets.all(10.0),
          value: record.status,
          onChanged: (bool newValue) {
            setState(() {
              record.status = newValue;
              Timer(Duration(milliseconds: 600), () {
                _onegaiReference.document(record.onegaiId).delete().then((value) {
                  print("deleted");
                }).catchError((error) {
                  print(error);
                });
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
    this.subtitle,
    this.value,
    this.onChanged,
    this.padding,
    this.onTap,
  });

  final String label;
  final String subtitle;
  final bool value;
  final Function onChanged;
  final EdgeInsets padding;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:padding,
      child: Row(
        children: <Widget>[
          Expanded(
//              child:InkWell(
//              onTap:(){Navigator.push(
//                context,
//                MaterialPageRoute(builder: (context) => OnegaiCreator()),
//              );},
            child:Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style:TextStyle(fontSize: 25.0)
                ),
                Row(
                  children: <Widget>[
                    Icon(const IconData(59670, fontFamily: 'MaterialIcons'),),
                    SizedBox(width: 5,),
                    Text(subtitle),
                  ],
                ),
              ]
             ),
            ),
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

  Record.fromSnapshot(dynamic snapshot): this.fromMap(
      snapshot.data,
      reference: snapshot.reference
  );

  @override
  String toString() => "Record<$content: $dueDate>";
}
