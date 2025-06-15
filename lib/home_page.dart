import 'package:flutter/material.dart';

import 'menu_navigation.dart';
import 'shared.dart';
import 'home_page_card.dart';

class HomePage extends StatelessWidget{

  final User user;

  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Event'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: Color(0xFFDBFFCB),
      ),
      drawer: AppDrawer(
        user: user,
      ),
      body: HomePageCard(currentUser: user)
    );
  }
}