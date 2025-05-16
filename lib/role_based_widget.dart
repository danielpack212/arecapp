import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class RoleBasedWidget extends StatelessWidget {
  final Widget Function(BuildContext) maintenanceTechnicianBuilder;
  final Widget Function(BuildContext) energyExpertBuilder;
  final Widget Function(BuildContext)? defaultBuilder;

  RoleBasedWidget({
    required this.maintenanceTechnicianBuilder,
    required this.energyExpertBuilder,
    this.defaultBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<UserProvider>().userRole;

    switch (userRole) {
      case 'Maintenance Technician':
        return maintenanceTechnicianBuilder(context);
      case 'Energy Expert':
        return energyExpertBuilder(context);
      default:
        return defaultBuilder?.call(context) ?? SizedBox.shrink();
    }
  }
}