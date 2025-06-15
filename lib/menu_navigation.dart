// home_page, post_event, schedule_page, profile_page, manage_user
import 'package:flutter/material.dart';

import 'menu_list.dart';

import 'shared.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'post_event.dart';
import 'schedule_page.dart';
import 'manage_user.dart';
import 'profile_page.dart';

class AppDrawer extends StatelessWidget {

  final User user;

  const AppDrawer({Key? key, required this.user}) : super(key: key);

  // Handle menu tap navigation
  void handleMenuTap(String item, BuildContext context){
    Navigator.pop(context); // Close drawer

    switch (item) {
      case 'Home Page':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => HomePage(user: user,)));
        break;
      case 'Post Event':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostEvent(user: user,)));
        break;
      case 'Schedule':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SchedulePage(user: user)));
        break;
      case 'Manage Users':
         Navigator.push(context, MaterialPageRoute(builder: (_) => ManageUser(user: user)));
        break;
      case 'Profile':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(user: user)));
        break;
      case 'Logout':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
              (route) => false,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unknown menu item: $item")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuList = getMenuByRole(user.role);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Hello ${user.name} \nRole : ${user.role}',
                style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ...menuList.map((item) => ListTile(
            leading: Icon(menuIcons[item] ?? Icons.menu),
            title: Text(item),
            tileColor : MenuCategoryColour(item),
            onTap: () => handleMenuTap(item, context),
          ))
        ],
      ),
    );
  }
}

MenuCategoryColour(String category){
  switch(category){
    case 'Home Page':
      return const Color(0xFFDBFFCB);
    case 'Post Event':
      return const Color(0xFFFFF1D5);
    case 'Schedule':
      return const Color(0xFFF7CFD8);
    case 'Manage Users':
      return const Color(0xFFBBD8A3);
    case 'Profile':
      return const Color(0xFF94B4C1);
    case 'Logout':
      return const Color(0xFF94F4CF);
  }
}