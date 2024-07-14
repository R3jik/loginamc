import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:loginamc/helpers/timezone_helper.dart';
import 'package:timezone/data/latest.dart';
import 'package:share_plus/share_plus.dart';

class ProfesorProfile extends StatefulWidget {
  final String profesorId;
  final String seccionId;

  ProfesorProfile({required this.profesorId, required this.seccionId});

  @override
  _ProfesorProfileState createState() => _ProfesorProfileState();
}

class _ProfesorProfileState extends State<ProfesorProfile> {
  Map<String, dynamic>? _profesorData;
  List<Map<String, dynamic>> _asistencias = [];
  String _currentDate = '';
  String cursoId = '';
  Map<String, dynamic>? _cursoData;

  @override
  void initState() {
    super.initState();
    TimeZoneHelper.initializeTimeZones();
    _currentDate = DateFormat('dd-MM-yyyy').format(TimeZoneHelper.nowInLima());
    _fetchAsistencias();
    _fetchProfesorData();
  }

  void _fetchProfesorData() async {
    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId)
        .get();
    setState(() {
      _profesorData = profesorDoc.data() as Map<String, dynamic>;
      cursoId = profesorDoc['cursoId'];
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

  void _fetchAsistencias() async {
    QuerySnapshot alumnasSnapshot = await FirebaseFirestore.instance
        .collection('ALUMNAS')
        .where('seccionId', isEqualTo: widget.seccionId)
        .get();

    Map<String, dynamic> asistenciaPorSalon = {
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
    }

    setState(() {
      _asistencias = [
        {
          'grado': widget.seccionId.substring(1, 2),
          'seccion': widget.seccionId.substring(2),
          ...asistenciaPorSalon
        }
      ];
    });
  }

  void _deleteAsistencia(String alumnaId, String asistenciaId) async {
    await FirebaseFirestore.instance
        .collection('ALUMNAS')
        .doc(alumnaId)
        .collection('asistencia')
        .doc(asistenciaId)
        .delete();
    setState(() {
      _asistencias
          .removeWhere((asistencia) => asistencia['id'] == asistenciaId);
    });
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text('Reporte de Asistencias del Día $_currentDate'),
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

    for (var asistencia in _asistencias) {
      sheetObject.appendRow([
        asistencia['fecha'],
        asistencia[const TextCellValue('grado')],
        asistencia[const TextCellValue('seccion')],
        asistencia[const TextCellValue('totalAlumnas')],
        asistencia[const TextCellValue('totalAsistentes')],
        asistencia[const TextCellValue('totalTardanzas')],
        asistencia[const TextCellValue('totalFaltas')],
        /*asistencia['seccion'],
        asistencia['totalAlumnas'],
        asistencia['totalAsistentes'],
        asistencia['totalTardanzas'],
        asistencia['totalFaltas']*/
      ]);
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil del Profesor'),
        backgroundColor: Colors.blue,
      ),
      body: _profesorData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: screenWidth,
                    padding: EdgeInsets.all(16.0),
                    color: Colors.blue[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nombre: ${_profesorData!['nombre']}',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Apellido Paterno: ${_profesorData!['apellido_paterno']}',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Apellido Materno: ${_profesorData!['apellido_materno']}',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Curso: ${_cursoData?['nombre']}',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    padding: EdgeInsets.all(16.0),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistencias del Día',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        ..._asistencias.map((asistencia) {
                          return Card(
                            child: ListTile(
                              title: Text(
                                'Grado: ${asistencia['grado']} Sección: ${asistencia['seccion']}',
                                style: TextStyle(fontSize: 18),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Total Alumnas: ${asistencia['totalAlumnas']}'),
                                  Text(
                                      'Asistentes: ${asistencia['totalAsistentes']}'),
                                  Text(
                                      'Tardanzas: ${asistencia['totalTardanzas']}'),
                                  Text('Faltas: ${asistencia['totalFaltas']}'),
                                ],
                              ),
                              trailing: IconButton(
                                onPressed:() => _deleteAsistencia(asistencia['alumnaId'],asistencia['id']), 
                                icon: const Icon(Icons.delete, color: Colors.red,)),
                              
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 20),
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
                  ),
                ],
              ),
            ),
    );
  }
}
