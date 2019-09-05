import 'dart:ui';

class Constants {
  //Firestore key
  final onegai = 'onegai';
  final users = 'users';

  //Preference key
  final uuid = 'uuid';
  final userName = 'userName';
  final partnerId = 'partnerId';
  final partnerName = 'partnerName';
  final hasPartner = 'hasPartner';

  //色
  final violet = Color.fromRGBO(207, 167, 205, 1);
  final grey = Color.fromRGBO(229, 229, 229, 1);
  final ivyGrey = Color.fromRGBO(102, 108, 103, 1);
  final darkGold = Color.fromRGBO(108, 93, 83, 1);
  final floatingButton = Color.fromRGBO(230, 230, 250, 1);

  //FCM
  final serverKey =
      'AAAAwldVx0o:APA91bFYc67P8oOR1F2FYOYFZdZG-qcmxQITKBEQk5nyCMpPPCLq4KD15diao8CWhBBKoW2V9ur02EqwUq3CLt9km5q3X7Pz_DHw5cS6PuTRj_ILvpB1ZvXpu9rNarQGlbtsZ6nutREp';
  final url = 'https://fcm.googleapis.com/fcm/send';

  //AdMob
  final appId = 'ca-app-pub-3234540343519708~3708344405';
  final addUnitId = 'ca-app-pub-3234540343519708/8264512994';

  //タブ
  final me = '自分';
  final partner = 'パートナー';

  //画像
  final flag = 'icon/oshid_list_flag.png';
  final oshidoriBlue = 'images/oshidori_icon.png';
  final oshidoriGreen = 'images/oshidori_icon2.png';
}

// onegaiPage
enum Status { Yours, Mine, Together }
