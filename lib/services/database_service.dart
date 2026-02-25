import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER DATA METHODS ---

  // 1. SAVE USER DATA (Called during Sign Up)
  Future<void> saveUserData(String userId, String name, String email) async {
    await _db.collection('users').doc(userId).set({
      "uid": userId,
      "name": name,
      "email": email,
      "createdAt": Timestamp.now(),
    }, SetOptions(merge: true)); // merge: true ensures we don't overwrite tasks
  }

  // 2. GET USER DATA (To show "Hi, Name" on Home)
  Stream<DocumentSnapshot> getUserData(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // 3. UPDATE USER NAME
  Future<void> updateUserName(String userId, String newName) async {
    await _db.collection('users').doc(userId).update({
      "name": newName,
    });
  }

  // --- TASK METHODS (Kept exactly as yours) ---

  // 1. ADD TASK
  Future<void> addTask(String userId, String title) async {
    await _db.collection('users').doc(userId).collection('tasks').add({
      "title": title,
      "isDone": false,
      "createdAt": Timestamp.now(),
    });
  }

  // 2. GET TASKS (Real-time stream)
  Stream<List<TaskModel>> getTasks(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromSnapshot(doc)).toList());
  }

  // 3. TOGGLE DONE
  Future<void> updateTaskStatus(String userId, String taskId, bool currentStatus) async {
    await _db.collection('users').doc(userId).collection('tasks').doc(taskId).update({
      "isDone": !currentStatus,
    });
  }

  // 4. DELETE TASK
  Future<void> deleteTask(String userId, String taskId) async {
    await _db.collection('users').doc(userId).collection('tasks').doc(taskId).delete();
  }
}