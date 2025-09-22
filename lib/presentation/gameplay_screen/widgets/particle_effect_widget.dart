import 'package:flutter/material.dart';

import './enhanced_particle_effect_widget.dart';

class ParticleEffectWidget extends StatefulWidget {
  final bool isActive;
  final Color particleColor;

  const ParticleEffectWidget({
    Key? key,
    required this.isActive,
    required this.particleColor,
  }) : super(key: key);

  @override
  State<ParticleEffectWidget> createState() => _ParticleEffectWidgetState();
}

class _ParticleEffectWidgetState extends State<ParticleEffectWidget> {
  @override
  Widget build(BuildContext context) {
    return EnhancedParticleEffectWidget(
      isActive: widget.isActive,
      particleColor: widget.particleColor,
      particleCount: 25,
      duration: const Duration(milliseconds: 1200),
    );
  }
}
