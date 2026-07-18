import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: c.primary, borderRadius: BorderRadius.circular(19)),
              child: Icon(Icons.bolt_outlined, color: c.primaryInk, size: 36),
            ),
            const SizedBox(height: 18),
            Text('작업온',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 20),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: c.primary),
            ),
          ],
        ),
      ),
    );
  }
}
