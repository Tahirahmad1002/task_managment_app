import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String id;
  String title;
  bool isDone;
  DateTime createdAt;

  TaskModel({required this.id, required this.title, this.isDone = false, required this.createdAt});

  // Convert Firebase data to a Task Object
  factory TaskModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return TaskModel(
      id: snap.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert Task Object to Map to send to Firebase
  Map<String, dynamic> toJson() => {
    "title": title,
    "isDone": isDone,
    "createdAt": createdAt,
  };
}