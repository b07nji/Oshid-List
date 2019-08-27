import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/auth/authentication.dart';
import 'package:oshid_list_v1/model/qrUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MyHomePage extends StatefulWidget {
//  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
//  // 以下をStateの中に記述
//  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
//
//  @override
//  void initState() {
//    super.initState();
//    _firebaseMessaging.configure(
//      onMessage: (Map<String, dynamic> message) async {
//        print("onMessage: $message");
//        _buildDialog(context, "onMessage");
//      },
//      onLaunch: (Map<String, dynamic> message) async {
//        print("onLaunch: $message");
//        _buildDialog(context, "onLaunch");
//      },
//      onResume: (Map<String, dynamic> message) async {
//        print("onResume: $message");
//        _buildDialog(context, "onResume");
//      },
//    );
//    _firebaseMessaging.requestNotificationPermissions(
//        const IosNotificationSettings(sound: true, badge: true, alert: true));
//    _firebaseMessaging.onIosSettingsRegistered
//        .listen((IosNotificationSettings settings) {
//      print("Settings registered: $settings");
//    });
//    _firebaseMessaging.getToken().then((String token) {
//      assert(token != null);
//      print("Push Messaging token: $token");
//    });
//    _firebaseMessaging.subscribeToTopic("/topics/all");
//  }
//
//  // ダイアログを表示するメソッド
//  void _buildDialog(BuildContext context, String message) {
//    showDialog(
//        context: context,
//        barrierDismissible: false,
//        builder: (BuildContext context) {
//          return new AlertDialog(
//            content: new Text("Message: $message"),
//            actions: <Widget>[
//              new FlatButton(
//                child: const Text('CLOSE'),
//                onPressed: () {
//                  Navigator.pop(context, false);
//                },
//              ),
//              new FlatButton(
//                child: const Text('SHOW'),
//                onPressed: () {
//                  Navigator.pop(context, true);
//                },
//              ),
//            ],
//          );
//        }
//    );
//  }

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
      });
    });
    //タブ生成
    _tabController = TabController(length: tabs.length, vsync: this);
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
                                    return SimpleDialog(
                                      title:Text('test'),
                                      children: <Widget>[
                                        AlertDialog(
                                          title: Text('uuid: ' + user.uuid + "/ partner id: " + user.partnerId),
                                        )
                                      ],
                                    );
                                  }
                              );
                        });

                        _userReference.document(user.partnerId).updateData({
                          'hasPartner': user.hasPartner,
                          'partnerId': user.uuid
                        }).whenComplete(() {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return SimpleDialog(
                                  title:Text('test'),
                                  children: <Widget>[
                                    AlertDialog(
                                      title: Text('パートナーに反映'),
                                    )
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
                /**
                 * TODO: [WIP]CLoud Messaginで処理するようにする
                 */
                Container(
                  child: RaisedButton(
                    child: Text('パートナー情報反映'),
                    onPressed: () {
                      _userReference.document(user.uuid).snapshots().forEach((snapshots) {
                        Map<String, dynamic> data = Map<String, dynamic>.from(snapshots.data);

                        auth.saveHasPartnerFlag(data[constants.hasPartner]);
                        user.hasPartner = data[constants.hasPartner];
                        auth.hasPartner().then((value) {
                          print('has partner?: ' + value.toString());
                        });

                        auth.savePartnerInfo(data[constants.partnerId]);
                        user.partnerId = data[constants.partnerId];
                        auth.getPartnerId().then((value) {
                          print('what is partner id: ' + value);
                        });
                      });


                      showDialog(
                          context: context,
                          builder: (context) {
                            return SimpleDialog(
                              title:Text('test'),
                              children: <Widget>[
                                AlertDialog(
                                  title: Text('パートナーに反映'),
                                )
                              ],
                            );
                          }
                      );
                    }),
                ),
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
