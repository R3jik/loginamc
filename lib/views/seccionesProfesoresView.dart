import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loginamc/views/listaView.dart';



Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);


class SeccionesProfesoresPage extends StatelessWidget {
  final String profesorUid;
  final String gradoId;
  final String gradoNombre;

  SeccionesProfesoresPage({required this.profesorUid, required this.gradoId, required this.gradoNombre});

  Future<Map<String, dynamic>> getUserInfo() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('PROFESORES').doc(profesorUid).get();
    return userDoc.data() as Map<String, dynamic>;
  }
  Future<List<Map<String, dynamic>>> getSecciones() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('PROFESORES').doc(profesorUid).get();
    List<dynamic> seccionesIds = userDoc['seccionId'];
    
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('SECCIONES')
    .where(FieldPath.documentId,whereIn: seccionesIds)
    .where('gradoId', isEqualTo: gradoId)
    .get();
    
    return querySnapshot.docs
        .map((doc) => {
              'id':doc.id,
              'letra': doc['letra'],
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    TextStyle texto = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: whiteText,
    );
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                color: fondo1,
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 5),
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
                          return Text('$greeting, ${userInfo['nombre']} ${userInfo['apellido_paterno']}',style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: whiteText,
                            ),);
                        }
                      },
                    ),
                    Image(image: const AssetImage('assets/images/Insignia_AMC.png'),
                    width: screenWidth*0.1,
                    height: screenHeight*0.1,)
                  ],
                ),
              )
            ),
            Positioned(
              bottom: 0,
            child: Container(
              width: screenWidth,
                height: screenHeight*0.82,
                decoration: BoxDecoration(
                  color: fondo2,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(50))
                ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_box,color: whiteColor,size: 30),
                        const SizedBox(width: 5,),
                        Text("Seleccione el aula del $gradoNombre",style: texto,
                        textAlign: TextAlign.left,)
                      ],
                    ),
                  ),
                  Container(
                    height: screenHeight*0.7,
                    width: screenWidth*0.9,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: getSecciones(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}',style: texto,));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No tienes secciones asignadas',style: texto,));
                        } else {
                          List<Map<String, dynamic>> secciones = snapshot.data!;
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 20,
                            ),
                          itemCount: secciones.length,
                          padding: const EdgeInsets.all(10),
                          itemBuilder: (context, index) {
                          return GestureDetector(
                          onTap: () {
                            Navigator.push(context,MaterialPageRoute(builder: (context) =>  AsistenciaView(seccionId: secciones[index]['id'],seccionNombre: secciones[index]['letra'], gradoNombre: gradoNombre, profesorId: profesorUid,),
                      ),
                    );
                                    },
                                    child: SeccionCard(
                                      letra: secciones[index]['letra'],
                                    ),
                                  );
                              },
                            );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
        
      ),
    );
  }
}

class SeccionCard extends StatelessWidget {
  final String letra;

  SeccionCard({required this.letra});

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
              letra.toString(),
              style: const TextStyle(
                fontSize: 80,
                color: Colors.white, // El color se aplicará como un degradado por ShaderMask
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Text("SECCION",
            style: TextStyle(
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
