import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oshid_list_v1/entity/onegai.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/auth/authentication.dart';
import 'package:oshid_list_v1/model/qrUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onegaiPage.dart';
import 'pointPage.dart';

import "package:intl/intl.dart";

final _onegaiReference = Firestore.instance.collection('onegai');
final _userReference = Firestore.instance.collection('users');
final auth = Authentication();
final user = User();
final qr = QRUtils();

class MyHomePage extends StatefulWidget {
//  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {

  final List<Tab> tabs = <Tab> [
    Tab(
      key: Key('0'),
      text: '自分',
        ),
    Tab(
      key: Key('1'),
      text: 'パートナー',
    ),
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
        user.uuid = preferences.getString('uuid');
        user.hasPartner = preferences.getBool('hasPartner');
        user.partnerId = preferences.getString('partnerId');
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
        backgroundColor: Color.fromRGBO(207, 167, 205, 1),
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
                        color: Color.fromRGBO(207, 167, 205, 1)
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
                                      title:Text('pointPage.dart'),
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
                                  title:Text('pointPage.dart'),
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
//                        test.keys.forEach((key) {
//                          print(key + " : " + test[key].toString());
//                        });
                        auth.saveHasPartnerFlag(data['hasPartner']);
                        user.hasPartner = data['hasPartner'];
                        auth.hasPartner().then((value) {
                          print('has partner?: ' + value.toString());
                        });

                        auth.savePartnerInfo(data['partnerId']);
                        user.partnerId = data['partnerId'];
                        auth.getPartnerId().then((value) {
                          print('what is partner id: ' + value);
                        });
                      });


                      showDialog(
                          context: context,
                          builder: (context) {
                            return SimpleDialog(
                              title:Text('pointPage.dart'),
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
        backgroundColor: Color.fromRGBO(207, 167, 205, 1),
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
        indicatorColor: Color.fromRGBO(207, 167, 205, 1),
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
      /**
       * TODO: 時系列順にそーと
       */

      stream: _onegaiReference.where('owerRef', isEqualTo: _userReference.document(uuid)).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return
      ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context,data)).toList(),
    );

  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);
    var formatter = DateFormat('E: M/d', "ja");

    return Padding(
      key: ValueKey(record.content),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: LabeledCheckbox(
          onTap:(){Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OnegaiCreator()),
          );},
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
              _onegaiReference.document(record.reference.documentID).delete().then((value) {
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
}

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    this.label,
    this.value,
    this.onChanged,
    this.subtitle,
    this.padding,
    this.onTap,
  });

  final String label;
  final bool value;
  final Function onChanged;
  final String subtitle;
  final EdgeInsets padding;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding:padding,
        child: Row(
          children: <Widget>[
            Expanded(
              child:InkWell(
              onTap:(){Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OnegaiCreator()),
              );},
              child:Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
              Text(label,
              style:TextStyle(fontSize: 25.0)),
              Text(subtitle),]
             ),),),
              Checkbox(
              value: value,
              activeColor: Color.fromRGBO(207, 167, 205, 1),
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
  final String content;
  final DateTime dueDate;
  bool status = true;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference}) :
        assert(map['content'] != null),
        assert((map['dueDate']) != null),
        assert((map['status']) != null),
        content = map['content'],
        dueDate = DateTime.fromMillisecondsSinceEpoch(map['dueDate'].millisecondsSinceEpoch),
        status = map['status'];

  Record.fromSnapshot(DocumentSnapshot snapshot): this.fromMap(
      snapshot.data,
      reference: snapshot.reference
  );

  @override
  String toString() => "Record<$content: $dueDate>";
}
