import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GastosPage extends StatelessWidget {
  const GastosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(
          'Gastos',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Gastos',
          style: GoogleFonts.montserrat(fontSize: 22, color: Colors.grey),
        ),
      ),
    );
  }
}
