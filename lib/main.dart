import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // for sign in

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TaskApp());
}

class TaskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Authentication(),
    );
  }
}

class Authentication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return TaskHomePage(title: 'Task Homepage');
        } else {
          return LoginPage();
        }
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      print("Login Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign in')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => login(context),
              child: Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskHomePage extends StatefulWidget {
  TaskHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _TaskHomePageState createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  // log out
  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // delete button
  void deleteItem(String itemId) {
    _firestore.collection('task').doc(itemId).delete();
  }

  void itemAdd() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController explanationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("add new task"),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Task Name'),
              ),
              TextField(
                controller: explanationController,
                decoration: InputDecoration(labelText: 'Explanation of Task'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // button
                String name = nameController.text.trim();
                String explanation = explanationController.text.trim();
                _firestore.collection('task').add({
                  'name': name,
                  'explanation': explanation,
                  'completed':
                      false, // add completed for check box. default is false
                });
                Navigator.of(context).pop();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void toggleCompletion(String ItemId, bool isCompleted) {
    // toggle checkbox
    _firestore.collection('task').doc(ItemId).update({
      'completed': !isCompleted,
    });
  }

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // UI to display Firestore data
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        actions: [IconButton(onPressed: logout, icon: Icon(Icons.logout))],
      ),
      body: Center(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('task').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // Loading indicator
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final items = snapshot.data?.docs ?? [];
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index].data() as Map<String, dynamic>;
                String itemId =
                    items[index].id; // used for deletion,update, chck
                bool isCompleted = item['completed'] ?? false;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: isCompleted,
                        onChanged: (value) {
                          toggleCompletion(itemId, isCompleted);
                        },
                      ),
                      title: Text(item['name'] ?? 'Unknown Item'),
                      subtitle: Text(item['explanation'].toString() ?? '0'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          deleteItem(itemId);
                        },
                        child: Text('delete'),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          itemAdd();
        },
        tooltip: 'Add Task',
        child: Icon(Icons.add),
      ),
    );
  }
}
