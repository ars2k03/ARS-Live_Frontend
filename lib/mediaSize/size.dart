import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  double get w => MediaQuery.sizeOf(this).width;
  double get h => MediaQuery.sizeOf(this).height;
}