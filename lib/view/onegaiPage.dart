import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oshid_list_v1/entity/onegai.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/auth/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:intl/intl.dart";

final _onegaiReference = Firestore.instance.collection('onegai');
final _userReference = Firestore.instance.collection('users');
final user = User();
final auth = Authentication();

class OnegaiCreator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('おねがいする'),
        backgroundColor: Color.fromRGBO(207, 167, 205, 1),
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
///日付の表示変換
  var formatter = DateFormat('M/d E', "ja");
///繰り返しボタンリスト
  List<String> _repeatation = ['毎日', '週に一度', '月に一度', '年に一度'];
  String _selectedRepeatation;

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
        //TODO: リファクタ
        user.uuid = preferences.getString('uuid');
        user.hasPartner = preferences.getBool('hasPartner');
        user.partnerId = preferences.getString('partnerId');

        auth.hasPartner().then((value) {
          if (!value) {
            user.partnerId = 'not yours';
            print(user.partnerId);
          }
        });

        pressAttention1 = user.hasPartner;
        pressAttention3 = !user.hasPartner;
      });
    });
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
                if (value.isEmpty) return "おねがいを入れてね";
                return null;
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
                  child: Text('パートナー'),
                  onPressed: () {
                    if (user.hasPartner) {
                      setState(() {
                        pressAttention1 = !pressAttention1;
                        pressAttention2 = false;
                        pressAttention3 = false;

                        //TODO: partnerID = 'no partner'の時にdisable
                        user.uuid = 'not mine';
                      });
                    }
                    showDialog(
                        context: context,
                        builder: (context) {
                          return SimpleDialog(
                            title:Text('test'),
                            children: <Widget>[
                              AlertDialog(
                                title: Text('パートナーと繋がってね'),
                              )
                            ],
                          );
                        }
                    );
                  }
                ),
                FlatButton(
                  color: pressAttention2 ? Colors.cyan : Colors.grey,
                  child: Text('ふたりで'),
                  onPressed: () {
                    if (user.hasPartner) {
                      setState(() {
                        pressAttention2 = !pressAttention2;
                        pressAttention1 = false;
                        pressAttention3 = false;
                      });
                    }
                    showDialog(
                        context: context,
                        builder: (context) {
                          return SimpleDialog(
                            title:Text('test'),
                            children: <Widget>[
                              AlertDialog(
                                title: Text('パートナーと繋がってね'),
                              )
                            ],
                          );
                        }
                    );

                  },
                ),
                FlatButton(
                    color: pressAttention3 ? Colors.cyan : Colors.grey,
                    child: Text('自分'),
                    onPressed: () {
                      setState(() {
                        pressAttention3 = !pressAttention3;
                        pressAttention1 = false;
                        pressAttention2 = false;
                        user.partnerId = 'not yours';
                      });
                    }
                )
              ],
            ),

            Text('いつまでに? ${formatter.format(_onegai.dueDate)}'),
            SizedBox(
              width: 10.0,
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
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                hint: Text('繰り返す？'),
                value: _selectedRepeatation,
                onChanged: (newValue) {
                  setState(() {
                    _selectedRepeatation = newValue;
                  });
                },
                items: _repeatation.map((location) {
                  return DropdownMenuItem(
                    child: new Text(location),
                    value: location,
                  );
                }).toList(),
              ),
            ),),

            Container(
              child: RaisedButton(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'おねがいする',
                  style: TextStyle(color: Colors.white),
                ),
                color: Color.fromRGBO(207, 167, 205, 1),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text('送信しています'),
                    ));
                    _formKey.currentState.save();

                    //TODO: documentIDをフィールドに含める必要ある？
                    //TODO: リファクタ

                    if (user.partnerId == 'not yours') {
                      //to me
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

                    } else if(user.uuid == 'not mine') {
                      //to partner
                      _onegaiReference.add(
                          {
                            'content': _onegai.content,
                            'dueDate': _onegai.dueDate,
                            'status': false,
                            'owerRef': _userReference.document(user.partnerId)

                          }
                      ).then((docRef) {
                        _onegaiReference.document(docRef.documentID).updateData(
                            {
                              'onegaiId': docRef.documentID
                            }
                        );
                        Navigator.of(context).pop('/home');
                      });
                    } else {
                      //together
                      [user.uuid, user.partnerId].forEach((uuid) {
                        _onegaiReference.add(
                            {
                              'content': _onegai.content,
                              'dueDate': _onegai.dueDate,
                              'status': false,
                              'owerRef': _userReference.document(uuid)

                            }
                        ).then((docRef) {
                          _onegaiReference.document(docRef.documentID).updateData(
                              {
                                'onegaiId': docRef.documentID
                              }
                          );
                        });
                      });

                      /**
                       * TODO:[refactor]値の初期化
                       */
                      user.uuid = preferences.getString('uuid');
                      user.partnerId = preferences.getString('partnerId');
                      Navigator.of(context).pop('/home');

                    }
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
