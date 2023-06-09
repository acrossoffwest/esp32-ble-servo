import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _connected = false;
  late BluetoothDevice bluetoothDevice;
  late BluetoothService bluetoothService;
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  void _connect() async {
    print("connect!");

    if (!_connected) {
      flutterBlue.startScan(timeout: Duration(seconds: 4));
      var subscription = flutterBlue.scanResults.forEach((results) async {
        if (_connected) {
          return;
        }
        // do something with scan results
        for (ScanResult r in results) {
          if (_connected) {
            break;
          }
          if (r.device.name == "-> HELO WORLDE <-") {
            bluetoothDevice = r.device;
            print('${bluetoothDevice.name} found! rssi: ${r.rssi} -> connecting');
            // Connect to the device
            await bluetoothDevice.connect();
            List<BluetoothService> services = await bluetoothDevice.discoverServices();
            services.forEach((service) {
              print("------>  ${service.uuid.toString()}");
              if (service.uuid.toString() == "6e400001-b5a3-f393-e0a9-e50e24dcca9e") {
                print("------>  ${service.uuid.toString()}  <---------- save");
                bluetoothService = service;
              }
            });
            _connected = true;
            break;
          }
        }
      });
      flutterBlue.stopScan();
    }

    setState(() {
      if (_connected) {
        _counter = 1;
      } else {
        _counter = 0;
      }
    });
  }

  void _disconnect() async {
    print("disconnect!");

    if (_connected) {
      await bluetoothDevice.disconnect();
      _connected = false;
    }

    setState(() {
      if (_connected) {
        _counter = 1;
      } else {
        _counter = 0;
      }
    });
  }

  void _rx() async {
    print("rx!");

    // Reads all characteristics
    var characteristics = bluetoothService.characteristics;
    for(BluetoothCharacteristic c in characteristics) {
      // List<int> value = await c.read();
      // print(value);
      print("C -> ${c.uuid.toString()}");
      if (c.uuid.toString() == "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
        await c.write(utf8.encode("A"));
        break;
      }
    }
  }

  void _tx() async {
    print("tx!");

    var characteristics = bluetoothService.characteristics;
    for(BluetoothCharacteristic c in characteristics) {
      print("C -> ${c.uuid.toString()}");
      if (c.uuid.toString() == "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
        await c.write(utf8.encode("B"));
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            FloatingActionButton(
              onPressed: _disconnect,
              tooltip: 'Increment',
              child: const Icon(Icons.circle),
            ),
            FloatingActionButton(
              onPressed: _rx,
              tooltip: 'Increment',
              child: const Icon(Icons.abc),
            ),
            FloatingActionButton(
              onPressed: _tx,
              tooltip: 'Increment',
              child: const Icon(Icons.ac_unit),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _connect,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
