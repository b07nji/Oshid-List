import 'package:oshid_list_v1/entity/user.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Authentication {
  final user = User();

  void saveUserInfo(String uuid, String nickname) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    user.uuid = (preferences.getString('uuid') ?? null);
    await preferences.setString('uuid', uuid);
    await preferences.setString('nickname', nickname);

  }

  Future<String> getUuid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getString('uuid') ?? null);

  }
}

