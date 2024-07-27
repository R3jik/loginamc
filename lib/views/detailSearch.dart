import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class DetalleAlumnaView extends StatefulWidget {
  final Map<String, dynamic> alumna;

  DetalleAlumnaView({required this.alumna});

  @override
  _DetalleAlumnaViewState createState() => _DetalleAlumnaViewState();
    Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);
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
                  fechaHora = fechaHora.subtract(Duration(hours: 0));
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
      if (seccionId.isNotEmpty && seccionId.length == 3) {
        // Separar grado y sección
        _grado = seccionId.substring(1, 2); // Extraer solo el número del grado
        _seccion = seccionId.substring(2); // Extraer la última letra como sección
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
    backgroundColor: const Color(0XFF071E30),
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                    Container(
                      alignment: const Alignment(0, 0),
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0XFF001220),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            spreadRadius: 3,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        "DETALLES DE ASISTENCIA",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),

                    //AQUI VA EL CONTAINER
                    Container(
                      height: 200,
                      width: 500,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0XFF001220),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.16),
                                    spreadRadius: 3,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        width: 400,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD3E5FF),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.16),
                                              spreadRadius: 3,
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Text(
                                            '${widget.alumna['nombre']} ',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10, top: 10),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        width: 400,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD3E5FF),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.16),
                                              spreadRadius: 3,
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Text(
                                            '${widget.alumna['apellido_paterno']} ',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          width: 400,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD3E5FF),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.16),
                                                spreadRadius: 3,
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 10),
                                            child: Text(
                                              '${widget.alumna['apellido_materno']}',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0XFF001220),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.16),
                                      spreadRadius: 3,
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                width: 200,
                                height: 200,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person_3,
                                      color: Colors.blue,
                                      size: 150,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text("GRADO: $_grado", style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold,),),
                                      const SizedBox(width: 10,),
                                      Text("SECCION: $_seccion", style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold,),),
                                    ],
                                    ),
                                  ],
                                ),
                                
                              ),
                              
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _eliminarTodasAsistencias,
                        child: Text('Eliminar todas las asistencias'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                    const Text('ESTADISTICAS TOTALES',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  // Text(
                  //   '${widget.alumna['nombre']} ${widget.alumna['apellido_paterno']} ${widget.alumna['apellido_materno']}',
                  //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  // ),
                  // SizedBox(height: 8),
                  // Text('Grado: $_grado'),
                  // Text('Sección: $_seccion'),
                  // SizedBox(height: 16),
                  
                  const SizedBox(height: 10),
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
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      const SizedBox(height: 8),
      asistencias.isEmpty
          ? Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Text('No hay $title registradas',style: const TextStyle(
                              fontSize: 17,                              
                              color: Colors.white)),
          )
          : Column(
              children: asistencias.map((asistencia) {
                return Card(
                  color: const Color(0XFF001220),
                  child: ListTile(
                    title: Text('${asistencia['cursoNombre']}',style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha : ${asistencia['fechaHora']}', style: TextStyle(color: Colors.white),),
                        if (title == 'Justificaciones' && asistencia['fechaHoraJustificacion'] != null)
                          Text('Justificado el: ${asistencia['fechaHoraJustificacion']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != 'Justificaciones')
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.greenAccent,),
                            onPressed: () => _justificarAsistencia(
                              asistencia['id'],
                              asistencia['profesorId'],
                              asistencia['asistenciaId'],
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
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
      const SizedBox(height: 16),
    ],
  );
}
}