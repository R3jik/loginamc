import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:loginamc/viewsAuxiliar/mainAuxView.dart';


class NavigatorAuxiliar extends StatefulWidget {
  
  const NavigatorAuxiliar({super.key});

  @override
  State<NavigatorAuxiliar> createState() => _NavigatorAuxiliarState();
}

class _NavigatorAuxiliarState extends State<NavigatorAuxiliar> {
  
  int _selectedIndex = 0;
  
  static const List<Widget> _widgetOptions = <Widget>[
    //MainAuxview(),
    //Buscar(),
    //Justificar(),
    //Perfil(),
  ];
  @override
  
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      bottomNavigationBar: 
        Container(

            child: GNav(
            //padding: EdgeInsets.all(30),
            tabMargin: EdgeInsets.only(top: 8, bottom:8),
            tabBackgroundColor: const Color.fromRGBO(7, 30, 48, 0.7),
            backgroundColor: const Color.fromRGBO(0, 18, 31, 1),
            tabBorderRadius: 100, 
            duration: const Duration(milliseconds: 400),
            tabs:const [
            GButton(
              icon: Icons.home,
              iconColor: Colors.white,
              iconActiveColor: Colors.white,
              text: "Inicio",
              textColor: Colors.white,
              ),
        
            GButton(
              icon: Icons.search_rounded,
              iconColor: Colors.white,
              iconActiveColor: Colors.white,
              text: "Buscar",
              textColor: Colors.white,
              ),
        
            GButton(
              icon: Icons.article_sharp,
              iconColor: Colors.white,
              iconActiveColor: Colors.white,
              text: "Justificar",
              textColor: Colors.white,
              ),
        
            GButton(
              icon: Icons.person_pin,
              iconColor: Colors.white,
              iconActiveColor: Colors.white,
              text: "Perfil",
              textColor: Colors.white,
              ),
          ],
          
          selectedIndex: _selectedIndex, 
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          }
          )
        ),
      
    );
  }
}