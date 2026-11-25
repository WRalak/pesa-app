# Keep Flutter + plugin entry points that are reached via reflection.
-keep class io.flutter.** { *; }
-keep class androidx.biometric.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.google.android.play.core.**
