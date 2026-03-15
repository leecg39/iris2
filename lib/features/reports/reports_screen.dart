// @TASK P1-S0-T1 - 보고서 탭 Placeholder 화면
// @SPEC docs/planning/

import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text(
              '보고서',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '매칭 보고서 (준비 중)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
