# MLKit text recognition — suppress missing optional language model classes
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }

# flutter_local_notifications persists scheduled notifications via Gson,
# using `new TypeToken<ArrayList<NotificationDetails>>(){}` to deserialize
# them on every app start (see rescheduleAllNotifications() in main.dart).
# Without these rules R8 strips the generic signature Gson's reflection
# needs, so every cold start throws "TypeToken must be created with a type
# argument" and silently aborts before a single notification gets
# (re)scheduled — the root cause of the long-reported "no notifications"
# bug, only reproducible in a minified release build. Standard Gson-under-
# ProGuard rules, scoped to the plugin's own model classes plus Gson itself.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-dontwarn sun.misc.**
-keep class sun.misc.Unsafe { *; }
