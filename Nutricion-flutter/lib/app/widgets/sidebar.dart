import 'package:flutter/material.dart';

import '../models.dart';

enum ViewType { platos, inventario }

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.currentView,
    required this.onViewChange,
    required this.selectedCasa,
    required this.onCasaChange,
  });

  final ViewType currentView;
  final ValueChanged<ViewType> onViewChange;
  final Casa selectedCasa;
  final ValueChanged<Casa> onCasaChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF166534),
            Color(0xFF14532D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildCasaSelector(),
          Expanded(child: _buildMenu()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF15803D)),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hogar Bambi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Nutrición',
            style: TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasaSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF15803D)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Casa Actual',
            style: TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCasa.id,
                iconEnabledColor: Colors.white,
                dropdownColor: const Color(0xFF166534),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (value) {
                  final casa = casas.firstWhere(
                    (c) => c.id == value,
                    orElse: () => casas.first,
                  );
                  onCasaChange(casa);
                },
                items: [
                  for (final casa in casas)
                    DropdownMenuItem(
                      value: casa.id,
                      child: Text(casa.nombre),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _SidebarItem(
          label: 'Platos Servidos',
          icon: Icons.restaurant_menu_outlined,
          isActive: currentView == ViewType.platos,
          onTap: () => onViewChange(ViewType.platos),
        ),
        _SidebarItem(
          label: 'Inventario',
          icon: Icons.inventory_2_outlined,
          isActive: currentView == ViewType.inventario,
          onTap: () => onViewChange(ViewType.inventario),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF15803D)),
        ),
      ),
      child: const Text(
        'Sistema de Gestión v1.0',
        style: TextStyle(
          color: Color(0xFFA7F3D0),
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF16A34A) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? Colors.white : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
