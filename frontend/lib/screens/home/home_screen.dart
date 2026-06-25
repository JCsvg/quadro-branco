import 'package:flutter/material.dart';
import 'package:sdwb/core/signals/router_signals.dart';
import 'package:sdwb/core/signals/theme_palette_signals.dart';
import 'package:sdwb/core/theme/app_bar.dart';
import 'package:sdwb/core/theme/theme_palette.dart';
import 'package:signals/signals_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nomeUsuarioController = TextEditingController();

  @override
  void dispose() {
    _nomeUsuarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // ignore: deprecated_member_use
    final paletteIndex = selectedPaletteIndex.watch(context);

    return Scaffold(
      appBar: const SdwbAppBar(showHome: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Quadro Branco',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Colabore em tempo real com seu time — desenhe, anote e crie juntos.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'COR DO TEMA',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < kThemePalettes.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: GestureDetector(
                                  onTap: () => selectedPaletteIndex.value = i,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: kThemePalettes[i].seedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: i == paletteIndex
                                            ? colorScheme.onSurface
                                            : colorScheme.outline,
                                        width: i == paletteIndex ? 3 : 1.5,
                                      ),
                                    ),
                                    child: i == paletteIndex
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOME DE USUÁRIO',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nomeUsuarioController,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Lucas Mendes',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.secondaryContainer,
                                    foregroundColor:
                                        colorScheme.onSecondaryContainer,
                                  ),
                                  onPressed:
                                      _nomeUsuarioController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : () => goTo(AppRoute.view),
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('Jogar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => goTo(AppRoute.create),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Criar Sala'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quadro Branco · Colaboração em tempo real',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
