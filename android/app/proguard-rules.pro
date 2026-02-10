# Flutter engine (official minimal rules)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.FlutterView { *; }
-keep class io.flutter.util.PathUtils { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Gson (for JSON serialization)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Encryption libraries
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
-keep class org.pointycastle.** { *; }
-dontwarn org.pointycastle.**

# Biometric authentication
-keep class androidx.biometric.** { *; }
-keep interface androidx.biometric.** { *; }
# Google Play Core - Required for Flutter deferred components
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep interface com.google.android.play.core.**
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep interface com.google.android.play.core.splitinstall.**
-keep class com.google.android.play.core.tasks.** { *; }
-keep interface com.google.android.play.core.tasks.**
