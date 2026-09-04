import 'package:flutter/material.dart';

class FaworiLogo extends StatelessWidget {
  final double size;
  const FaworiLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final fs = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top:    BorderSide(color: const Color(0xFFF9A03F), width: size * 0.04),
          right:  BorderSide(color: const Color(0xFF3FA65C), width: size * 0.04),
          bottom: BorderSide(color: const Color(0xFF2E77D0), width: size * 0.04),
          left:   BorderSide(color: const Color(0xFFD93025), width: size * 0.04),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(alignment: Alignment.centerLeft,  child: Text('FA', style: _t(fs))),
          Align(alignment: Alignment.center,      child: Text('WO', style: _t(fs))),
          Align(alignment: Alignment.centerRight, child: Text('RI', style: _t(fs))),
        ],
      ),
    );
  }

  TextStyle _t(double fs) =>
      TextStyle(color: Colors.white, fontSize: fs, fontWeight: FontWeight.w800, height: 1.1);
}
