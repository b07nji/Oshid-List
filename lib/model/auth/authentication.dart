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

  void savePartnerInfo(String partnerId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('partnerId', partnerId);
  }

  Future<String> getPartnerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getString('partnerId') ?? null);
  }

  void saveHasPartnerFlag(bool hasPartner) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('hasPartner', hasPartner);
  }

  Future<bool> hasPartner() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getBool('hasPartner') ?? false);
  }
}

