import 'package:flutter/material.dart';

final class AppSpace {
  const AppSpace._();

  static const double s0 = 0;
  static const double s0_5 = 2;
  static const double s1 = 4;
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;
  static const double s80 = 80;
}

final class AppRadius {
  const AppRadius._();

  static const Radius none = Radius.circular(0);
  static const Radius xs = Radius.circular(4);
  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(16);
  static const Radius xl = Radius.circular(24);
  static const Radius full = Radius.circular(999);

  static const BorderRadius noneAll = BorderRadius.all(none);
  static const BorderRadius xsAll = BorderRadius.all(xs);
  static const BorderRadius smAll = BorderRadius.all(sm);
  static const BorderRadius mdAll = BorderRadius.all(md);
  static const BorderRadius lgAll = BorderRadius.all(lg);
  static const BorderRadius xlAll = BorderRadius.all(xl);
  static const BorderRadius fullAll = BorderRadius.all(full);
}

final class AppElevation {
  const AppElevation._();

  static const List<BoxShadow> e1 = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> e2 = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 4),
  ];

  static const List<BoxShadow> e3 = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 8),
  ];

  static const List<BoxShadow> e4 = [
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 8), blurRadius: 16),
  ];

  static const List<BoxShadow> e5 = [
    BoxShadow(color: Color(0x29000000), offset: Offset(0, 12), blurRadius: 24),
  ];
}
