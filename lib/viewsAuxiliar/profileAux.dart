
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:loginamc/views/loginView.dart';
import 'package:loginamc/widgets/Icono.dart';

class ProfileAux extends StatefulWidget {
  final AppUser profesorId;

  const ProfileAux({Key? key, required this.profesorId}) : super(key: key);

  @override
  _ProfileAuxState createState() => _ProfileAuxState();
}

class _ProfileAuxState extends State<ProfileAux> {
  Map<String, dynamic>? _profesorData;
  String cursoId = '';
  List<Map<String, dynamic>> justificaciones = [];
  bool _isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _fetchProfesorData();
    _fetchJustificaciones();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _fetchProfesorData() async {
  if (!_mounted) return;
  
  try {
    // Obtener el documento del profesor
    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.profesorId.dni)
        .get();

    if (!_mounted) return;  // Verificar nuevamente después de la operación asíncrona

    if (!profesorDoc.exists) {
      print('El documento del profesor no existe.');
      return;
    }

    //print('Profesor Data: ${profesorDoc.data()}');

      _profesorData = profesorDoc.data() as Map<String, dynamic>;
      //cursoId = _profesorData?['cursoId'] ?? '';
      _isLoading = false;
  
  } catch (e){
  print('Error fetching data: $e');
    if (_mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }}

  void _fetchJustificaciones() async {
    try {
      QuerySnapshot justificacionesSnapshot = await FirebaseFirestore.instance
          .collection('AUXILIARES')
          .doc(widget.profesorId.dni)
          .collection('JUSTIFICACIONES')
          .get();

      setState(() {
        justificaciones = justificacionesSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'numero_expediente': data['numero_expediente'] ?? '',
            'fecha': data['fecha'] ?? '',
            'estado': data['estado'] ?? '',
            'descripcion_expediente': data['descripcion_expediente'] ?? '',
            'nombreAlumna': data['nombreAlumna'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching justificaciones: $e');
    }
  }


  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => LoginPage()));// Asegúrate de tener una ruta de login configurada
  }

  // Función auxiliar para parsear la fecha
DateTime? _parseDate(dynamic fecha) {
  if (fecha is DateTime) return fecha;
  if (fecha is Timestamp) return fecha.toDate();
  if (fecha is String) {
    try {
      return DateFormat('dd-MM-yyyy').parse(fecha);
    } catch (e) {
      print('Error parsing date: $fecha');
      return null;
    }
  }
  return null;
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
    TextStyle textoDatosProf = TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: whiteText);

    return SafeArea(
      child: Scaffold(
        body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                color: fondo2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(0),
                    width: screenWidth,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: fondo1,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(' ', style: textoDatosProf),
                            Text('MI PERFIL', style: textoDatosProf),
                            GestureDetector(
                              onTap: (){_cerrarSesion();},
                              child: 
                              const Tooltip(
                                message: "CERRAR SESION",
                                child: Icon(
                                Icons.arrow_circle_right_outlined,
                                  color: Color(0XFF0066FF),
                                  size: 35.0,
                                ),
                              ),
                              
                            ),
                          ],
                        )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left:0),
                                  child: Text(
                                    'Nombre:',
                                    style: textoDatosProf,
                                  ),
                                ),
                                Container(
                                  width: screenWidth * 0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['nombre'] ?? ''}', style: textoDatosProf),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left:0),
                                  child: Text(
                                    'Apellido Paterno:',
                                    style: textoDatosProf,
                                  ),
                                ),
                                Container(
                                  width: screenWidth * 0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['apellido_paterno'] ?? ''}', style: textoDatosProf),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left:0),
                                  child: Text(
                                    'Apellido Materno:',
                                    style: textoDatosProf,
                                  ),
                                ),
                                Container(
                                  width: screenWidth * 0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['apellido_materno'] ?? ''}', style: textoDatosProf),
                                ),
                              ],
                            ),
                            
                            Column(
                              children: <Widget>[
                                IconoPerfil(),
                                const SizedBox(height: 20),
                                Container(
                                  width: 180,
                                  child: Text(
                                    '${_profesorData?['cursoId'] ?? ''}',
                                    style: textoDatosProf,textAlign:  TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  
                const SizedBox(height: 20,),
                
                const Text('Justificaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                
                const SizedBox(height: 20,),

                Expanded(
                  child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: justificaciones.length,
                  itemBuilder: (context, index) {
                    final justificacion = justificaciones[index];
                    return Column(
                      children: [
                        Card(
                          color: Colors.blue[900],
                          child: ListTile(
                            title: Text('Expediente: ${justificacion['numero_expediente']}',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fecha: ${justificacion['fecha']}', style: const TextStyle(color: Colors.white70)),
                                Text('Estado: ${justificacion['estado']}', style: const TextStyle(color: Colors.white70)),
                                Text('Alumna: ${justificacion['nombreAlumna']}', style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            trailing: const Icon(Icons.check_circle, color: Colors.green),
                            onTap: () {
                              AlertDialog(
                                title: Text("a"),
                                actions: [
                                  ElevatedButton(onPressed: (){}, child: Text("Info aqui"))
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 10,),
                      ],
                    );
                  },
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
