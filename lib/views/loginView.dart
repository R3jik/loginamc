import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginamc/helpers/navigatorAdmin.dart';
import 'package:loginamc/helpers/navigatorProfesor.dart';
import 'package:loginamc/views/resetPassView.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class AppUser {
  final String dni;

  AppUser({required this.dni});
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        User user = userCredential.user!;
        await _redirectUserBasedOnRole(user);
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'invalid-email':
              _errorMessage = 'El correo electrónico no es válido.';
              break;
            case 'user-disabled':
              _errorMessage = 'Esta cuenta ha sido deshabilitada.';
              break;
            case 'user-not-found':
              _errorMessage = 'No se encontró una cuenta con este correo electrónico.';
              break;
            case 'wrong-password':
              _errorMessage = 'La contraseña es incorrecta.';
              break;
            default:
              _errorMessage = 'Error de autenticación. Por favor, inténtelo de nuevo.';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error de red. Por favor, verifique su conexión a Internet.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _redirectUserBasedOnRole(User user) async {
    
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('USUARIOS').doc(user.uid).get();
      if (userDoc.exists) {
        String role = userDoc.get('rol').toString().toUpperCase();
        String dni = userDoc.get('dni').toString();
        AppUser appUser = AppUser(dni: dni);

        if (role == 'PROFESOR') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NavigatorProfesor(user: appUser)),
          );
        } else if (role == 'AUXILIAR') {
          // Implementar navegación para AUXILIAR
        } else if (role == 'ADMINISTRADOR') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NavigatorAdmin(user: appUser)),
          );
        } else {
          setState(() {
            _errorMessage = 'Usuario no tiene rol asignado';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Usuario no registrado';
        });
      }
    
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
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
                  child: CustomPaint(
                    size: Size(screenWidth * 0.4, screenHeight * 0.2),
                    painter: WavePainter(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Transform.rotate(
                    angle: 3.14159,
                    child: CustomPaint(
                      size: Size(screenWidth * 0.4, screenHeight * 0.2),
                      painter: WavePainter(),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60, left: 30, right: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image(
                              image: const AssetImage('assets/images/Insignia_AMC.png'),
                              width: screenWidth * 0.3,
                              height: screenHeight * 0.2,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: Text(
                              'INGRESE SU CUENTA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: whiteText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Usuario',
                            style: TextStyle(
                              color: whiteText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: input,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(50)),
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
                          Text(
                            'Contraseña',
                            style: TextStyle(
                              color: whiteText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ResetPasswordPage()));
                                },
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: lightBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lightBlue,
                                ),
                                onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.login, color: whiteColor),
                                          SizedBox(width: 8),
                                          Text(
                                            'INGRESAR',
                                            style: TextStyle(
                                              color: whiteColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
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
            );
          },
        ),
        resizeToAvoidBottomInset: false,
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0XFF0066FF)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height * 1);

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

    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}