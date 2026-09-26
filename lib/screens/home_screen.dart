import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'add_medication_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(key: _dashboardKey),
      const CalendarScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: _index == 0
            ? Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Image.asset('assets/images/jen_logo_name.png', height: 44, fit: BoxFit.contain, alignment: Alignment.centerLeft),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, size: 28, color: Color(0xFF1565F5)),
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen())),
                        ),
                        Image.asset('assets/images/jen_home.png', height: 72),
                      ],
                    ),
                  ),
                  Expanded(child: screens[0]),
                ],
              )
            : screens[1],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565F5),
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddMedicationScreen()));
          if (result == true) _dashboardKey.currentState?.refresh();
        },
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 32,
                  color: _index == 0 ? const Color(0xFF1565F5) : Colors.grey),
              onPressed: () => setState(() => _index = 0),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: Icon(Icons.calendar_month, size: 32,
                  color: _index == 1 ? const Color(0xFF1565F5) : Colors.grey),
              onPressed: () => setState(() => _index = 1),
            ),
          ],
        ),
      ),
    );
  }
}