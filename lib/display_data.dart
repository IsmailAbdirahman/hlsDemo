import 'package:flutter/material.dart';

import 'download_data.dart';
import 'home.dart';

class DisplayData extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DisplayDataState();
  }
}

class _DisplayDataState extends State<DisplayData> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    MyApp(),
    DownloadData(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: Center(
            child: _children.elementAt(_currentIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
              onTap: onTabTapped,
              currentIndex: _currentIndex,
              items: [
                BottomNavigationBarItem(
                  icon: new Icon(Icons.cloud_download),
                  label: "Download",
                ),
                BottomNavigationBarItem(
                  icon: new Icon(Icons.copy),
                  label: "Copy",
                ),
              ]),
        ),
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
