import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:loginamc/views/loginView.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AsistenciasPorMesView extends StatefulWidget {
  final AppUser profesorId;

  const AsistenciasPorMesView({Key? key, required this.profesorId}) : super(key: key);

  @override
  _AsistenciasPorMesViewState createState() => _AsistenciasPorMesViewState();
}

class _AsistenciasPorMesViewState extends State<AsistenciasPorMesView> {
  List<Map<String, dynamic>> _asistencias = [];
  bool _isLoading = false;
  Map<String, List<Map<String, dynamic>>> _asistenciasPorMes = {};

  @override
  void initState() {
    super.initState();
    _loadAsistencias();
  }

  Future<void> _loadAsistencias() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    List<String>? asistenciasString = prefs.getStringList('asistencias');

    if (asistenciasString != null) {
      _asistencias = asistenciasString.map((asistencia) {
        Map<String, dynamic> asistenciaMap = jsonDecode(asistencia) as Map<String, dynamic>;
        if (asistenciaMap['fecha'] is String) {
          asistenciaMap['fecha'] = DateFormat('dd-MM-yyyy').parse(asistenciaMap['fecha']);
        }
        return asistenciaMap;
      }).toList();

      _agruparAsistenciasPorMes();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _agruparAsistenciasPorMes() {
    _asistenciasPorMes.clear();
    for (var asistencia in _asistencias) {
      String mesKey = DateFormat('MMMM yyyy').format(asistencia['fecha']);
      if (!_asistenciasPorMes.containsKey(mesKey)) {
        _asistenciasPorMes[mesKey] = [];
      }
      _asistenciasPorMes[mesKey]!.add(asistencia);
    }
  }

  Future<void> _fetchAsistenciasFromFirebase() async {
    setState(() {
      _isLoading = true;
    });

    CollectionReference asistenciasRef = FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.profesorId.dni)
        .collection('ASISTENCIAS');

    QuerySnapshot querySnapshot = await asistenciasRef.get();
    _asistencias = querySnapshot.docs.map((doc) {
      Map<String, dynamic> asistencia = doc.data() as Map<String, dynamic>;
      asistencia['id'] = doc.id;
      if (asistencia['fecha'] is Timestamp) {
        asistencia['fecha'] = (asistencia['fecha'] as Timestamp).toDate();
      }
      return asistencia;
    }).toList();

    _agruparAsistenciasPorMes();

    // Guardar asistencias en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    List<String> asistenciasString = _asistencias.map((a) => jsonEncode(a)).toList();
    await prefs.setStringList('asistencias', asistenciasString);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencias por Mes'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _asistenciasPorMes.length,
              itemBuilder: (context, index) {
                String mes = _asistenciasPorMes.keys.elementAt(index);
                List<Map<String, dynamic>> asistenciasDelMes = _asistenciasPorMes[mes]!;
                return ExpansionTile(
                  title: Text(mes),
                  children: asistenciasDelMes.map((asistencia) {
                    return ListTile(
                      title: Text(DateFormat('dd-MM-yyyy').format(asistencia['fecha'])),
                      subtitle: Text('Grado: ${asistencia['seccionId'].substring(1, 2)} Sección: ${asistencia['seccionId'].substring(2, 3)}'),
                      trailing: Text('Total: ${asistencia['totalAlumnas']}'),
                    );
                  }).toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAsistenciasFromFirebase,
        child: Icon(Icons.refresh),
        tooltip: 'Cargar Asistencias',
      ),
    );
  }
}
