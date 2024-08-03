import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loginamc/views/loginView.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class AttendanceDashboard extends StatefulWidget {
  final AppUser user;

  AttendanceDashboard({Key? key, required this.user}) : super(key: key);
  @override
  _AsistenciasGraficosViewState createState() => _AsistenciasGraficosViewState();
}

class _AsistenciasGraficosViewState extends State<AttendanceDashboard> {
  List<Map<String, dynamic>> asistencias = [];
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    cargarAsistencias();
  }

  Future<void> cargarAsistencias() async    {
    final QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('PROFESORES').get();

    for (var profesorDoc in profesoresSnapshot.docs) {
      final asistenciasSnapshot = await profesorDoc.reference.collection('ASISTENCIAS').get();
      asistencias.addAll(asistenciasSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>));
    }

    asistencias.sort((a, b) => DateFormat('dd-MM-yyyy').parse(a['fecha']).compareTo(DateFormat('dd-MM-yyyy').parse(b['fecha'])));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 13, 14, 104)!, Color.fromARGB(255, 66, 2, 68)!],
          ),
        ),
        child:SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: Text("MENU DE GRAFICOS", style: TextStyle(color: Colors.white70, fontSize: 20),)),
              ),
              SizedBox(height: 24),
              _buildDateRangePicker(),
              SizedBox(height: 24),
              _buildCarouselSlider(),
              SizedBox(height: 24),
              // _buildChartContainer(
              //   'Faltas y Tardanzas por Sección'
              //   // _buildStackedBarChart(),
              // ),
              Center(
                child: GestureDetector(
                  child: Container(
                  padding: EdgeInsets.all(16),
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 231, 12, 12).withOpacity(.6),
                        blurRadius: 2,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Center(child: Text("CERRAR SESION", style: TextStyle(color: Colors.white70, fontSize: 17),)),
                  ),
                onTap: () {
                  _cerrarSesion();
                },
                ),
              ),
            
            ],
          ),
        ),
      ),
    );
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => LoginPage()));// Asegúrate de tener una ruta de login configurada
  }
  
  Widget _buildDateRangePicker() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(start: startDate, end: endDate),
              );
              if (picked != null) {
                setState(() {
                  startDate = picked.start;
                  endDate = picked.end;
                });
              }
    },
            child: Text(
              '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM').format(endDate)}',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
          Icon(Icons.calendar_today, color: Colors.white60),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 500,
        viewportFraction: 0.8,
        enlargeCenterPage: true,
        enableInfiniteScroll: true,
        scrollDirection: Axis.vertical,
        autoPlay: true,
      ),
      items: [
        _buildChartContainer('Faltas y Tardanzas\n', _buildLineChart()),
        _buildChartContainer('Distribución por Curso\n', _buildPieChart()),
        _buildChartContainer('Faltas y Tardanzas por Sección\n', _buildGroupedBarChart()),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      
      padding: EdgeInsets.only(bottom: 20, top: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max, // Añadido para minimizar el tamaño vertical
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white60),
          ),
          SizedBox(height: 1),
          SizedBox(
            height: 280, // Altura fija para el gráfico
            child: chart,
          )
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    List<Map<String, dynamic>> filteredData = asistencias.where((a) {
      DateTime date = DateFormat('dd-MM-yyyy').parse(a['fecha']);
      return date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)));
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < filteredData.length && value.toInt() % 5 == 0) {
                  DateTime date = DateFormat('dd-MM-yyyy').parse(filteredData[value.toInt()]['fecha']);
                  return Text(
                    DateFormat('d MMM').format(date),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: TextStyle(color: Colors.white70, fontSize: 10));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _lineChartBarData(filteredData, 'totalFaltas', Colors.red),
          _lineChartBarData(filteredData, 'totalTardanzas', Colors.blue),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  '${flSpot.y.toInt()}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineChartBarData(List<Map<String, dynamic>> data, String field, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value[field].toDouble());
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildPieChart() {
    Map<String, num> faltasPorCurso = {};
    Map<String, num> tardanzasPorCurso = {};

    for (var item in asistencias) {
      DateTime date = DateFormat('dd-MM-yyyy').parse(item['fecha']);
      if (date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)))) {
        String curso = item['cursoId'];
        faltasPorCurso[curso] = (faltasPorCurso[curso] ?? 0) + item['totalFaltas'];
        tardanzasPorCurso[curso] = (tardanzasPorCurso[curso] ?? 0) + item['totalTardanzas'];
      }
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          ...faltasPorCurso.entries.map((entry) => PieChartSectionData(
                color: Colors.red.withOpacity(0.8),
                value: entry.value.toDouble(),
                title: '${entry.key}\n${entry.value}',
                radius: 100,
                titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              )),
          ...tardanzasPorCurso.entries.map((entry) => PieChartSectionData(
                color: Colors.blue.withOpacity(0.8),
                value: entry.value.toDouble(),
                title: '${entry.key}\n${entry.value}',
                radius: 80,
                titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              )),
        ],
      ),
    );
  }

  // Widget _buildStackedBarChart() {
  //   Map<String, Map<String, num>> dataBySection = {};

  //   for (var item in asistencias) {
  //     DateTime date = DateFormat('dd-MM-yyyy').parse(item['fecha']);
  //     if (date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)))) {
  //       String section = item['seccionId'];
  //       dataBySection.putIfAbsent(section, () => {'faltas': 0, 'tardanzas': 0});
  //       dataBySection[section]!['faltas'] = (dataBySection[section]!['faltas'] ?? 0) + item['totalFaltas'];
  //       dataBySection[section]!['tardanzas'] = (dataBySection[section]!['tardanzas'] ?? 0) + item['totalTardanzas'];
  //     }
  //   }

  //   return BarChart(
  //     BarChartData(
  //       alignment: BarChartAlignment.spaceAround,
  //       maxY: dataBySection.values.fold<double>(0, (max, data) => math.max<double>(max, (data['faltas']! + data['tardanzas']!).toDouble())),

  //       barTouchData: BarTouchData(
  //         touchTooltipData: BarTouchTooltipData(
  //           //tooltipBgColor: Colors.blueAccent,
  //           getTooltipItem: (group, groupIndex, rod, rodIndex) {
  //             String sectionName = dataBySection.keys.elementAt(group.x.toInt());
  //             String label = rodIndex == 0 ? 'Faltas' : 'Tardanzas';
  //             return BarTooltipItem(
  //               '$sectionName\n$label: ${rod.toY.toInt()}',
  //               const TextStyle(color: Colors.white),
  //             );

  //           },
  //         ),
  //       ),
  //       titlesData: FlTitlesData(
  //         show: true,
  //         bottomTitles: AxisTitles(
  //           sideTitles: SideTitles(
  //             showTitles: true,
  //             getTitlesWidget: (value, meta) {
  //               if (value.toInt() >= 0 && value.toInt() < dataBySection.length) {
  //                 return Text(dataBySection.keys.elementAt(value.toInt()), style: TextStyle(color: Colors.black54, fontSize: 10));
  //               }
  //               return Text('');
  //             },
  //           ),
  //         ),
  //         leftTitles: AxisTitles(
  //           sideTitles: SideTitles(
  //             showTitles: true,
  //             reservedSize: 30,
  //             interval: 5,
  //             getTitlesWidget: (value, meta) {
  //               return Text(value.toInt().toString(), style: TextStyle(color: Colors.white70, fontSize: 10));
  //             },
  //           ),
  //         ),
  //         topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //         rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //       ),
  //       gridData: FlGridData(show: false),
  //       borderData: FlBorderData(show: false),
  //       barGroups: dataBySection.entries.map((entry) {
  //         return BarChartGroupData(
  //           x: dataBySection.keys.toList().indexOf(entry.key),
  //           barRods: [
  //             BarChartRodData(
  //               toY: entry.value['faltas']!.toDouble(),
  //               color: Colors.red,
  //               width: 16,
  //               borderRadius: BorderRadius.circular(4),
  //             ),
  //             BarChartRodData(
  //               toY: entry.value['tardanzas']!.toDouble(),
  //               color: Colors.blue,
  //               width: 16,
  //               borderRadius: BorderRadius.circular(4),
  //             ),
  //           ],
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  Widget _buildGroupedBarChart() {
    Map<String, Map<String, num>> dataBySection = {};

    for (var item in asistencias) {
      DateTime date = DateFormat('dd-MM-yyyy').parse(item['fecha']);
      if (date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)))) {
        String section = item['seccionId'];
        dataBySection.putIfAbsent(section, () => {'faltas': 0, 'tardanzas': 0});
        dataBySection[section]!['faltas'] = (dataBySection[section]!['faltas'] ?? 0) + item['totalFaltas'];
        dataBySection[section]!['tardanzas'] = (dataBySection[section]!['tardanzas'] ?? 0) + item['totalTardanzas'];
      }
    }
      return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: dataBySection.values.fold<double>(0, (max, data) => math.max<double>(max, (data['faltas']! + data['tardanzas']!).toDouble())),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String sectionName = dataBySection.keys.elementAt(group.x.toInt());
              String label = rodIndex == 0 ? 'Faltas' : 'Tardanzas';
              return BarTooltipItem(
                '$sectionName\n Total: ${rod.toY.toInt()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dataBySection.length) {
                  return Text(dataBySection.keys.elementAt(value.toInt()), style: TextStyle(color: Colors.black54, fontSize: 10));
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles:SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: TextStyle(color: Colors.white70, fontSize: 10));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: dataBySection.entries.map((entry) {
          return BarChartGroupData(
            x: dataBySection.keys.toList().indexOf(entry.key),
            barsSpace: 4,
            barRods: [  
              BarChartRodData(
                toY: entry.value['faltas']!.toDouble(),
                color: Colors.red,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: entry.value['tardanzas']!.toDouble(),
                color: Colors.blue,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}