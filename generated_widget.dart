import 'package:flutter/material.dart';

class GeneratedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: InputDecoration(hintText: 'e.g., 1h, 4h, 1d', labelText: 'Interval', border: OutlineInputBorder()),
                    obscureText: false,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(hintText: 'e.g., 50, 200 (integer)', labelText: 'Period', border: OutlineInputBorder()),
                    obscureText: false,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(hintText: 'e.g., close, open, high, low (string)', labelText: 'Parameter', border: OutlineInputBorder()),
                    obscureText: false,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(hintText: 'e.g., 3, 5 (integer)', labelText: 'Number of Indicators', border: OutlineInputBorder()),
                    obscureText: false,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12)),
                    child: Text('Save Configuration'),
                  ),
                ],
              ),
          ),
      ),
    );
  }
}
