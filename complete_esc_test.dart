import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complete ESC Key Test',
      home: EscKeyNavigationTest(),
    );
  }
}

class EscKeyNavigationTest extends StatefulWidget {
  @override
  _EscKeyNavigationTestState createState() => _EscKeyNavigationTestState();
}

class _EscKeyNavigationTestState extends State<EscKeyNavigationTest> {
  late FocusNode _focusNode;
  String _lastAction = "None";
  int _escCount = 0;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    // Listen to focus changes
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      print('🎯 Focus changed: ${_focusNode.hasFocus}');
    });
    
    // Request focus after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      print('🚀 App started, focus requested');
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _simulateBackButton() {
    print('⬅️ Back button simulation');
    setState(() {
      _lastAction = "Back button pressed";
    });
    // Navigate to second screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SecondScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        print('🎹 Key event: ${event.runtimeType} - ${event.logicalKey}');
        
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          print('🎉 ESC KEY DETECTED!');
          setState(() {
            _escCount++;
            _lastAction = "ESC pressed - simulating back";
          });
          
          // Simulate back button behavior
          if (Navigator.of(context).canPop()) {
            print('✅ Can pop - going back');
            Navigator.of(context).pop();
          } else {
            print('❌ Cannot pop - staying on current screen');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ESC = Back Button Test'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _isFocused ? Colors.green.shade100 : Colors.red.shade100,
                  border: Border.all(
                    color: _isFocused ? Colors.green : Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Status: ${_isFocused ? "✅ FOCUSED" : "❌ NOT FOCUSED"}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isFocused ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('ESC Key Presses: $_escCount'),
                    Text('Last Action: $_lastAction'),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Test Instructions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '1. Ensure this window is focused (click on it)\n'
                '2. Press ESC key - should do nothing (no back navigation)\n'
                '3. Click "Go to Second Screen" button\n'
                '4. On second screen, press ESC - should come back here\n'
                '5. Check terminal for debug messages',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _simulateBackButton,
                    child: Text('Go to Second Screen'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _focusNode.requestFocus();
                      print('🎯 Manual focus request');
                    },
                    child: Text('Request Focus'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  late FocusNode _focusNode;
  int _escCount = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    // Request focus after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      print('🚀 Second screen loaded, focus requested');
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
        print('🎹 Second screen key event: ${event.runtimeType} - ${event.logicalKey}');
        
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          print('🎉 ESC KEY DETECTED ON SECOND SCREEN!');
          setState(() {
            _escCount++;
          });
          
          // Simulate back button behavior
          if (Navigator.of(context).canPop()) {
            print('✅ Can pop - going back to first screen');
            Navigator.of(context).pop();
          } else {
            print('❌ Cannot pop from second screen');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Second Screen - ESC to Go Back'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is the SECOND SCREEN',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('ESC Key Presses: $_escCount'),
                    SizedBox(height: 10),
                    Text(
                      'Press ESC key to go back to the first screen\n'
                      'This simulates the back arrow button behavior',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Manual Back Button'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}