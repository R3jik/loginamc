import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:loginamc/views/loginView.dart';
import 'package:http/http.dart' as http;

class AdminPanel extends StatefulWidget {
  final AppUser user;

  const AdminPanel({required this.user});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
  }

  void _subscribeToTopic() async {
    try {
      await _messaging.subscribeToTopic('all');
      print('Subscribed to topic "all"');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bloque de Usuarios Conectados
            Text('Usuarios Conectados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('USUARIOS').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var user = snapshot.data!.docs[index];
                    bool isConnected = user['isConnected'] ?? false;
                    return ListTile(
                      title: Text(user['email']),
                      trailing: Icon(
                        isConnected ? Icons.circle : Icons.circle_outlined,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 20),

            // Bloque de Añadir/Quitar Usuarios
            Text('Añadir/Quitar Usuarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addUser,
                  child: Text('Añadir Usuario'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _deleteUser,
                  child: Text('Quitar Usuario'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Bloque de Registro de Cambios (Opcional)
            Text('Registro de Cambios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('LONGS').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var log = snapshot.data!.docs[index];
                    var timestamp = log['timestamp'];
                    // String formattedDate = timestamp != null ? (timestamp as Timestamp).toDate().toString() : 'No date';
                    return ListTile(
                      title: Text(log['action']),
                      // subtitle: Text(formattedDate),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addUser() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _firestore.collection('USUARIOS').doc(userCredential.user!.uid).set({
        'email': _emailController.text,
        'isConnected': false,
      });
      _emailController.clear();
      _passwordController.clear();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _deleteUser() async {
    try {
      var user = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _firestore.collection('USUARIOS').doc(user.user!.uid).delete();
      await user.user!.delete();
      _emailController.clear();
      _passwordController.clear();
    } catch (e) {
      print("Error: $e");
    }
  }
}
