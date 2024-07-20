import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:loginamc/views/mainView.dart';
import 'package:loginamc/helpers/timezone_helper.dart';
import 'package:timezone/timezone.dart' as tz;

class AsistenciaView extends StatefulWidget {
  final String seccionId;
  final String seccionNombre;
  final String gradoNombre;
  final String profesorId;  // Añadimos el ID del profesor

  AsistenciaView({
    required this.seccionId,
    required this.seccionNombre,
    required this.gradoNombre,
    required this.profesorId,  // Añadimos el ID del profesor
  });

  @override
  _AsistenciaViewState createState() => _AsistenciaViewState();
}

class _AsistenciaViewState extends State<AsistenciaView> {
  List<Map<String, dynamic>> _alumnas = [];
  int _totalAsistentes = 0;
  int _totalAlumnas = 0;
  int _totalFaltantes = 0;
  int _totalTardanzas = 0;
  String _cursoNombre = '';  // Añadimos una variable para el nombre del curso
  bool _isLoading = false;
  TextStyle texto = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _fetchAlumnas();
    _fetchCursoNombre();  // Llamamos a la función para obtener el nombre del curso
  }

  void _fetchAlumnas() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('ALUMNAS')
        .where('seccionId', isEqualTo: widget.seccionId)
        .orderBy('apellido_paterno')
        .get();

    List<Map<String, dynamic>> alumnas = querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'nombre': doc['nombre'],
        'apellido_paterno': doc['apellido_paterno'],
        'apellido_materno': doc['apellido_materno'],
        'estado': 'none', // Estado por defecto
      };
    }).toList();

    setState(() {
      _alumnas = alumnas;
      _totalAlumnas = alumnas.length; // Inicialmente no contamos asistencia, faltas ni tardanzas
      _totalAsistentes = 0;
      _totalFaltantes = 0;
      _totalTardanzas = 0;
    });
  }

  void _fetchCursoNombre() async {
    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId)
        .get();
    String cursoId = profesorDoc['cursoId'];
    DocumentSnapshot cursoDoc = await FirebaseFirestore.instance
        .collection('CURSOS')
        .doc(cursoId)
        .get();

    setState(() {
      _cursoNombre = cursoDoc['nombre'];
    });
  }
  void _todasAsistentes(){

  }

  void _updateEstado(int index, String estado) {
    setState(() {
      _alumnas[index]['estado'] = estado;
      _totalAsistentes = _alumnas.where((alumna) => alumna['estado'] == 'asistencia').length;
      _totalFaltantes = _alumnas.where((alumna) => alumna['estado'] == 'falta').length;
      _totalTardanzas = _alumnas.where((alumna) => alumna['estado'] == 'tardanza').length;
    });
  }

  Future <void> _guardarAsistencia() async {
    setState(() {
      _isLoading = true;
    });
    // Mostrar mensaje de que se está guardando la lista
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Guardando asistencia...'),
    ));
    // Validación para asegurarse de que todas las alumnas tienen un estado válido
    bool todasValidas = _alumnas.every((alumna) => alumna['estado'] != 'none');
    if (!todasValidas) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debe marcar la asistencia, tardanza o falta para todas las alumnas'),
      ));
      return;
    }

    final tz.TZDateTime now = TimeZoneHelper.nowInLima();
    final String fecha = DateFormat('dd-MM-yyyy').format(now);
    final Timestamp timestamp = Timestamp.fromDate(now);

    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId)
        .get();
    String cursoId = profesorDoc['cursoId'];

    for (var alumna in _alumnas) {
      String asistenciaId = '$fecha-$cursoId';
      await FirebaseFirestore.instance
          .collection('ALUMNAS')
          .doc(alumna['id'])
          .collection('asistencia')
          .doc(asistenciaId)  // Usamos el UID personalizado
          .set({
        'fecha': timestamp,
        'cursoNombre': _cursoNombre,  // Guardamos el nombre del curso
        'estado': alumna['estado'],
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Asistencia guardada exitosamente'),
    ));
    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context);
  }
  void _marcarAsistenciaATodas() {
    setState(() {
      for (var i = 0; i < _alumnas.length; i++) {
        _alumnas[i]['estado'] = 'asistencia';
      }
      _totalAsistentes = _alumnas.length;
      _totalFaltantes = 0;
      _totalTardanzas = 0;
    });
  }
  void _marcarFaltaTodas(){
    setState(() {
      for (var i=0; i< _alumnas.length; i++){
        _alumnas[i]['estado'] = 'falta';
      }
      _totalAsistentes = 0;
      _totalFaltantes = _alumnas.length;
      _totalTardanzas = 0;
    });
  }
  void _marcarTardanzaTodas(){
    setState(() {
      for(var i = 0; i < _alumnas.length; i++){
        _alumnas[i]['estado'] = 'tardanza';
      }
      _totalAsistentes = 0;
      _totalFaltantes = 0;
      _totalTardanzas = _alumnas.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Asistencia del ${widget.gradoNombre} - ${widget.seccionNombre}',style: const TextStyle(
            color: Colors.white,
            fontSize: 20),),
          backgroundColor: fondo2,
          iconTheme: const IconThemeData(
            color: Colors.white
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                color: fondo2,
                width: screenWidth,
                height: screenHeight,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: screenWidth ,
                    height: screenHeight * 0.15,
                    decoration:  BoxDecoration(
                      color: fondo1,
                      borderRadius:  const BorderRadius.all(Radius.circular(20))
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text('TOTAL', style: texto),
                                  const SizedBox(height: 10,),
                                  Row(
                                    children: [
                                      const Icon(Icons.group, color: Colors.white,),
                                      const SizedBox(width: 10,),
                                      Text(_totalAlumnas.toString(), style: texto,),
                                    ],
                                  )
                                ],
                              ),
                              Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(DateFormat('dd-MM-yyyy').format(TimeZoneHelper.nowInLima()), style: texto),
                                      const SizedBox(width: 10,),
                                      const Icon(Icons.calendar_month, color: Colors.white, size: 30,),
                                    ],
                                  ),
                                  const SizedBox(height: 10,),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        onPressed:(){
                                          _marcarAsistenciaATodas();
                                        },
                                        icon: const Icon(Icons.check_circle, color: Colors.green,)),
                                      Text(_totalAsistentes.toString(), style: texto),
                                      IconButton(
                                        onPressed: (){
                                          _marcarFaltaTodas();
                                        }, icon: const Icon(Icons.remove_circle, color: Colors.red,))
                                      ,
                                      Text(_totalFaltantes.toString(), style: texto),
                                      IconButton(
                                        onPressed: (){
                                          _marcarTardanzaTodas();
                                        }, 
                                        icon: const Icon(Icons.access_time_filled, color: Colors.yellow,)),
                                      Text(_totalTardanzas.toString(), style: texto),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Container(
                      width: screenWidth * 0.9,
                      decoration:  BoxDecoration(
                        color: fondo1,
                        borderRadius: const BorderRadius.all(Radius.circular(30))
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: ListView.builder(
                          itemCount: _alumnas.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                '${_alumnas[index]['apellido_paterno']} ${_alumnas[index]['apellido_materno']}, ${_alumnas[index]['nombre']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              trailing: Container(
                                width: screenWidth * 0.35,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.check_circle,
                                        color: _alumnas[index]['estado'] == 'asistencia' ? Colors.green : Colors.white,
                                      ),
                                      onPressed: () {
                                        _updateEstado(index, 'asistencia');
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_circle,
                                        color: _alumnas[index]['estado'] == 'falta' ? Colors.red : Colors.white,
                                      ),
                                      onPressed: () {
                                        _updateEstado(index, 'falta');
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.access_time_filled,
                                        color: _alumnas[index]['estado'] == 'tardanza' ? Colors.yellow : Colors.white,
                                      ),
                                      onPressed: () {
                                        _updateEstado(index, 'tardanza');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10,),
                  GestureDetector(
                    onTap: _isLoading ? null : _guardarAsistencia,
                    child: Container(
                      height: screenHeight*0.05,
                      width: screenWidth*0.6,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Color(0XFF005FA9)
                      ),
                      child: Center(
                        child: _isLoading
                        ? const CircularProgressIndicator( valueColor:  AlwaysStoppedAnimation<Color>(Colors.white),)
                        :  Text("Guardar Asistencia", style: texto,)),
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
