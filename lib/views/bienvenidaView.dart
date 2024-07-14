import 'package:flutter/material.dart';
import 'package:loginamc/views/loginView.dart';



class Bienvenidaview extends StatelessWidget {
  const Bienvenidaview ({super.key});

  @override
  Widget build(BuildContext context) {
    
    //trae el tamaño de la pantalla del dispositivo
    final screenSize = MediaQuery.of(context).size;
    //aplica variable de ancho
    final screenWidth = screenSize.width;
    //aplica variable de largo
    final screenHeight = screenSize.height;

    Color whiteText = const Color(0XFFF3F3F3);
    Color bgBlue = const Color(0XFF001220);
    Color lightBlue = const Color(0XFF0066FF);
    Color textButton = const Color(0XFFEAEAEA);

    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              //Grafico de fondo
              Positioned(
                top: 0,
                child: Container(
                  width: screenWidth,
                  height: screenHeight,
                  color: bgBlue,
                  ),
                ),
              //Presentación principal
              Positioned(
                top: screenHeight*0.1,
                left: screenWidth*0.1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("BIENVENIDO", style:TextStyle(
                      color: whiteText,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Heebo',
                      ),
                      textAlign: TextAlign.left,
                    ),            
                    Text("SISTEMA DE ASISTENCIA DE ALUMNAS", style: TextStyle(
                      color: whiteText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.left,
                    ),
                  Image(
                  image: const AssetImage('assets/images/img_icono.png'),
                  width: screenWidth*0.8,
                  height: screenHeight*0.4,
                  fit: BoxFit.contain, // Ajustar la imagen dentro del contenedor, manteniendo la relación de aspecto
                ),
                Center(
                  child: GestureDetector(
                    onTap: ()  {
                      Navigator.push(context, MaterialPageRoute(builder: (context ) =>  LoginPage()));
                      }
                    ,
                    child: Container(
                      margin: const EdgeInsets.symmetric( vertical: 30, horizontal: 50),
                      padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 50),
                      decoration:  BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(60)),
                        color: lightBlue,
                        
                      ),
                      child:  Text('SIGUIENTE', style: TextStyle(
                        color: textButton,
                        fontWeight: FontWeight.bold,
                        fontSize: 24
                      ),),
                      
                    ),
                  ),
                ),
                  ],
                )
              ),
              //Grafico inferior
              Positioned(
                bottom: 0,
                child: ClipPath(
                  clipper: MountainClipper(),
                  child: Container(
                    width: screenWidth,
                    height: screenHeight*0.7,
                    color: lightBlue,
              ),
              ),
              )
            ],
            
          ),
        ),
      ),
    );
  }
}

//creación del gráfico azul
class MountainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    // Iniciar el camino desde el borde inferior izquierdo
    path.moveTo(0, size.height);
    
    // Dibujar curvas que parecen montañas
    path.lineTo(0, size.height * 0.79);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.8, size.width * 0.2, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.9, size.width * 0.4, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width * 0.6, size.height * 0.79);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.8, size.width * 0.8, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.9, size.width , size.height * 0.8);
    
    // Terminar el camino en el borde inferior derecho
    path.lineTo(size.width, size.height);

    // Cerrar el camino
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}