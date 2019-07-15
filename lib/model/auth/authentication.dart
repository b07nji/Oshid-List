import 'package:oshid_list_v1/entity/user.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Authentication {
  final user = User();

  void saveUserInfo(String uuid, String photoUrl) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    user.uuid = (preferences.getString('uuid') ?? null);
    user.photoUrl = (preferences.getString('photoUrl') ?? null);
    await preferences.setString('uuid', uuid);
    await preferences.setString('photoUrl', photoUrl);

  }

  Future<String> getUuid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getString('uuid') ?? null);

  }

  Future<String> getPhotoUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getString('photoUrl') ?? null);

  }

}

