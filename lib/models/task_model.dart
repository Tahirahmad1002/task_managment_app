import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String id;
  String title;
  String description; // NEW
  String category;    // NEW
  bool isDone;
  DateTime createdAt;

  TaskModel({
    required this.id, 
    required this.title, 
    this.description = "", // NEW
    this.category = "General", // NEW
    this.isDone = false, 
    required this.createdAt
  });

  factory TaskModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return TaskModel(
      id: snap.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '', // NEW
      category: data['category'] ?? 'General', // NEW
      isDone: data['isDone'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description, // NEW
    "category": category,       // NEW
    "isDone": isDone,
    "createdAt": createdAt,
  };
}