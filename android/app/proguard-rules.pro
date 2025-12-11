# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Firestore classes
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Isar database classes
-keep class io.isar.** { *; }
-dontwarn io.isar.**

# Keep model classes (for JSON serialization)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Don't obfuscate Gson classes
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
