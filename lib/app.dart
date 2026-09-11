import 'package:flutter/material.dart';

import 'features/shell/camping_home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Peterbauer Camping',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1f6f68)),
          scaffoldBackgroundColor: const Color(0xfff5f7f4),
          useMaterial3: true,
        ),
        home: const CampingHomePage(),
      );
}
