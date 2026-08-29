// lib/ui/onboarding/welcome_screen.dart — ONB-01. First screen a user with
// no `appdata.json` ever sees. Vietnamese copy is verbatim per §6 — never
// translated, paraphrased or abbreviated.
import 'package:flutter/material.dart';

import 'onboarding_flow.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'MotoNote',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhắc bảo dưỡng xe máy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              // Drive restore is Phase 5 (BKP-08) — disabled here.
              const OutlinedButton(
                onPressed: null,
                child: Text('Khôi phục từ Google Drive'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sẽ có ở bản sau',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingFlow(),
                    ),
                  );
                },
                child: const Text('Bắt đầu mới'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
