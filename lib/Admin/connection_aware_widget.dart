import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionAwareWidget extends StatefulWidget {
  final Widget child;

  const ConnectionAwareWidget({Key? key, required this.child}) : super(key: key);

  @override
  _ConnectionAwareWidgetState createState() => _ConnectionAwareWidgetState();
}

class _ConnectionAwareWidgetState extends State<ConnectionAwareWidget> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateConnectionStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateConnectionStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateConnectionStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      _updateConnectionStatus(true);
    }
  }

  Future<void> _updateConnectionStatus(bool isConnected) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('USUARIOS')
          .doc(user.uid)
          .update({'isConnected': isConnected});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}