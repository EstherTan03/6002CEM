// menu_navigation
import 'package:flutter/material.dart';

const List<String> userMenu = [
  'Home Page',
  'Schedule',
  'Profile',
  'Logout',
];

const List<String> adminMenu = [
  'Home Page',
  'Post Event',
  'Schedule',
  'Profile',
  'Logout',
];

const List<String> superAdminMenu = [
  'Home Page',
  'Post Event',
  'Schedule',
  'Manage Users',
  'Profile',
  'Logout',
];

final Map<String, IconData> menuIcons = {
  'Home Page': Icons.home,
  'Post Event': Icons.event,
  'Schedule': Icons.schedule,
  'Manage Users': Icons.people,
  'Profile': Icons.person,
  'Logout' : Icons.logout,
};

List<String> getMenuByRole(String role) {
  switch (role) {
    case 'admin':
      return adminMenu;
    case 'super_admin':
      return superAdminMenu;
    default:
      return userMenu;
  }
}
