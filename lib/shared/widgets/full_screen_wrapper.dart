import 'package:flutter/material.dart';

class FullScreenWrapper extends StatelessWidget {
  final Widget child;
  
  const FullScreenWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}