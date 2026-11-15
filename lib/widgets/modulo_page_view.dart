import 'package:flutter/material.dart';

/// PageView compartilhado pelos módulos do app.
///
/// O snapping nativo só troca de módulo após um arraste suficiente ou um
/// gesto rápido; toques curtos e a rolagem vertical continuam com o conteúdo.
class ModuloPageView extends StatelessWidget {
  final PageController controller;
  final List<Widget> children;
  final ValueChanged<int> onPageChanged;

  const ModuloPageView({
    super.key,
    required this.controller,
    required this.children,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) => PageView(
    controller: controller,
    onPageChanged: onPageChanged,
    physics: const PageScrollPhysics(),
    children: children,
  );
}
