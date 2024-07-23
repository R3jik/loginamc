import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetalleAlumnaView extends StatefulWidget {
  final Map<String, dynamic> alumna;
  DetalleAlumnaView({required this.alumna,});

  @override
  _DetalleAlumnaViewState createState() => _DetalleAlumnaViewState();
}

class _DetalleAlumnaViewState extends State<DetalleAlumnaView> {
  List<Map<String, dynamic>> _tardanzas = [];
  List<Map<String, dynamic>> _faltas = [];
  List<Map<String, dynamic>> _justificaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAsistencias();
  }

  Future<void> _fetchAsistencias() async {
    try {
      // Obtener todos los documentos en la colección PROFESORES
      QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('PROFESORES').get();

      List<Map<String, dynamic>> tardanzas = [];
      List<Map<String, dynamic>> faltas = [];
      List<Map<String, dynamic>> justificaciones = [];

      for (var profesorDoc in profesoresSnapshot.docs) {
        String profesorId = profesorDoc.id;

        // Obtener todas las fechas de asistencias para el profesor actual
        QuerySnapshot fechasSnapshot = await FirebaseFirestore.instance
            .collection('PROFESORES')
            .doc(profesorId)
            .collection('ASISTENCIAS')
            .get();

        for (var fechaDoc in fechasSnapshot.docs) {
          String fechaId = fechaDoc.id;

          // Obtener el documento de ASISTENCIAS para la fecha actual
          DocumentSnapshot asistenciaDoc = await FirebaseFirestore.instance
              .collection('PROFESORES')
              .doc(profesorId)
              .collection('ASISTENCIAS')
              .doc(fechaId)
              .get();

           // Obtener la fecha y hora real del documento de asistencia
            DateTime? fechaHoraUTC;
            if (asistenciaDoc['fecha'] is Timestamp) {
              fechaHoraUTC = (asistenciaDoc['fecha'] as Timestamp).toDate();
            } else if (asistenciaDoc['fecha'] is String) {
              fechaHoraUTC = DateTime.tryParse(asistenciaDoc['fecha']);
            }

          // Ajustar a la zona horaria de Lima (UTC-5)
            DateTime? fechaHoraLima;
            if (fechaHoraUTC != null) {
              fechaHoraLima = fechaHoraUTC.subtract(Duration(hours: 5));
            }
             // Si no se pudo obtener la fecha y hora, usa el ID como fallback
            String fechaHoraStr = fechaHoraLima != null 
                ? DateFormat('dd-MM-yyyy HH:mm').format(fechaHoraLima)
                : fechaId;
                  
          // Obtener el cursoId del documento de ASISTENCIAS
                String cursoId = asistenciaDoc['cursoId'] ?? '';
                String cursoNombre = 'Curso desconocido';

          if (cursoId.isNotEmpty) {
            DocumentSnapshot cursoDoc = await FirebaseFirestore.instance
                .collection('CURSOS')
                .doc(cursoId)
                .get();
            cursoNombre = cursoDoc['nombre'] ?? 'Curso desconocido';
          }

          // Obtener todos los documentos en DETALLES para la fecha actual
          QuerySnapshot detallesSnapshot = await FirebaseFirestore.instance
              .collection('PROFESORES')
              .doc(profesorId)
              .collection('ASISTENCIAS')
              .doc(fechaId)
              .collection('DETALLES')
              .get();

          // Filtrar los documentos por el ID de la alumna
          var detallesFiltrados = detallesSnapshot.docs.where((doc) {
            return doc.id == widget.alumna['id'];
          }).toList();

          for (var detalleDoc in detallesFiltrados) {
            var data = detalleDoc.data() as Map<String, dynamic>;
            data['id'] = detalleDoc.id;
            data['fecha'] = fechaHoraStr; // Usa la fecha formateada aquí
            data['cursoNombre'] = cursoNombre;

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

      setState(() {
        _tardanzas = tardanzas;
        _faltas = faltas;
        _justificaciones = justificaciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching asistencias: $e');
    }
  }

  Future<void> _justificarAsistencia(String alumnoId, String fecha, String estado) async {
  try {
    // Referencia a la colección de ASISTENCIAS del profesor
    final asistenciasRef = FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc()
        .collection('ASISTENCIAS');

    // Buscar en todas las asistencias del profesor
    final QuerySnapshot asistenciasSnapshot = await asistenciasRef.get();

    // Variable para almacenar el documento de asistencia correcto
    DocumentSnapshot? asistenciaCorrecta;

    // Iterar sobre todas las asistencias
    for (var doc in asistenciasSnapshot.docs) {
      // Buscar en la colección DETALLES de cada asistencia
      final detalleDoc = await doc.reference
          .collection('DETALLES')
          .doc(alumnoId)
          .get();

      if (detalleDoc.exists) {
        asistenciaCorrecta = doc;
        break;
      }
    }

    if (asistenciaCorrecta == null) {
      print('No se encontró un documento de asistencia para el alumno con ID: $alumnoId');
      return;
    }

    // Actualizar el documento de DETALLES
    await asistenciaCorrecta.reference
        .collection('DETALLES')
        .doc(alumnoId)
        .set({
      'estado': 'justificacion',
      'fecha_justificacion': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    print('Asistencia justificada con éxito para el alumno con ID: $alumnoId');
    _fetchAsistencias();
  } catch (e) {
    print('Error justificando asistencia: $e');
  }
}

  Future<void> _cambiarEstadoAsistencia(String alumnoId, String nuevoEstado, String fecha, String cursoNombre) async {
  try {
    print('Intentando cambiar estado para alumno con ID: $alumnoId en la fecha: $fecha, curso: $cursoNombre');

    // Convertir la fecha string a DateTime
    DateTime fechaDateTime = DateFormat('dd-MM-yyyy HH:mm').parse(fecha);
    // Convertir a Timestamp de Firestore
    Timestamp fechaTimestamp = Timestamp.fromDate(fechaDateTime);

    QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('PROFESORES').get();
    print('Número de profesores encontrados: ${profesoresSnapshot.docs.length}');

    for (var profesorDoc in profesoresSnapshot.docs) {
      String profesorId = profesorDoc.id;
      print('Buscando en profesor: $profesorId');

      QuerySnapshot asistenciasSnapshot = await FirebaseFirestore.instance
          .collection('PROFESORES')
          .doc(profesorId)
          .collection('ASISTENCIAS')
          .get();

      print('Número de asistencias encontradas para el profesor: ${asistenciasSnapshot.docs.length}');

      for (var asistenciaDoc in asistenciasSnapshot.docs) {
        print('Revisando asistencia: ${asistenciaDoc.id}');
        print('Fecha de la asistencia: ${asistenciaDoc['fecha']}');
        
        // Verificar si la fecha coincide
        if (asistenciaDoc['fecha'] == fechaTimestamp) {
          print('Fecha coincide');
          
          // Verificar si el curso coincide
          DocumentSnapshot cursoDoc = await FirebaseFirestore.instance
              .collection('CURSOS')
              .doc(asistenciaDoc['cursoId'])
              .get();
          
          print('Curso de la asistencia: ${cursoDoc['nombre']}');
          
          if (cursoDoc['nombre'] == cursoNombre) {
            print('Curso coincide');
            
            // Buscar el detalle del alumno en esta asistencia
            DocumentReference detalleRef = asistenciaDoc.reference
                .collection('DETALLES')
                .doc(alumnoId);

            DocumentSnapshot detalleDoc = await detalleRef.get();

            if (detalleDoc.exists) {
              String estadoActual = detalleDoc['estado'];
              print('Estado actual del alumno: $estadoActual');

              if (estadoActual != nuevoEstado) {
                await detalleRef.update({
                  'estado': nuevoEstado,
                  'fecha_actualizacion': FieldValue.serverTimestamp(),
                });
                print('Estado de asistencia cambiado con éxito de $estadoActual a $nuevoEstado');
                
                await _fetchAsistencias();
                return;
              } else {
                print('El estado actual ya es $nuevoEstado, no se requiere actualización');
                return;
              }
            } else {
              print('No se encontró el detalle para el alumno');
            }
          } else {
            print('El curso no coincide');
          }
        } else {
          print('La fecha no coincide');
        }
      }
    }

    print('No se encontró la asistencia específica para actualizar');
  } catch (e) {
    print('Error cambiando estado de asistencia: $e');
  }
}



  Future<void> _eliminarTodasAsistencias() async {
    try {
      // Obtener todos los documentos en la colección PROFESORES
      QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('PROFESORES').get();

      for (var profesorDoc in profesoresSnapshot.docs) {
        String profesorId = profesorDoc.id;

        // Obtener todas las fechas de asistencias para el profesor actual
        QuerySnapshot fechasSnapshot = await FirebaseFirestore.instance
            .collection('PROFESORES')
            .doc(profesorId)
            .collection('ASISTENCIAS')
            .get();

        for (var fechaDoc in fechasSnapshot.docs) {
          String fechaId = fechaDoc.id;

          // Obtener todos los documentos en DETALLES para la fecha actual
          QuerySnapshot detallesSnapshot = await FirebaseFirestore.instance
              .collection('PROFESORES')
              .doc(profesorId)
              .collection('ASISTENCIAS')
              .doc(fechaId)
              .collection('DETALLES')
              .get();

          // Filtrar los documentos por el ID de la alumna y eliminarlos
          var detallesFiltrados = detallesSnapshot.docs.where((doc) {
            return doc.id == widget.alumna['id'];
          }).toList();

          for (var detalleDoc in detallesFiltrados) {
            await FirebaseFirestore.instance
                .collection('PROFESORES')
                .doc(profesorId)
                .collection('ASISTENCIAS')
                .doc(fechaId)
                .collection('DETALLES')
                .doc(detalleDoc.id)
                .set({
                  'estado': 'asistencia',
                  'fecha_asistencia': DateTime.now().toIso8601String(),
                }, SetOptions(merge: true));
          }
        }
      }

      // Actualizar la lista local después de eliminar todas las asistencias
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
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 20),

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
                                        padding: EdgeInsets.all(5),
                                        width: 400,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFD3E5FF),
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
                                        padding: EdgeInsets.all(5),
                                        width: 400,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFD3E5FF),
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
                                          padding: EdgeInsets.all(5),
                                          width: 400,
                                          decoration: BoxDecoration(
                                            color: Color(0xFFD3E5FF),
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
                            width: 20,
                          ),
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
                            width: 180,
                            height: 180,
                            child: const Icon(
                              Icons.person_3,
                              color: Colors.blue,
                              size: 150,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  
                    const Text('ESTADISTICAS TOTALES',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Expanded(
                      child: ListView(
                        children: [
                          const Text('Tardanzas',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
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
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _tardanzas.length,
                              itemBuilder: (context, index) {
                                final tardanza = _tardanzas[index];
                                return ListTile(
                                  title: Text('Fecha: ${tardanza['fecha']} \nCurso: ${tardanza['cursoNombre']} \nEstado: ${tardanza['estado']}'),
                                  textColor: Colors.white,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: tardanza['estado'] == 'justificacion',
                                        onChanged: (value) {
                                          if (value) {
                                            _justificarAsistencia(tardanza['id'], tardanza['fecha'], 'tardanza');
                                          }
                                        },
                                      ),
                                      IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _cambiarEstadoAsistencia(tardanza['id'], 'asistencia', tardanza['fechaSolo'], tardanza['cursoNombre']);
                                      },
                                    ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Faltas',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
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
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _faltas.length,
                              itemBuilder: (context, index) {
                                final falta = _faltas[index];
                                return ListTile(
                                  title: Text('Fecha: ${falta['fecha']} \nCurso: ${falta['cursoNombre']} \nEstado: ${falta['estado']}'),
                                  textColor: Colors.white,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: falta['estado'] == 'justificacion',
                                        onChanged: (value) {
                                          if (value) {
                                            _justificarAsistencia(falta['id'], falta['fecha'], 'falta');
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _cambiarEstadoAsistencia(falta['id'], 'asistencia', falta['fecha'], falta['cursoNombre']);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Justificaciones',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
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
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _justificaciones.length,
                              itemBuilder: (context, index) {
                                final justificacion = _justificaciones[index];
                                return ListTile(
                                  title: Text('Fecha: ${justificacion['fecha']} \nCurso: ${justificacion['cursoNombre']} \nEstado: ${justificacion['estado']}'),
                                  textColor: Colors.white,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: justificacion['estado'] == 'justificacion',
                                        onChanged: (value) {
                                          if (value) {
                                            _justificarAsistencia(justificacion['id'], justificacion['fecha'], 'justificacion');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: _eliminarTodasAsistencias,
                        child: Text('Eliminar todas las asistencias'),
                      ),
                    ),
                    SizedBox(height: 20,),
                  ],
                ),
              ),
      ),
    );
  }
}
