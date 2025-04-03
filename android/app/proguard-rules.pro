# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Camera plugin
-keep class androidx.camera.** { *; }

# Accessibility
-keep class android.view.accessibility.** { *; }
-dontwarn android.view.accessibility.**

# Don't warn about unused classes
-dontwarn android.util.LongArray
-dontwarn androidx.window.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Kotlin Metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keep class kotlin.** { *; }
-keep class org.jetbrains.** { *; } 