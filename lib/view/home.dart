import 'dart:async';
import 'dart:convert' show json;
import 'package:http/http.dart' as http;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oshid_list_v1/config/ads.dart';
import 'package:oshid_list_v1/entity/onegai.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/store.dart';
import 'package:oshid_list_v1/model/qrUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'onegaiPage.dart';
import "package:intl/intl.dart";

final _onegaiReference = Firestore.instance.collection(constants.onegai);
final _userReference = Firestore.instance.collection(constants.users);
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

final store = Store();
final user = User();
final qr = QRUtils();
final formatter = DateFormat('M/d E', "ja");
final constants = Constants();
var userName = 'user';
var partnerName = 'パートナーがいません';
var hasPartner = false;

class MyHomePage extends StatefulWidget {
//  MyHomePage({Key key, this.title}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final List<Tab> tabs = <Tab>[
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

  ///起動時に呼ばれる
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences pref) {
      setState(() {
        initUserInfo(pref);
        initFCM();
        FirebaseAdMob.instance.initialize(appId: constants.appId);
        myBanner
          // typically this happens well before the ad is shown
          ..load()
          ..show(
            // Positions the banner ad 60 pixels from the bottom of the screen
            anchorOffset: 0.0,
            // Positions the banner ad 10 pixels from the center of the screen to the right
            horizontalCenterOffset: 0.0,
            // Banner Position
            anchorType: AnchorType.bottom,
          );
      });
    });
    //タブ生成
    _tabController = TabController(length: tabs.length, vsync: this);
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
          }).toList()),
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
            )),
            Container(
              child: Center(
                child: userName != null
                    ? Text(
                        userName,
                        style: TextStyle(fontSize: 20, color: constants.violet),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 5.0),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: hasPartner ? 20 : 0,
                  height: hasPartner ? 20 : 0,
                  child:
                      hasPartner ? Image.asset(constants.oshidoriBlue) : null,
                ),
                SizedBox(width: hasPartner ? 10.0 : 0),
                Container(
                  width: 20,
                  height: 20,
                  child: Image.asset(constants.oshidoriGreen),
                ),
              ],
            ),
            Center(
              child: Text(
                partnerName,
                style: TextStyle(color: constants.ivyGrey),
              ),
            ),
            Center(
              child: Container(
                padding: EdgeInsets.only(top: 30.0),
                child: userName != null
                    ? Text(
                        '$userNameのQRコード',
                        style: TextStyle(color: constants.ivyGrey),
                      )
                    : null,
              ),
            ),
            Center(
              child: qr.generateQr(user.uuid),
            ),
            Center(
              child: RaisedButton(
                color: constants.violet,
                child: Text(
                  'パートナーと繋がる',
                  style: TextStyle(color: Colors.white),
                ),
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
                                    }),
                              ],
                            );
                          });
                      return null;
                    }
                    /**
                     * TODO: パートナー名取得
                     */
                    _userReference
                        .document(partnerId)
                        .snapshots()
                        .forEach((snapshots) {
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
                                      }),
                                ],
                              );
                            });
                      }

                      Map<String, dynamic> data =
                          Map<String, dynamic>.from(snapshots.data);
                      store.savePartnerName(data[constants.userName]);

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
                                  title: Text(
                                      data[constants.userName] + 'さんを見つけました！'),
                                  actions: <Widget>[
                                    FlatButton(
                                        child: Text('繋がる'),
                                        onPressed: () {
                                          //メニューバーのパートナー名反映
                                          setState(() {
                                            /**
                                         *  TODO: パートナーIDをローカルストレージ保存
                                         */
                                            store.saveHasPartnerFlag(true);
                                            store.savePartnerId(partnerId);
                                            user.hasPartner = true;
                                            user.partnerId = partnerId;
                                            hasPartner = true;
                                            partnerName =
                                                data[constants.userName];
                                          });
                                          //push通知
                                          postQrScannedNotification();
                                          //更新した自分のパートナー情報をアプリに反映
                                          fetchChangedUserInfo();
                                          //ダイアログ閉じる
                                          Navigator.pop(context, false);
                                        }),
                                  ],
                                );
                              });
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
          size: 30,
          color: constants.violet,
        ),
        elevation: 2.0,
        backgroundColor: constants.floatingButton,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OnegaiCreator()),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: 42.0),
        child: TabBar(
          tabs: tabs,
          labelStyle: TextStyle(color: constants.ivyGrey),
          controller: _tabController,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 2,
          indicatorPadding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
          labelColor: Colors.black,
        ),
      ),
    );
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
            ));
  }

  void initUserInfo(SharedPreferences pref) {
    user.uuid = pref.getString(constants.uuid);
    user.userName = pref.getString(constants.userName);
    user.hasPartner = pref.getBool(constants.hasPartner);
    user.partnerId = pref.getString(constants.partnerId);

    userName = user.userName;
    hasPartner = user.hasPartner;
    if (user.hasPartner) partnerName = pref.getString(constants.partnerName);
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

  void sendCompleteNotification(String onegai) async {
    var serverKey = constants.serverKey;
    final notification = {
      "to": "/topics/" + user.partnerId,
      "notification": {"title": "$userNameが$onegaiを完了しました！"},
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

  void postQrScannedNotification() async {
    var serverKey = constants.serverKey;
    final notification = {
      "to": "/topics/" + user.partnerId,
      "notification": {"title": "$userNameさんと繋がりました！"},
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

      store.saveHasPartnerFlag(data[constants.hasPartner]);
      user.hasPartner = data[constants.hasPartner];

      store.savePartnerId(data[constants.partnerId]);
      user.partnerId = data[constants.partnerId];

      _userReference.document(user.partnerId).snapshots().forEach((snapshots) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshots.data);
        store.savePartnerName(data[constants.userName]);
        setState(() {
          hasPartner = true;
          partnerName = data[constants.userName];
        });
      });
    });
  }

  Widget _createTab(Tab tab, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _onegaiReference
          .where('owerRef',
              isEqualTo: _userReference
                  .document(tab.key == Key('0') ? user.uuid : user.partnerId))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        if (sortByDate(snapshot.data.documents) == null)
          return Center(
              child: hasPartner
                  ? Container(
                      child: Text(
                        tab.key == Key('0') ? 'お願いをいれてね' : '何か手伝うよ〜',
                        style:
                            TextStyle(color: constants.ivyGrey, fontSize: 20),
                      ),
                    )
                  : Container(
                      child: Text(
                        'パートナーと繋がってね',
                        style:
                            TextStyle(color: constants.ivyGrey, fontSize: 20),
                      ),
                    ));
        return _buildList(
            context, sortByDate(snapshot.data.documents), tab.key);
      },
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> sortedList, Key key) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children:
          sortedList.map((data) => _buildListItem(context, data, key)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, dynamic data, Key key) {
    final _onegai = OnegaiResponse.fromMap(data);

    //自分へのお願いの場合は、期日当日にpush通知
    if (key == Key('0')) if (isOnDue(_onegai)) sendDueNotification(_onegai);

    return Padding(
      key: ValueKey(_onegai.content),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: constants.violet),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: LabeledCheckbox(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OnegaiCreator()),
            );
          },
          label: _onegai.content,
          subtitle: formatter.format(_onegai.dueDate),
          padding: EdgeInsets.all(10.0),
          value: _onegai.status,
          isOver: isOver(_onegai.dueDate),
          onChanged: (value) {
            setState(() {
              Firestore.instance.runTransaction((transaction) async {
                await transaction.update(
                    _onegaiReference.document(_onegai.onegaiId),
                    {'status': true}).then((value) {
                  Timer(Duration(milliseconds: 750), () {
                    _onegaiReference
                        .document(_onegai.onegaiId)
                        .delete()
                        .then((value) {
                      if (key == Key('0'))
                        sendCompleteNotification(_onegai.content);
                      print("deleted");
                    }).catchError((error) {
                      print(error);
                    });
                  });
                });
              });
            });
          },
        ),
      ),
    );
  }

  bool isOver(DateTime due) {
    DateTime today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return DateTime(due.year, due.month, due.day).isBefore(today);
  }

  bool isOnDue(OnegaiResponse _onegai) {
    DateTime today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    var due = _onegai.dueDate;
    var createdAt = _onegai.createdAt;

    if (DateTime(createdAt.year, createdAt.month, createdAt.day)
        .isAtSameMomentAs(today)) return false;

    return DateTime(due.year, due.month, due.day).isAtSameMomentAs(today);
  }

  void sendDueNotification(OnegaiResponse _onegai) async {
    if (!_onegai.isDueNotificationPushed) return null;

    var serverKey = constants.serverKey;
    var onegai = _onegai.content;

    final notification = {
      "to": "/topics/" + user.uuid,
      "notification": {"title": "$onegaiの期日が迫ってるよ！"},
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

      _onegaiReference
          .document(_onegai.onegaiId)
          .updateData({'isDueNotificationPushed': true});
    } else {
      print("failed push notification");
    }
  }

  List<Map<String, dynamic>> sortByDate(List<DocumentSnapshot> list) {
    if (list.isEmpty) return null;
    List<Map<String, dynamic>> sortedList = [];
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
  const LabeledCheckbox(
      {this.label,
      this.subtitle,
      this.value,
      this.onChanged,
      this.padding,
      this.onTap,
      this.isOver});

  final String label;
  final String subtitle;
  final bool value;
  final Function onChanged;
  final EdgeInsets padding;
  final Function onTap;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label,
                      style: TextStyle(
                          fontSize: 25.0,
                          color:
                              isOver ? constants.violet : constants.ivyGrey)),
                  Row(
                    children: <Widget>[
                      Icon(
                        const IconData(59670, fontFamily: 'MaterialIcons'),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(subtitle,
                          style: TextStyle(
                              color: isOver ? Colors.red : constants.ivyGrey))
                    ],
                  ),
                ]),
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
