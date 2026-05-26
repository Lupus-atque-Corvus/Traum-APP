import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/preferences_provider.dart';
import '../providers/repository_providers.dart';
import '../../l10n/app_localizations.dart';

// ── ClockWeatherWidget ────────────────────────────────────────────────────────
//
// Shows the current time (updated every second via Timer) and the cached
// weather data (temperature + icon + condition).  Mirrors the design from the
// original concept repo (HomeClockWeatherWidget).

class ClockWeatherWidget extends ConsumerStatefulWidget {
  const ClockWeatherWidget({super.key});

  @override
  ConsumerState<ClockWeatherWidget> createState() => _ClockWeatherWidgetState();
}

class _ClockWeatherWidgetState extends ConsumerState<ClockWeatherWidget> {
  late DateTime _now;
  late Timer _timer;

  String? _tempStr;
  String? _condition;
  int _weatherCode = 0;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeather());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final prefs = ref.read(sharedPreferencesProvider);
    _parseCache(prefs);

    final repo = ref.read(weatherRepositoryProvider);
    if (mounted) {
      await repo.refreshOnStart(prefs, context);
      if (mounted) _parseCache(prefs);
    }
  }

  void _parseCache(dynamic prefs) {
    final cache = prefs.getString('weather_cache') as String?;
    if (cache == null) return;
    try {
      final l10n = AppLocalizations.of(context)!;
      final data = jsonDecode(cache) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return;

      final temp = current['temperature_2m'] as num?;
      final code = (current['weathercode'] as num?)?.toInt() ?? 0;

      final unitSystem =
          ref.read(preferencesRepositoryProvider).unitSystem;
      final tempVal = temp == null
          ? null
          : unitSystem == 'imperial'
              ? '${(temp * 9 / 5 + 32).round()}°F'
              : '${temp.round()}°C';

      if (mounted) {
        setState(() {
          _tempStr = tempVal;
          _weatherCode = code;
          _condition = _conditionForCode(code, l10n);
        });
      }
    } catch (_) {}
  }

  String _conditionForCode(int code, AppLocalizations l10n) {
    if (code == 0) return l10n.weatherClear;
    if (code <= 3) return l10n.weatherCloudy;
    if (code <= 48) return l10n.weatherFoggy;
    if (code <= 67) return l10n.weatherRain;
    if (code <= 77) return l10n.weatherSnow;
    if (code <= 82) return l10n.weatherShowers;
    return l10n.weatherThunderstorm;
  }

  Widget _weatherIcon(int code) {
    if (code == 0) {
      return const Icon(Icons.wb_sunny_rounded,
          color: Color(0xFFFFBF00), size: 52);
    }
    if (code <= 2) {
      return Stack(
        children: [
          Positioned(
            top: 2,
            left: 2,
            child: Icon(Icons.wb_sunny_rounded,
                color: const Color(0xFFFF9800), size: 36),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Icon(Icons.cloud_rounded, color: Colors.white70, size: 36),
          ),
        ],
      );
    }
    if (code == 3) {
      return const Icon(Icons.cloud_rounded, color: Colors.blueGrey, size: 52);
    }
    if (code <= 48) {
      return const Icon(Icons.blur_on, color: Colors.grey, size: 52);
    }
    if (code <= 55) {
      return const Icon(Icons.grain, color: Color(0xFF64B5F6), size: 52);
    }
    if (code <= 65) {
      return const Icon(Icons.water_drop_rounded,
          color: Color(0xFF42A5F5), size: 52);
    }
    if (code <= 77) {
      return const Icon(Icons.ac_unit_rounded,
          color: Colors.lightBlue, size: 52);
    }
    if (code <= 82) {
      return const Icon(Icons.umbrella, color: Color(0xFF42A5F5), size: 52);
    }
    if (code >= 95) {
      return const Icon(Icons.bolt_rounded,
          color: Color(0xFFFFBF00), size: 52);
    }
    return const Icon(Icons.cloud_outlined, color: Colors.grey, size: 52);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!.localeName;
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final dateStr = DateFormat.yMMMMEEEEd(locale).format(_now);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: Clock + Date ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$h:$m',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFAFAFA),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
          // ── Right: Weather (only when data is available) ───────────────────
          if (_tempStr != null) ...[
            const SizedBox(width: 12),
            SizedBox(width: 52, height: 52, child: _weatherIcon(_weatherCode)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tempStr!,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFAFAFA),
                    height: 1.1,
                  ),
                ),
                if (_condition != null)
                  Text(
                    _condition!,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
