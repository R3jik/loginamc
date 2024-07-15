import 'package:flutter/material.dart';

class IconoPerfil extends StatelessWidget {
  Color fondoIconoClaro = Color(0XFF0066FF);
  Color fondoIconoOscuro = Color(0XFF001220);

  IconoPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fondoIconoOscuro,
        border: Border.all(
          color: fondoIconoClaro,
          width: 10,
        )
      ),
      child: 
      Icon(Icons.person ,color: fondoIconoClaro, size: 90,),
      
    );
  }
}