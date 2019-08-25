import 'dart:ui';

class Constants {
  // Firestore key
  final onegai = 'onegai';
  final users = 'users';

  // Preference key
  final uuid = 'uuid';
  final userName = 'userName';
  final partnerId = 'partnerId';
  final hasPartner = 'hasPartner';

  // 色
  final violet = Color.fromRGBO(207, 167, 205, 1);
  final grey = Color.fromRGBO(229, 229, 229, 1);

}

// onegaiPage
enum Status { NotYours, NotMine, Together }
