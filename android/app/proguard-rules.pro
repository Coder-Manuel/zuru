# Flutter core (REQUIRED)
-keep class io.flutter.** { *; }
-keep class io.flutter.util.PathUtils { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# JNI
-keep class com.github.dart_lang.jni.** { *; }

# Supabase / Ktor / OkHttp
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.ktor.**

# Firebase
-keep class com.google.firebase.** { *; }

# Gson internal types used by Mapbox geocoding SDK
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Mapbox
-keep class com.mapbox.** { *; }

# LiveKit / WebRTC
-keep class org.webrtc.** { *; }
-keep class io.livekit.** { *; }

-keepattributes *Annotation*
-dontwarn io.flutter.**
