import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oshid_list_v1/entity/onegai.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _onegaiReference = Firestore.instance.collection('onegai');
final _userReference = Firestore.instance.collection('users');
final user = User();

class OnegaiCreator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('おねがいする'),
        backgroundColor: Colors.blue,
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
  final _onegai = Onegai();

  ///ボタンの色を変化させる
  bool pressAttention1 = true;
  bool pressAttention2 = false;
  bool pressAttention3 = false;

  SharedPreferences preferences;

  ///起動時に呼ばれる
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences pref) {
      preferences = pref;
      setState(() {
        user.uuid = preferences.getString('uuid');
        user.photoUrl = preferences.getString('photoUrl');
      });

    });
  }

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
      context: context,
      initialDate: new DateTime.now(),
      firstDate: DateTime(1994),
      lastDate: DateTime(2025)
    );
    if (picked != null) {
      setState(() => _onegai.dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380.0,
      child: Form(
        key: this._formKey,
        child: ListView(
          children: <Widget>[
            TextFormField(
              validator: (value) {
                if (value.isEmpty) return 'おねがいを入れてね';
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'おねがい'
              ),
              onSaved: (value) => (setState(() => _onegai.content = value))
            ),

            Text('誰に?'),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  color: pressAttention1 ? Colors.cyan : Colors.grey,
                  onPressed: () {
                    setState(() {
                      pressAttention1 = !pressAttention1;
                      pressAttention2 = false;
                      pressAttention3 = false;
                    });
                  },
                  child: Text('パートナー')
                ),
                FlatButton(
                  color: pressAttention2 ? Colors.cyan : Colors.grey,
                  onPressed: () {
                    setState(() {
                      pressAttention2 = !pressAttention2;
                      pressAttention1 = false;
                      pressAttention3 = false;
                    });
                  },
                    child: Text('ふたりで'),
                ),
                FlatButton(
                    color: pressAttention3 ? Colors.cyan : Colors.grey,
                    onPressed: () {
                      setState(() {
                        pressAttention3 = !pressAttention3;
                        pressAttention1 = false;
                        pressAttention2 = false;
                      });
                    },
                    child: Text('自分')
                )
              ],
            ),

            Text('いつまでに? ${_onegai.dueDate}'),


            SizedBox(
              width: 10.0,
              child: RaisedButton.icon(
                color: Colors.white,
                onPressed: _selectDate,
                icon: Icon(Icons.date_range),
                label: Text('いつまでに？'),
              ),
            ),

            Container(
              child: RaisedButton(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('おねがいする', style: TextStyle(color: Colors.white),),
                color: Colors.blue,
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    Scaffold.of(context)
                        .showSnackBar(SnackBar(content: Text('送信しています'),));
                    _formKey.currentState.save();

                    //TODO: documentIDをフィールドに含める必要ある？
                    _onegaiReference.add(
                        {
                          'content': _onegai.content,
                          'dueDate': _onegai.dueDate,
                          'status': false,
                          'owerRef': _userReference.document(user.uuid)

                        }
                    ).then((docRef) {
                      _onegaiReference.document(docRef.documentID).updateData(
                          {
                            'onegaiId': docRef.documentID
                          }
                      );
                      Navigator.of(context).pop('/home');
                    });

                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}