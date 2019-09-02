import 'package:cloud_firestore/cloud_firestore.dart';

class OnegaiRequest {
  String key;
  String content;
  String whose;
  String owerRef;
  DateTime dueDate = DateTime.now();
  bool status;
}

class OnegaiResponse {
  final String onegaiId;
  final String content;
  final DateTime dueDate;
  bool status = true;
  final DocumentReference reference;

  OnegaiResponse.fromMap(Map<String, dynamic> map, {this.reference}) :
        assert(map['onegaiId'] != null),
        assert(map['content'] != null),
        assert((map['dueDate']) != null),
        assert((map['status']) != null),
        onegaiId = map['onegaiId'],
        content = map['content'],
        dueDate = DateTime.fromMillisecondsSinceEpoch(map['dueDate'].millisecondsSinceEpoch),
        status = map['status'];

//  Record.fromSnapshot(dynamic snapshot): this.fromMap(
//      snapshot.data,
//      reference: snapshot.reference
//  );

  @override
  String toString() => "Record<$content: $dueDate>";
}
