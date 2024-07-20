import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loginamc/views/pruebaCSVView.dart';
import 'package:loginamc/views/seccionesAuxView.dart';


    Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);

class MainSiageView extends StatelessWidget {
  final User user;
  
  MainSiageView({required this.user});
  Future<Map<String, dynamic>> getUserInfo() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('ADMINISTRADORES').doc(user.uid).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    

    TextStyle texto = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: whiteText,
    );

    return SafeArea(
      child: Scaffold(
        body:
            Container(
              width: screenWidth,
              height: screenHeight,
              color: fondo1,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(screenWidth*0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: getUserInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}', style: texto,);
                          } else {
                            Map<String, dynamic> userInfo = snapshot.data!;
                            String greeting = userInfo['genero'] == 'Masculino' ? 'Bienvenido' : 'Bienvenida';
                            return Text('$greeting, ${userInfo['nombre']} ${userInfo['apellido_paterno']}',style:  texto,);
                          }
                        },
                      ),
                      Image(
                        image: const AssetImage('assets/images/Insignia_AMC.png'),
                        width: screenWidth*0.1,
                        height: screenHeight*0.1,
                      )
                    ],
                    
                  ),
                ),
                GestureDetector(
                  child: Container(
                              height: 100,
                              width: 300,
                              child: Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>  LinearGradient(
                  colors: [fondo1 , lightBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                                ).createShader(bounds),
                                child: const Text(
                  "Agregar Datos de los Profesores",
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white, // El color se aplicará como un degradado por ShaderMask
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                                ),
                              ),
                      ],
                    ),
                  ),
                  ),
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => UploadPage()));
                  },
                ),
              ],
            ),
          ),
          ),
    );
  }
}


class GradoCard extends StatelessWidget {
  final int numero;
  final String nombre;

  GradoCard({required this.numero, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>  LinearGradient(
              colors: [fondo1 , lightBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              numero.toString(),
              style: const TextStyle(
                fontSize: 80,
                color: Colors.white, // El color se aplicará como un degradado por ShaderMask
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            nombre,
            style:  const TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}