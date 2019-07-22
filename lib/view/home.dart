import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/qrUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onegaiPage.dart';


final _onegaiReference = Firestore.instance.collection('onegai');
final _userReference = Firestore.instance.collection('users');
final user = User();
final qr = QRUtils();

class MyHomePage extends StatefulWidget {
//  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SharedPreferences preferences;

  ///起動時に呼ばれる
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences pref) {
      preferences = pref;
      setState(() {
        user.uuid = preferences.getString('uuid');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Oshid-List'),),
      body: _buildBody(context),
      endDrawer:
      Drawer(
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
                     * TODO
                     */
                    _onegaiReference.where('owerRef', isEqualTo: _userReference.document(partnerId)).snapshots()
                            .forEach((value) {
                              String test;

                              value.documents.map((v) {
                                test = v.data.containsKey('name').toString();
                              });
                      showDialog(
                          context: context,
                          builder: (context) {
                            return SimpleDialog(
                              title: Text('パートナーと繋がる'),
                              children: <Widget>[
                                SimpleDialogOption(
                                  //onPressed: ,
                                  child: Text(test + ': ' + partnerId),
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


      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add, size: 30),
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OnegaiCreator()),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot> (
      stream: _onegaiReference.where('owerRef', isEqualTo: _userReference.document(user.uuid)).snapshots(),
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

    return Padding(
      key: ValueKey(record.content),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: CheckboxListTile(
          title: Text(record.content),
          subtitle: Text(record.dueDate.toIso8601String()),
          value: record.status,
          activeColor: Colors.blue,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (bool e) {
            setState(() {
              print('change status called');
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

