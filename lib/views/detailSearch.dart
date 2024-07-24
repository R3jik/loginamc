import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

class DetalleAlumnaView extends StatefulWidget {
  final Map<String, dynamic> alumna;

  DetalleAlumnaView({required this.alumna});

  @override
  _DetalleAlumnaViewState createState() => _DetalleAlumnaViewState();
}

class _DetalleAlumnaViewState extends State<DetalleAlumnaView> {
  List<Map<String, dynamic>> _tardanzas = [];
  List<Map<String, dynamic>> _faltas = [];
  List<Map<String, dynamic>> _justificaciones = [];
  bool _isLoading = true;
  String _grado = '';
  String _seccion = '';

  @override
  void initState() {
    super.initState();
    _fetchAsistencias();
    _fetchGradoSeccion();
    tz.initializeTimeZones();
  }

  Future<void> _fetchAsistencias() async {
  try {
    QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('PROFESORES').get();
    List<Map<String, dynamic>> tardanzas = [];
    List<Map<String, dynamic>> faltas = [];
    List<Map<String, dynamic>> justificaciones = [];

    for (var profesorDoc in profesoresSnapshot.docs) {
      String profesorId = profesorDoc.id;
      String cursoId = profesorDoc['cursoId'] ?? '';
      String cursoNombre = 'Curso desconocido';

      print('Procesando profesor: $profesorId');

      if (cursoId.isNotEmpty) {
        DocumentSnapshot cursoDoc = await FirebaseFirestore.instance
            .collection('CURSOS')
            .doc(cursoId)
            .get();
        if (cursoDoc.exists) {
          cursoNombre = cursoDoc['nombre'] ?? 'Curso desconocido';
        }
      }

      print('Curso del profesor: $cursoNombre');

      QuerySnapshot asistenciasSnapshot = await FirebaseFirestore.instance
          .collection('PROFESORES')
          .doc(profesorId)
          .collection('ASISTENCIAS')
          .get();

      for (var asistenciaDoc in asistenciasSnapshot.docs) {
        String asistenciaId = asistenciaDoc.id;
        String asistenciaFecha = asistenciaDoc['fecha'] ?? '';
        String asistenciaHora = asistenciaDoc['hora'] ?? '';

        print('Procesando asistencia: $asistenciaId');
        print('Fecha de asistencia: $asistenciaFecha');
        print('Hora de asistencia: $asistenciaHora');

        QuerySnapshot detallesSnapshot = await FirebaseFirestore.instance
            .collection('PROFESORES')
            .doc(profesorId)
            .collection('ASISTENCIAS')
            .doc(asistenciaId)
            .collection('DETALLES')
            .get();

        for (var detalleDoc in detallesSnapshot.docs) {
          var data = detalleDoc.data() as Map<String, dynamic>;
          if (data['nombre'] == widget.alumna['nombre'] &&
              data['apellido_paterno'] == widget.alumna['apellido_paterno'] &&
              data['apellido_materno'] == widget.alumna['apellido_materno']) {
            
            data['id'] = detalleDoc.id;
            data['profesorId'] = profesorId;
            data['asistenciaId'] = asistenciaId;
            data['cursoNombre'] = cursoNombre;

            // Usar la fecha y hora de la asistencia
            if (asistenciaFecha.isNotEmpty && asistenciaHora.isNotEmpty) {
              data['fecha'] = asistenciaFecha;
              data['hora'] = asistenciaHora;
              
              
               // Parsear la fecha y hora correctamente
              try {
                // Asumiendo que la fecha está en formato dd-MM-yyyy
                List<String> fechaParts = asistenciaFecha.split('-');
                if (fechaParts.length == 3) {
                  String fechaFormatted = '${fechaParts[2]}-${fechaParts[1]}-${fechaParts[0]}'; // Convertir a yyyy-MM-dd
                  DateTime fechaHora = DateTime.parse('$fechaFormatted $asistenciaHora');
                  
                  // Ajustar a hora de Lima (UTC-5)
                  fechaHora = fechaHora.subtract(Duration(hours: 5));
                  data['fechaHora'] = DateFormat('dd-MM-yyyy HH:mm').format(fechaHora);
                } else {
                  data['fechaHora'] = 'Formato de fecha inválido';
                }
              } catch (e) {
                print('Error al parsear fecha y hora: $e');
                data['fechaHora'] = 'Error en fecha/hora';
              }
            } else {
              data['fechaHora'] = 'Fecha/hora no disponible';
            }

            print('Detalle encontrado para alumna:');
            print('Nombre: ${data['nombre']} ${data['apellido_paterno']} ${data['apellido_materno']}');
            print('Estado: ${data['estado']}');
            print('Fecha y hora: ${data['fechaHora']}');

            if (data['estado'] == 'tardanza') {
              tardanzas.add(data);
            } else if (data['estado'] == 'falta') {
              faltas.add(data);
            } else if (data['estado'] == 'justificacion') {
              justificaciones.add(data);
            }
          }
        }
      }
    }

    setState(() {
      _tardanzas = tardanzas;
      _faltas = faltas;
      _justificaciones = justificaciones;
      _isLoading = false;
    });

    print('Tardanzas encontradas: ${_tardanzas.length}');
    print('Faltas encontradas: ${_faltas.length}');
    print('Justificaciones encontradas: ${_justificaciones.length}');

  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('Error fetching asistencias: $e');
  }
}

  Future<void> _fetchGradoSeccion() async {
    try {
      DocumentSnapshot alumnaDoc = await FirebaseFirestore.instance
          .collection('ALUMNAS')
          .doc(widget.alumna['id'])
          .get();

      if (alumnaDoc.exists) {
        var data = alumnaDoc.data() as Map<String, dynamic>;
        String seccionId = data['seccionId'] ?? '';
        if (seccionId.isNotEmpty) {
          // Separar grado y sección
          _grado = seccionId.substring(0, seccionId.length - 1);
          _seccion = seccionId.substring(seccionId.length - 1);
          setState(() {});
        }
      }
    } catch (e) {
      print('Error fetching grado y seccion: $e');
    }
  }

  Future<void> _justificarAsistencia(String alumnoId, String profesorId, String asistenciaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('PROFESORES')
          .doc(profesorId)
          .collection('ASISTENCIAS')
          .doc(asistenciaId)
          .collection('DETALLES')
          .doc(alumnoId)
          .update({
        'estado': 'justificacion',
      });

      print('Asistencia justificada con éxito para el alumno con ID: $alumnoId');
      _fetchAsistencias();
    } catch (e) {
      print('Error justificando asistencia: $e');
    }
  }

  Future<void> _cambiarEstadoAsistencia(String profesorId, String asistenciaId, String detalleId) async {
    try {
      await FirebaseFirestore.instance
          .collection('PROFESORES')
          .doc(profesorId)
          .collection('ASISTENCIAS')
          .doc(asistenciaId)
          .collection('DETALLES')
          .doc(detalleId)
          .update({
        'estado': 'asistencia',
      });

      _fetchAsistencias();
    } catch (e) {
      print('Error changing asistencia state: $e');
    }
  }

  Future<void> _eliminarTodasAsistencias() async {
    try {
      QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('PROFESORES').get();

      for (var profesorDoc in profesoresSnapshot.docs) {
        String profesorId = profesorDoc.id;
        QuerySnapshot asistenciasSnapshot = await FirebaseFirestore.instance
            .collection('PROFESORES')
            .doc(profesorId)
            .collection('ASISTENCIAS')
            .get();

        for (var asistenciaDoc in asistenciasSnapshot.docs) {
          String asistenciaId = asistenciaDoc.id;
          
          QuerySnapshot detallesSnapshot = await FirebaseFirestore.instance
              .collection('PROFESORES')
              .doc(profesorId)
              .collection('ASISTENCIAS')
              .doc(asistenciaId)
              .collection('DETALLES')
              .get();

          for (var detalleDoc in detallesSnapshot.docs) {
            var data = detalleDoc.data() as Map<String, dynamic>;
            if (data['nombre'] == widget.alumna['nombre'] &&
                data['apellido_paterno'] == widget.alumna['apellido_paterno'] &&
                data['apellido_materno'] == widget.alumna['apellido_materno']) {
              await detalleDoc.reference.update({
                'estado': 'asistencia',
              });
            }
          }
        }
      }

      setState(() {
        _tardanzas.clear();
        _faltas.clear();
        _justificaciones.clear();
      });

      print('Todas las asistencias de la alumna han sido eliminadas');
    } catch (e) {
      print('Error eliminando todas las asistencias: $e');
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Detalle de Alumna'),
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.alumna['nombre']} ${widget.alumna['apellido_paterno']} ${widget.alumna['apellido_materno']}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Grado: $_grado'),
                  Text('Sección: $_seccion'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _eliminarTodasAsistencias,
                    child: Text('Eliminar todas las asistencias'),
                  ),
                  SizedBox(height: 16),
                  _buildAsistenciasList('Tardanzas', _tardanzas),
                  _buildAsistenciasList('Faltas', _faltas),
                  _buildAsistenciasList('Justificaciones', _justificaciones),
                ],
              ),
            ),
          ),
  );
}

Widget _buildAsistenciasList(String title, List<Map<String, dynamic>> asistencias) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      asistencias.isEmpty
          ? Text('No hay $title registradas')
          : Column(
              children: asistencias.map((asistencia) {
                return Card(
                  child: ListTile(
                    title: Text('${asistencia['cursoNombre']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha : ${asistencia['fechaHora']}'),
                        if (title == 'Justificaciones' && asistencia['fechaHoraJustificacion'] != null)
                          Text('Justificado el: ${asistencia['fechaHoraJustificacion']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != 'Justificaciones')
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () => _justificarAsistencia(
                              asistencia['id'],
                              asistencia['profesorId'],
                              asistencia['asistenciaId'],
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _cambiarEstadoAsistencia(
                            asistencia['profesorId'],
                            asistencia['asistenciaId'],
                            asistencia['id'],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      SizedBox(height: 16),
    ],
  );
}
}