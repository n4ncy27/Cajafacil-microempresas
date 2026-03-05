import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          // Header azul
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF3366FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo + avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buenos días,',
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Juan Huertas',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Text(
                        'N',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Card total en caja
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A5E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL EN CAJA — HOY',
                        style: GoogleFonts.montserrat(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$1.573.000',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildBadge(
                            '+ Ingresos \$45.3M',
                            const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 10),
                          _buildBadge(
                            '- Gastos \$4.9M',
                            const Color(0xFFEF5350),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Registrar por voz
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2A5E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.amberAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar por Voz',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '"Vendí 50 Café Volcán en efectivo"',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Grid de 4 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildModuleCard(
                          icon: Icons.arrow_upward,
                          iconColor: const Color(0xFF4CAF50),
                          borderColor: const Color(0xFF4CAF50),
                          title: 'Ingresos',
                          subtitle: 'Ventas y abonos',
                          value: '\$45.3M',
                          valueColor: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModuleCard(
                          icon: Icons.receipt_long,
                          iconColor: const Color(0xFF3366FF),
                          borderColor: const Color(0xFF3366FF),
                          title: 'Compras',
                          subtitle: 'Proveedores',
                          value: '\$22.3M',
                          valueColor: const Color(0xFF3366FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModuleCard(
                          icon: Icons.arrow_downward,
                          iconColor: const Color(0xFFEF5350),
                          borderColor: const Color(0xFFEF5350),
                          title: 'Gastos',
                          subtitle: 'Operativos',
                          value: '\$4.9M',
                          valueColor: const Color(0xFFEF5350),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModuleCard(
                          icon: Icons.inventory_2_outlined,
                          iconColor: const Color(0xFFFF9800),
                          borderColor: const Color(0xFFFF9800),
                          title: 'Inventario',
                          subtitle: 'Control stock',
                          value: '',
                          valueColor: Colors.transparent,
                          badge: '2 bajos',
                          badgeColor: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Reportes card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bar_chart,
                            color: Color(0xFF7C4DFF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reportes',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Flujo de Caja · CxC · CxP · Estado de Resultado',
                                style: GoogleFonts.montserrat(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String value,
    required Color valueColor,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (value.isNotEmpty)
            Text(
              value,
              style: GoogleFonts.montserrat(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: GoogleFonts.montserrat(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
