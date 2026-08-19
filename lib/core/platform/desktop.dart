import 'dart:io';

/// True on Windows/Linux desktop builds — the single gate for features that
/// have no desktop equivalent (Android/iOS home-screen widgets, Health
/// Connect/HealthKit, background task scheduling, OS calendar sync, the
/// camera overlay, barcode/OCR scanning). Desktop "companion mode": core
/// modules work, mobile-exclusive features are hidden rather than crashing.
bool get isDesktop => Platform.isWindows || Platform.isLinux;
