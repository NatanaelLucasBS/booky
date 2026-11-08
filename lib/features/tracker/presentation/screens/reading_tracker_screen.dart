import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela 06: Rastreador de Leitura
/// Cronômetro ativo de leitura imersiva, controle de páginas lidas
/// com ajuste interativo [-] [+] e estatísticas da sessão.
class ReadingTrackerScreen extends StatefulWidget {
  const ReadingTrackerScreen({super.key});

  @override
  State<ReadingTrackerScreen> createState() => _ReadingTrackerScreenState();
}

class _ReadingTrackerScreenState extends State<ReadingTrackerScreen> {
  Timer? _timer;
  int _secondsElapsed = 2604; // 00:43:24 inicial
  bool _isRunning = true;

  int _currentPage = 364;
  final int _totalPages = 656;
  final int _initialSessionPage = 342;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _incrementPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _decrementPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _finishSession() {
    final pagesRead = _currentPage - _initialSessionPage;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sessão Concluída', style: Theme.of(ctx).textTheme.titleLarge),
        content: Text(
          'Excelente! Você leu ${pagesRead > 0 ? pagesRead : 0} páginas em ${_formatTime(_secondsElapsed)}.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressPercent = (_currentPage / _totalPages).clamp(0.0, 1.0);
    final pagesReadInSession = _currentPage - _initialSessionPage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreador De Leitura'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Identificação do Livro
              Text(
                'SESSÃO EM ANDAMENTO',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'O Nome do Vento',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'Patrick Rothfuss',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Capítulo 18 — A Estrada para Imre',
                  style: theme.textTheme.labelMedium,
                ),
              ),

              const SizedBox(height: 36),

              // Timer Display Gigante
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRunning ? AppColors.woodBrown : AppColors.mediumBrown,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TEMPO DECORRIDO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _formatTime(_secondsElapsed),
                style: TextStyle(
                  fontFamilyFallback: const ['Courier', 'monospace'],
                  fontSize: 54,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isRunning ? 'Foco ininterrupto' : 'Sessão pausada',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 40),

              // Controle Interativo de Páginas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColors.mediumBrown : AppColors.beige,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'PROGRESSO DA LEITURA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Botão Decrementar
                        IconButton.outlined(
                          onPressed: _decrementPage,
                          icon: const Icon(Icons.remove, size: 20),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? AppColors.mediumBrown : AppColors.beige,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$_currentPage',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'de $_totalPages',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Text(
                              'página atual',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Botão Incrementar
                        IconButton.outlined(
                          onPressed: _incrementPage,
                          icon: const Icon(Icons.add, size: 20),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? AppColors.mediumBrown : AppColors.beige,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Linha de Progresso
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 4,
                        backgroundColor: isDark ? AppColors.darkBrown : AppColors.beige,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.lightCream : AppColors.darkBrown,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progressPercent * 100).toInt()}% concluído • ${pagesReadInSession > 0 ? pagesReadInSession : 0} páginas nesta sessão',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botões de Ação da Sessão
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 18),
                label: Text(_isRunning ? 'PAUSAR SESSÃO' : 'RETOMAR LEITURA'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _finishSession,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('CONCLUIR SESSÃO DE LEITURA'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
