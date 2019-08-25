import 'package:oshid_list_v1/entity/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants.dart';

final constants = Constants();
final user = User();

class Authentication {

  void saveUserInfo(String uuid, String userName) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    user.uuid = (preferences.getString(constants.uuid) ?? null);
    await preferences.setString(constants.uuid, uuid);
    await preferences.setString(constants.userName, userName);
  }

  Future<String> getUuid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getString(constants.uuid) ?? null);
  }

  void savePartnerInfo(String partnerId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(constants.partnerId, partnerId);
  }

  Future<String> getPartnerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getString(constants.partnerId) ?? null);
  }

  void saveHasPartnerFlag(bool hasPartner) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(constants.hasPartner, hasPartner);
  }

  Future<bool> hasPartner() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(constants.hasPartner) ?? false);
  }
}

