// @TASK P1-S0-T1 - 매칭 탭 Placeholder 화면
// @SPEC docs/planning/

import 'package:flutter/material.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_outlined, size: 64, color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text(
              '매칭',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'AI 공고 매칭 (준비 중)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
