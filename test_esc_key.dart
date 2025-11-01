import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESC Key Test',
      home: EscKeyTestScreen(),
    );
  }
}

class EscKeyTestScreen extends StatefulWidget {
  @override
  _EscKeyTestScreenState createState() => _EscKeyTestScreenState();
}

class _EscKeyTestScreenState extends State<EscKeyTestScreen> {
  late FocusNode _focusNode;
  String _lastKeyPressed = "None";
  int _escPressCount = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        print('🔍 Raw Key Event: ${event.runtimeType}');
        print('🔍 Logical Key: ${event.logicalKey}');
        print('🔍 Physical Key: ${event.physicalKey}');
        
        setState(() {
          _lastKeyPressed = event.logicalKey.debugName ?? 'Unknown';
        });

        if (event is RawKeyDownEvent) {
          print('⬇️ Key Down Event: ${event.logicalKey}');
          
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            print('🎉 ESC KEY DETECTED!');
            setState(() {
              _escPressCount++;
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ESC Key Test'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _focusNode.hasFocus ? Colors.green : Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Focus Status: ${_focusNode.hasFocus ? "FOCUSED" : "NOT FOCUSED"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _focusNode.hasFocus ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Last Key Pressed: $_lastKeyPressed',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'ESC Key Presses: $_escPressCount',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Instructions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '1. Make sure this window has focus\n'
                '2. Press the ESC key\n'
                '3. Check the terminal for debug messages\n'
                '4. Count should increase',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _focusNode.requestFocus();
                  print('🎯 Focus requested manually');
                },
                child: Text('Request Focus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}