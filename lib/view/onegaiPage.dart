import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oshid_list_v1/entity/onegai.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/auth/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:intl/intl.dart";

import '../constants.dart';

final _onegaiReference = Firestore.instance.collection(constants.onegai);
final _userReference = Firestore.instance.collection(constants.users);
final user = User();
final auth = Authentication();
final constants = Constants();

class OnegaiCreator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('おねがいする'),
        backgroundColor: constants.violet,
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
        user.hasPartner = preferences.getBool(constants.hasPartner);
        if (user.hasPartner) {
          _radVal = Status.Yours;
        }

        user.uuid = preferences.getString(constants.uuid);
        user.partnerId = preferences.getString(constants.partnerId);

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
        )
    );
  }

  void _onChanged(value) {
    setState(() {
      switch (_radVal) {
        case Status.Mine:
          if (user.hasPartner) {
            _radVal = value;
            user.uuid = preferences.getString(constants.uuid);
            print('mine: uuid ' + user.uuid + ', partner ' + user.partnerId);
          } else {
            _buildNoPartnerDialog(context);
          }

          break;
        case Status.Yours:
          if (user.hasPartner) {
            _radVal = value;
            user.partnerId = preferences.getString(constants.partnerId);
            print('mine: uuid ' + user.uuid + ', partner ' + user.partnerId);

          } else {
            _buildNoPartnerDialog(context);
          }
          break;
        case Status.Together:
          if (user.hasPartner) {
            _radVal = value;
            user.uuid = preferences.getString(constants.uuid);
            user.partnerId = preferences.getString(constants.partnerId);
            print('together: uuid ' + user.uuid + ', partner ' + user.partnerId);

          } else {
            _buildNoPartnerDialog(context);
          }
          break;
      }
    });
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
            Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  RadioListTile(
                      title: Text('パートナー'),
                      value: Status.Yours,
                      groupValue: _radVal,
                      activeColor: constants.violet,
                      onChanged: _onChanged),
                  RadioListTile(
                      title: Text('ふたりで'),
                      value: Status.Together,
                      groupValue: _radVal,
                      activeColor: constants.violet,
                      onChanged: _onChanged),
                  RadioListTile(
                      title: Text('自分'),
                      value: Status.Mine,
                      groupValue: _radVal,
                      activeColor: constants.violet,
                      onChanged: _onChanged),
                ],
              ),
            ),

            Text('いつまでに?'),
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

            Container(
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
                      content: Text('送信しています'),
                    ));
                    _formKey.currentState.save();

                    // TODO: documentIDをフィールドに含める必要ある？
                    //　TODO: リファクタ

                    // 自分
                    if (_radVal == Status.Mine) {

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

                      // パートナー
                    } else if(_radVal == Status.Yours) {

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
                      // ふたりで
                    } else {
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
                      user.uuid = preferences.getString(constants.uuid);
                      user.partnerId = preferences.getString(constants.partnerId);
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
