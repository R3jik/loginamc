import 'dart:async';

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
  bool isConnected = true;
  Timer? _inactivityTimer;
  static const inactivityTimeout = Duration(seconds: 20); // Adjust as needed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateConnectionStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      _updateConnectionStatus(true);
      _startInactivityTimer(); // Restart timer on app resume
    }
  }

  _startInactivityTimer() {
  print('Starting inactivity timer');
  _inactivityTimer = Timer(inactivityTimeout, () {
    print('Inactivity timeout reached');
    setState(() {
      isConnected = false;
    });
    _updateConnectionStatus(false);
  });
}


  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
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
    // Add GestureDetector or other interaction listeners to reset the timer
    return GestureDetector(
      onTap: _resetInactivityTimer,
      child: widget.child,
    );
  }
}
