import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginamc/helpers/navigatorProfesor.dart';
import 'package:loginamc/views/mainAuxView.dart';
import 'package:loginamc/views/resetPassView.dart';




class LoginPage extends StatefulWidget {
  @override
  
  _LoginPageState createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _obscureText = true;

  Future<void> _signInWithEmailAndPassword() async {
    if(_formKey.currentState!.validate()){
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User user = userCredential.user!;
      //Verificar el tipo de usuario
      await _redirectUserBasedOnRole(user);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }
    }
  }

  Future<void> _redirectUserBasedOnRole(User user) async {
    // Verificar en la colección 'profesores'
    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance.collection('PROFESORES').doc(user.uid).get();
    if (profesorDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NavigatorProfesor(user: user)),
      );
      return;
    }
    // Verificar en la colección 'auxiliares'
    DocumentSnapshot auxiliarDoc = await FirebaseFirestore.instance.collection('AUXILIARES').doc(user.uid).get();
    if (auxiliarDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainAuxview(user: user)),
      );
      return;
    }
    // Si no se encuentra el UID en ninguna colección, mostrar un mensaje de error
    setState(() {
      _errorMessage = 'Usuario no tiene rol asignado';
    });
  }

  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    

    Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color input = const Color(0XFFD3E5FF);

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
                  child: Container(
                    width: screenWidth,
                    height: screenHeight,
                    color: fondo,
                    ),
            ),
            Align(
              alignment: Alignment.topRight,
              child:  CustomPaint(
                size:  Size(screenWidth*0.4, screenHeight*0.2),
                painter: WavePainter(),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child:Transform.rotate(
              angle: 3.14159,
              child: CustomPaint(
                size:  Size(screenWidth*0.4, screenHeight*0.2),
                painter: WavePainter(),
              ),
            ),),
            SingleChildScrollView(
              child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.only(top: 60,left: 30,right: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image(
                        image: const AssetImage('assets/images/Insignia_AMC.png'),
                        width: screenWidth*0.3,
                        height: screenHeight*0.2,),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text('INGRESE SU CUENTA', style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: whiteText,
                      ),
                      textAlign: TextAlign.center,),
                    ),
                    const SizedBox(height: 15),
                    Text('Usuario', style: TextStyle(
                      color: whiteText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),),
                    const SizedBox(height: 10,),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: input,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50))
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Por favor ingrese un correo electrónico válido';
                          }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Text('Contraseña', style: TextStyle(
                      color: whiteText ,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),),
                    const SizedBox(height: 10,),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        filled: true,
                        fillColor: input,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                          setState(() {
                              _obscureText = !_obscureText;
                          });
                          },
                          
              ),
            ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=> ResetPasswordPage()));
                          },
                          child: Text('¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: lightBlue,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lightBlue,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _signInWithEmailAndPassword();
                            }
                          },
                          icon: Icon(Icons.login, color: whiteColor,),
                          label: Text('INGRESAR',style: TextStyle(
                            color: whiteColor,
                            fontWeight: FontWeight.bold,
                          ),),
                        ),
                      ],
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              ),
            ),
            
          ],
        ),
        resizeToAvoidBottomInset: true,
        
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0XFF0066FF) // Color de la forma
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0); // Empezar en la esquina superior derecha
    path.lineTo(size.width, size.height * 1); // Línea hacia abajo

    // Dibujar curvas
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 1,
      size.width * 0.7,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.6,
      size.width * 0.35,
      size.height * 0.75,
    );
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.6,
      size.width * 0.4,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0,
      size.height * 0,
    );

    path.lineTo(0, 0); // Línea hasta la esquina superior izquierda
    path.close(); // Cerrar el camino

    canvas.drawPath(path, paint); // Dibujar la forma en el lienzo
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}