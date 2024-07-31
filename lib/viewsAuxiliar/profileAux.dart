
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
  // ignore: unused_field
  String _currentDate = '';
  String cursoId = '';
  // ignore: unused_field
  List<dynamic> _seccionData = [];
  Map<String, dynamic>? _cursoData;
  List<Map<String, dynamic>> _asistencias = [];
  

  @override
  void initState() {
    super.initState();
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
        body: Stack(
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(5),
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
                                  padding: const EdgeInsets.only(left:8.0),
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
                                  padding: const EdgeInsets.only(left:8.0),
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
                                  padding: const EdgeInsets.only(left:8.0),
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
                                  width: 200,
                                  child: Text(
                                    '${_cursoData?['nombre'] ?? ''}',
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
                
              ],
            ),
          ),
        ],
      ),

    ),
  );
}

}
