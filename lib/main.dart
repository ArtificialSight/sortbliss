34
    }
35
 return const SizedBox.shrink();
36  };
37
 
38
 // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
39
 await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
40
 
41
 runApp(const MyApp());
42 }
43 
44 class MyApp extends StatelessWidget {
45   const MyApp({super.key});
46
47   @override
48   Widget build(BuildContext context) {
49     return Sizer(builder: (context, orientation, screenType) {
50       return MaterialApp(
51         title: 'sortbliss',
52         theme: AppTheme.lightTheme,
53         darkTheme: AppTheme.darkTheme,
54         themeMode: ThemeMode.light,
55         // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
56         builder: (context, child) {
57           return MediaQuery(
58             data: MediaQuery.of(context).copyWith(
59               textScaler: TextScaler.linear(1.0),
60             ),
61             child: child!,
62           );
63         },
64         // 🚨 END CRITICAL SECTION
65         debugShowCheckedModeBanner: false,
66         routes: AppRoutes.routes,
67         initialRoute: AppRoutes.initial,
68       );
69     });
70   }
71 }