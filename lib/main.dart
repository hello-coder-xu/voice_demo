import 'package:flutter/material.dart';
import 'package:voice_demo/recorder/recorder_demo.dart';
import 'package:voice_demo/recorder/recorder_mp4.dart';
import 'package:voice_demo/recorder/recorder_pcm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) {
                      return const RecorderMp4();
                    },
                  ),
                );
              },
              child: const Text("mp4"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) {
                      return const RecorderPcm16();
                    },
                  ),
                );
              },
              child: const Text("pcm16"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) {
                      return const RecorderDemo();
                    },
                  ),
                );
              },
              child: const Text("录音demo"),
            ),
          ],
        ),
      ),
    );
  }
}
