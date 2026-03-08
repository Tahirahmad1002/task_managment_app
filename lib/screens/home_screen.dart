import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/task_model.dart';
import 'signup_screen.dart'; 
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final DatabaseService _db = DatabaseService();
  final TextEditingController _taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: StreamBuilder<DocumentSnapshot>(
          stream: _db.getUserData(user!.uid),
          builder: (context, snapshot) {
            String displayName = "My Workspace";
            if (snapshot.hasData && snapshot.data!.exists) {
              displayName = "Hi, ${snapshot.data!['name']}! 👋";
            }
            return Text(
              displayName,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.blueAccent, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          IconButton(
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              }
            }, 
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent)
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2575FC),
        onPressed: () => _showAddTaskSheet(context, user.uid),
        label: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _db.getTasks(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final tasks = snapshot.data!;
          int completedCount = tasks.where((t) => t.isDone).length;
          double progressPercentage = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

          return Column(
            children: [
              // 1. PROGRESS BAR CARD
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Progress",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$completedCount of ${tasks.length} tasks completed",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${(progressPercentage * 100).toInt()}%",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. TASK LIST (UPDATED DESIGN)
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text("All clear! No tasks found.", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];

                          // Category Color Mapping
                          Color catColor;
                          switch (task.category) {
                            case 'Urgent': catColor = Colors.redAccent; break;
                            case 'Work': catColor = Colors.blueAccent; break;
                            case 'Personal': catColor = Colors.greenAccent; break;
                            default: catColor = Colors.orangeAccent;
                          }
                          
                          return Dismissible(
                            key: Key(task.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _db.deleteTask(user.uid, task.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${task.title} removed"), backgroundColor: Colors.redAccent),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border(left: BorderSide(color: catColor, width: 6)),
                                ),
                                child: ExpansionTile(
                                  leading: Checkbox(
                                    activeColor: const Color(0xFF6A11CB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    value: task.isDone,
                                    onChanged: (val) => _db.updateTaskStatus(user.uid, task.id, task.isDone),
                                  ),
                                  title: Text(task.title, style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                                    color: task.isDone ? Colors.grey : Colors.black87,
                                  )),
                                  subtitle: Text(
                                    "${task.category} • ${DateFormat('h:mm a').format(task.createdAt)}",
                                    style: TextStyle(fontSize: 12, color: catColor, fontWeight: FontWeight.w600),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 70, right: 20, bottom: 15),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Divider(),
                                          Text(task.description.isEmpty ? "No details added." : task.description,
                                              style: TextStyle(color: Colors.grey[700])),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () => _showEditTaskSheet(context, user.uid, task),
                                              icon: const Icon(Icons.edit, size: 18),
                                              label: const Text("Edit Task"),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- ADD TASK SHEET ---
  void _showAddTaskSheet(BuildContext context, String userId) {
    String selectedCategory = 'General';
    final TextEditingController _descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Create New Task", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _taskController,
                    decoration: InputDecoration(hintText: "Task Title", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(hintText: "Description (Optional)", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 15),
                  const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['General', 'Work', 'Personal', 'Urgent'].map((cat) {
                      bool isSel = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: const Color(0xFF2575FC),
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black),
                        onSelected: (selected) => setSheetState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2575FC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (_taskController.text.isNotEmpty) {
                          _db.addTask(userId, _taskController.text, _descController.text, selectedCategory);
                          _taskController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save Task", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- EDIT TASK SHEET ---
  void _showEditTaskSheet(BuildContext context, String userId, TaskModel task) {
    _taskController.text = task.title;
    final TextEditingController _editDescController = TextEditingController(text: task.description);
    String selectedCategory = task.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Task", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(controller: _taskController, decoration: const InputDecoration(labelText: "Task Title")),
              TextField(controller: _editDescController, decoration: const InputDecoration(labelText: "Description")),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                children: ['General', 'Work', 'Personal', 'Urgent'].map((cat) => ChoiceChip(
                  label: Text(cat),
                  selected: selectedCategory == cat,
                  onSelected: (s) => setSheetState(() => selectedCategory = cat),
                )).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _db.updateTaskDetails(userId, task.id, _taskController.text, _editDescController.text, selectedCategory);
                  _taskController.clear();
                  Navigator.pop(context);
                },
                child: const Text("Update Task"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}