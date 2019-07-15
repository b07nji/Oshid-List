import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oshid_list_v1/entity/user.dart';

import 'authentication.dart';

final auth = Authentication();
final user = User();
final _userReference = Firestore.instance.collection('users');

class LoginPage extends StatefulWidget {

  @override
  _LoginPageState createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text('Oshid-List'), backgroundColor: Colors.blue,),
      body: Container(
        child: _buildGoogleSignInButton(),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(
          child: RaisedButton(
            child: Text('Googleアカウントでログイン'),
            onPressed: () {
//              _handleGoogleSignIn().then((googleUser) {
//                setState(() {
//                  user.user = googleUser;
//                  /**
//                   * uuid保存
//                   */
//                  print("loginPage: " + user.uuid);
//                });
//
//                if (!user.user.isEmailVerified) {
//                  //TODO: 認証失敗の処理
//                }
//
//                _userReference.document(user.uuid).snapshots().listen((
//                    snapshot) {
//                  //TODO: uidをドキュメントIDにしてるけどええんか？
//                  _userReference.document(user.uuid).setData(
//                      {
//                        'name': user.user.displayName,
//                        'photoUrl': user.photoUrl,
//                        'uuid': user.uuid
//                      }
//                  );
//                  /**
//                   * home画面へ
//                   */
//                  Navigator.of(context).pushReplacementNamed('/home');
//                });
//              });
            },
          ),
        )
      ],
    );
  }
}