import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Sample',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'NFC - Home'),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _HomePageState();
  
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder<bool>(
                future: NfcManager.instance.isAvailable(),
                builder: (context, snapshot) => snapshot.data != true ? NfcReaderMissing(snapshot.data) : const NfcReader(),
              )
            ],
          ),
        ),
      );
  }
  //
}

class NfcReaderMissing extends StatelessWidget {
  final bool? data;
  const NfcReaderMissing(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('NfcManager.isAvailable(): ${data?.toString()}'));
  }
}

class NfcReader extends StatefulWidget {
  const NfcReader({super.key});

  @override
  State<StatefulWidget> createState() => _NfcReaderState();
}

class _NfcReaderState extends State<NfcReader> {
  ValueNotifier<dynamic> result = ValueNotifier(null);
  
  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SingleChildScrollView(
          child: ValueListenableBuilder(
            valueListenable: result,
            builder: (context, value, child) => Text('${value ?? 'no data'}'),
          ),
        ),
          
        ElevatedButton(
            onPressed: _tagRead,
            child: const Text('Tag Read')),
        ElevatedButton(
            onPressed: _ndefWrite,
            child: const Text('Ndef Write')),
        ElevatedButton(
            onPressed: _ndefWriteLock,
            child: const Text('Ndef Write Lock')),
      ],
    );
  }

  void _tagRead() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      result.value = tag.data;
      NfcManager.instance.stopSession();
    });
  }

  void _ndefWrite() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not ndef writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      NdefMessage message = NdefMessage([
        NdefRecord.createText('Hello World!'),
        NdefRecord.createUri(Uri.parse('https://flutter.dev')),
        NdefRecord.createMime(
            'text/plain', Uint8List.fromList('Hello'.codeUnits)),
        NdefRecord.createExternal(
            'com.example', 'mytype', Uint8List.fromList('mydata'.codeUnits)),
      ]);

      try {
        await ndef.write(message);
        result.value = 'Success to "Ndef Write"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
  }

  void _ndefWriteLock() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null) {
        result.value = 'Tag is not ndef';
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }

      try {
        await ndef.writeLock();
        result.value = 'Success to "Ndef Write Lock"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
  }
}