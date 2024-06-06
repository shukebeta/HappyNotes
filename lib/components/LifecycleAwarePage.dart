import 'package:flutter/cupertino.dart';

abstract class LifecycleAwarePage extends StatefulWidget {
  const LifecycleAwarePage({super.key});

  void onPageBecomesActive();
  void onPageBecomesInactive();
}
