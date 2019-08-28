import 'dart:ui';

class Constants {
  //Firestore key
  final onegai = 'onegai';
  final users = 'users';

  //Preference key
  final uuid = 'uuid';
  final userName = 'userName';
  final partnerId = 'partnerId';
  final hasPartner = 'hasPartner';

  //色
  final violet = Color.fromRGBO(207, 167, 205, 1);
  final grey = Color.fromRGBO(229, 229, 229, 1);

  //FCM server key
  final serverKey = 'AAAAwldVx0o:APA91bFYc67P8oOR1F2FYOYFZdZG-qcmxQITKBEQk5nyCMpPPCLq4KD15diao8CWhBBKoW2V9ur02EqwUq3CLt9km5q3X7Pz_DHw5cS6PuTRj_ILvpB1ZvXpu9rNarQGlbtsZ6nutREp';

}

// onegaiPage
enum Status { Yours, Mine, Together }
