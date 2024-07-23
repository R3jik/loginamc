import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:loginamc/views/loginView.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:loginamc/helpers/timezone_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:loginamc/widgets/icono.dart';
    


class ProfesorProfile extends StatefulWidget {
  final AppUser profesorId; //Cambiar el tipo de dato User a AppUser e importar la pagina loginView.dart porque ahi esta la clase creada

  const ProfesorProfile({super.key, required this.profesorId,});

  @override
  _ProfesorProfileState createState() => _ProfesorProfileState();
}

class _ProfesorProfileState extends State<ProfesorProfile> {
  Map<String, dynamic>? _profesorData;
  String _currentDate = '';
  String cursoId = '';
  List<dynamic> _seccionData = [];
  Map<String, dynamic>? _cursoData;

  @override
  void initState() {
    super.initState();
    TimeZoneHelper.initializeTimeZones();
    _currentDate = DateFormat('dd-MM-yyyy').format(TimeZoneHelper.nowInLima());
    _fetchProfesorData();
  }

  void _fetchProfesorData() async {
    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId.dni)
        .get();
    QuerySnapshot  seccionesDoc = await FirebaseFirestore.instance
      .collection('PROFESORES')
      .doc(widget.profesorId.dni)
      .collection('SECCIONES')
      .get();
    List<String> idsSecciones = seccionesDoc.docs.map((doc) => doc.id).toList();
    setState(() {
      _profesorData = profesorDoc.data() as Map<String, dynamic>;
      cursoId = profesorDoc['cursoId'];
      _seccionData = idsSecciones;
    });
    DocumentSnapshot<Map<String, dynamic>> nombreCurso = await FirebaseFirestore
        .instance
        .collection('CURSOS')
        .doc(cursoId)
        .get();
    setState(() {
      _cursoData = nombreCurso.data();
    });
  }

  Stream<List<Map<String, dynamic>>> _fetchAsistencias() async* {
    List<Map<String, dynamic>> asistencias = [];
    for (var seccionId in _seccionData) {
      QuerySnapshot alumnasSnapshot = await FirebaseFirestore.instance
          .collection('ALUMNAS')
          .where('seccionId', isEqualTo: seccionId)
          .get();

      Map<String, dynamic> asistenciaPorSalon = {
        'seccionId': seccionId,
        'totalAlumnas': 0,
        'totalAsistentes': 0,
        'totalTardanzas': 0,
        'totalFaltas': 0,
      };

      for (var alumnaDoc in alumnasSnapshot.docs) {
        QuerySnapshot asistenciaSnapshot = await alumnaDoc.reference
            .collection('asistencia')
            .where(FieldPath.documentId, isEqualTo: '$_currentDate-$cursoId')
            .get();

        if (asistenciaSnapshot.docs.isNotEmpty) {
          for (var doc in asistenciaSnapshot.docs) {
            asistenciaPorSalon['totalAlumnas'] += 1;
            if (doc['estado'] == 'asistencia') {
              asistenciaPorSalon['totalAsistentes'] += 1;
            } else if (doc['estado'] == 'tardanza') {
              asistenciaPorSalon['totalTardanzas'] += 1;
            } else if (doc['estado'] == 'falta') {
              asistenciaPorSalon['totalFaltas'] += 1;
            }
          }
          asistencias.add(asistenciaPorSalon);
        }
      }
    }
    yield asistencias;
  }

  void _deleteAsistencia(String alumnaId, String asistenciaId) async {
    await FirebaseFirestore.instance
        .collection('ALUMNAS')
        .doc(alumnaId)
        .collection('asistencia')
        .doc(asistenciaId)
        .delete();
    setState(() {});
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text('Reporte de Asistencias del Día $_currentDate _ $cursoId _}'),
        ),
      ),
    );

    // Agregar contenido del PDF

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'reporte_asistencias_$_currentDate _ $cursoId.pdf');
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Asistencias'];
    sheetObject.appendRow([
      const TextCellValue('Fecha'),
      const TextCellValue('Grado'),
      const TextCellValue('Sección'),
      const TextCellValue('Total Alumnas'),
      const TextCellValue('Total Asistentes'),
      const TextCellValue('Total Tardanzas'),
      const TextCellValue('Total Faltas'),
    ]);

    await for (var asistencia in _fetchAsistencias()) {
      for (var item in asistencia) {
        sheetObject.appendRow([
          item['fecha'],
          item[const TextCellValue('grado')],
          item[const TextCellValue('seccion')],
          item[const TextCellValue('totalAlumnas')],
          item[const TextCellValue('totalAsistentes')],
          item[const TextCellValue('totalTardanzas')],
          item[const TextCellValue('totalFaltas')],
        ]);
      }
    }

    Directory directory = await getApplicationDocumentsDirectory();
    String outputFile = "${directory.path}/reporte_asistencias.xlsx";
    File(outputFile)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.save()!);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte exportado: $outputFile')));
    Share.shareXFiles([XFile(outputFile)], text: 'Reporte de Asistencias');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    Color whiteColor = const Color(0XFFF6F6F6);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);
    Color fondoDatos = const Color(0XFF001739);
    TextStyle textoDatosProf = TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: whiteText);

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                color: fondo2,
              )),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: screenWidth,
                    height: screenHeight*0.3,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: fondo1,
                      borderRadius: const BorderRadius.all(Radius.circular(20))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Text('MI PERFIL', style: textoDatosProf,)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nombre:',
                                    style: textoDatosProf,
                                ),
                                Container(
                                  width: screenWidth*0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['nombre']?? ''}',style: textoDatosProf,),
                                ),
                                Text(
                                  'Apellido Paterno:',
                                  style: textoDatosProf,
                                ),
                                Container(
                                  width: screenWidth*0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['apellido_paterno']?? ''}',style: textoDatosProf,),
                                ),
                                Text(
                                  'Apellido Materno:',
                                  style: textoDatosProf,
                                ),
                                Container(
                                  width: screenWidth*0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['apellido_materno']?? ''}',style: textoDatosProf,),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                IconoPerfil(),
                                const SizedBox(height: 20,),
                                Text('${_cursoData?['nombre'] ?? ''}',
                                  style: textoDatosProf,
                                  ),
                              ],
                            ),
                            
                          ],
                        ),
                        
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Container(
                    height: screenHeight*0.45,
                    width: screenWidth,
                    color: fondo2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistencias del Día',
                          style: textoDatosProf,
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _fetchAsistencias(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}',style: textoDatosProf,));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(child: Text('No hay asistencias para mostrar.',style: textoDatosProf,));
                          }
                          
                          // Map para almacenar las asistencias agrupadas por seccionId
                          Map<String, Map<String, dynamic>> secciones = {};
                        
                          // Agrupar asistencias por seccionId
                          snapshot.data!.forEach((asistencia) {
                            String seccionId = asistencia['seccionId'];
                            if (!secciones.containsKey(seccionId)) {
                  secciones[seccionId] = asistencia;
                            }
                          });
                        
                          return Column(
                            children: secciones.values.map((asistencia) {
                  return Card(
                    color: fondo1,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            'Grado: ${asistencia['seccionId'].substring(1, 2)} Sección: ${asistencia['seccionId'].substring(2, 3)}',
                            style: textoDatosProf,
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fecha',style: textoDatosProf),
                                  Text(_currentDate,style: textoDatosProf,),
                                ],
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.group,color: whiteColor,),
                                      Text('${asistencia['totalAlumnas']}', style: textoDatosProf,),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green,),
                                      Text('${asistencia['totalAsistentes']}',style: textoDatosProf,),
                                      const Icon(Icons.remove_circle, color: Colors.red,),
                                      Text('${asistencia['totalFaltas']}',style: textoDatosProf,),
                                      const Icon(Icons.access_time_filled, color: Colors.yellow,),
                                      Text('${asistencia['totalTardanzas']}',style: textoDatosProf,),
                                      
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () => _deleteAsistencia(asistencia['alumnaId'], asistencia['id']),
                            icon: const Icon(Icons.delete, color: Colors.red,),
                          ),
                        ),
                        ButtonBar(
                          children: [
                            ElevatedButton(
                              onPressed: _exportToPDF,
                              child: Text('Exportar a PDF'),
                            ),
                            ElevatedButton(
                              onPressed: _exportToExcel,
                              child: Text('Exportar a Excel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                            }).toList(),
                          );
                        },
                          ),
                        ),
                        
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
