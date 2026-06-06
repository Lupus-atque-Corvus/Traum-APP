import 'package:drift/drift.dart';

/// Karten-Typen (Graffiti, Türme, Lost Places, erweiterbar)
class MapCollections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get hasRating => boolean().withDefault(const Constant(false))();
  BoolColumn get multiPhoto => boolean().withDefault(const Constant(false))();
  TextColumn get fieldConfig => text().withDefault(const Constant('{}'))();
  // JSON: {"rating":true,"multiPhoto":true,"fields":[{...}]}
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Ein Punkt auf der Karte
class MapMarkers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get collectionId => integer().references(MapCollections, #id)();
  TextColumn get title => text().withDefault(const Constant(''))();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get locationName => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get hashtags => text().withDefault(const Constant(''))();
  RealColumn get rating => real().nullable()();
  TextColumn get customFields => text().withDefault(const Constant('{}'))();
  // JSON: {"condition":"Verfallen","access":"Zaun","hidden":true}
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Fotos zu einem Marker (1 bei Graffiti, mehrere bei Türmen/Lost Places)
class MarkerPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get markerId => integer().references(MapMarkers, #id)();
  TextColumn get photoPath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get widthPx => integer().nullable()();
  IntColumn get heightPx => integer().nullable()();
  DateTimeColumn get takenAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}
