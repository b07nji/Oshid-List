import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/auth/authentication.dart';
import 'package:oshid_list_v1/model/qrUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onegaiPage.dart';

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
        user.uuid = preferences.getString('uuid');
        user.partnerId = preferences.getString('partnerId');
        print("initState() is called: " + user.uuid);
      });
    });

    //タブ生成
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Oshid-List'),),
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
                        color: Colors.blue
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
                        auth.savePartnerInfo(partnerId);
                        user.partnerId = partnerId;

                        _userReference.document(user.uuid).updateData({
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
                      });
                    },
                  ),
                ),

                Container(
                  child: qr.generateQr(user.uuid),
                ),

                Container(
                  child: Text('ログアウトする'),
                ),
              ],
            ),

          ),


////      floatingActionButton: FloatingActionButton(
//        child: Icon(Icons.add, size: 30),
//        backgroundColor: Colors.blue,
//        onPressed: () {
//          Navigator.push(
//            context,
//            MaterialPageRoute(builder: (context) => OnegaiCreator()),
//          );
//        },
//      ),

      //タブ生成
      bottomNavigationBar: TabBar(
        tabs: tabs,
        controller: _tabController,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
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
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context,data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);
    var formatter = new DateFormat('(E) M/d', "ja");

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
              activeColor: Colors.blue,
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
