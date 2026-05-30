import 'package:flutter/material.dart';
import '../../core/services/calendar_sync_service.dart' show NativeCalendar;
import '../../core/theme/colors.dart';

/// Shows a multi-select calendar picker dialog.
/// Returns the selected calendar IDs, or null if cancelled.
Future<List<String>?> showCalendarPickerDialog(
  BuildContext context,
  List<NativeCalendar> calendars,
  List<String> currentIds,
) {
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => _CalendarPickerDialog(
      calendars: calendars,
      initialIds: currentIds,
    ),
  );
}

class _CalendarPickerDialog extends StatefulWidget {
  final List<NativeCalendar> calendars;
  final List<String> initialIds;
  const _CalendarPickerDialog({required this.calendars, required this.initialIds});

  @override
  State<_CalendarPickerDialog> createState() => _CalendarPickerDialogState();
}

class _CalendarPickerDialogState extends State<_CalendarPickerDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TraumColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Kalender auswählen',
        style: TextStyle(
          color: TraumColors.onBackground,
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: widget.calendars.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Keine Kalender gefunden.\nBitte schließe den Planner und öffne ihn erneut.',
                style: TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 14,
                ),
              ),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.calendars.length,
                itemBuilder: (_, i) {
                  final cal = widget.calendars[i];
                  final isChecked = _selected.contains(cal.id);
                  final subtitle =
                      cal.accountName != null && cal.accountName != cal.name
                          ? cal.accountName!
                          : '';
                  return CheckboxListTile(
                    activeColor: TraumColors.lavender,
                    checkColor: Colors.white,
                    value: isChecked,
                    onChanged: (_) => setState(() {
                      if (isChecked) {
                        _selected.remove(cal.id);
                      } else {
                        _selected.add(cal.id);
                      }
                    }),
                    secondary: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: cal.color != null
                            ? Color(cal.color!)
                            : TraumColors.lavender,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      cal.name,
                      style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontSize: 14,
                      ),
                    ),
                    subtitle: subtitle.isNotEmpty
                        ? Text(
                            subtitle,
                            style: const TextStyle(
                              color: TraumColors.onBackgroundSubtle,
                              fontFamily: 'DMSans',
                              fontSize: 12,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(
            'Abbrechen',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
          child: Text(
            'Fertig',
            style: TextStyle(
              color: _selected.isEmpty
                  ? TraumColors.onBackgroundSubtle
                  : TraumColors.lavender,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
