import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oshid_list_v1/entity/user.dart';
import 'package:oshid_list_v1/model/auth/authentication.dart';
import 'package:uuid/uuid.dart';

final auth = Authentication();
final user = User();
final _userReference = Firestore.instance.collection('users');

class LoginPage extends StatefulWidget {

  @override
  _LoginPageState createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ログイン"),
        backgroundColor: Color.fromRGBO(207, 167, 205, 1),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 24.0),
                TextFormField(
                  decoration: const InputDecoration(
                    border: const UnderlineInputBorder(),
                    labelText: 'ニックネーム',
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'ニックネームを入れてね';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    user.nickname = value;
                    print('onsaved is caleed, value is:  ' + value);
                  },
                ),
                const SizedBox(height: 24.0),
                Center(
                  child: RaisedButton(
                    child: const Text('登録する'),
                    onPressed: () {
                      // TODO: ログイン処理
                      //1. generate uuid
                      var uuid = Uuid();

                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                        print(user.nickname);
//                        Scaffold.of(context)
//                            .showSnackBar(SnackBar(content: Text('送信しています')));
                      }
                      //TODO: user.uuidへの代入をする場所考える
                      user.uuid = uuid.v1();
                      user.hasPartner = false;
                      user.partnerId = "no partner";
                      print(user.uuid);

                      _userReference.document(user.uuid).setData(
                          {
                            'uuid': user.uuid,
                            'name': user.nickname,
                            'hasPartner': user.hasPartner,
                            'partnerId': user.partnerId
                          }
                      ).whenComplete(() {
                        Navigator.of(context).pushReplacementNamed('/home');
                      });
                      //3. add to preference. if no sentence below here, can't relate user with onegai
                      auth.saveUserInfo(user.uuid, user.uuid);
                      auth.saveHasPartnerFlag(user.hasPartner);
                      auth.savePartnerInfo(user.partnerId);

                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}