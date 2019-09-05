import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/store.dart';
import 'package:uuid/uuid.dart';

final store = Store();
final user = User();
final _userReference = Firestore.instance.collection(constants.users);

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Container(
            height: 50,
            width: 200,
            child: Image.asset(constants.flag),
          ),
          backgroundColor: Colors.white,
        ),
        body: Builder(
          builder: (context) => Center(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 24.0),
                    TextFormField(
                      cursorColor: Colors.deepPurpleAccent,
                      decoration: const InputDecoration(
                        border: const UnderlineInputBorder(),
                        labelText: 'ニックネーム',
                        labelStyle:
                            TextStyle(color: Color.fromRGBO(102, 108, 103, 1)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.deepPurpleAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.deepPurpleAccent),
                        ),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'ニックネームを入れてね';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        user.userName = value;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    Center(
                      child: RaisedButton(
                        color: constants.violet,
                        child: const Text(
                          '登録する',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          // TODO: ログイン処理
                          //1. generate uuid
                          var uuid = Uuid();

                          if (_formKey.currentState.validate()) {
                            Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text(
                              '送信しています',
                              textAlign: TextAlign.center,
                            )));
                          }
                          _formKey.currentState.save();
                          //TODO: user.uuidへの代入をする場所考える
                          user.uuid = uuid.v1();
                          user.hasPartner = false;
                          user.partnerId = "no partner";

                          _userReference.document(user.uuid).setData({
                            'uuid': user.uuid,
                            'userName': user.userName,
                            'hasPartner': user.hasPartner,
                            'partnerId': user.partnerId
                          }).whenComplete(() {
                            //3. add to preference. if no sentence below here, can't relate user with onegai
                            store.saveUserInfo(user.uuid, user.userName);
                            store.saveHasPartnerFlag(user.hasPartner);
                            store.savePartnerId(user.partnerId);

                            Navigator.of(context).pushReplacementNamed('/home');
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
