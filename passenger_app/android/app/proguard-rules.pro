# Flutter engine / embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# flutter_secure_storage (Tink / AndroidX security)
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.google.errorprone.annotations.**

# Sentry
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Keep stack traces readable in Sentry (mapping.txt is uploaded by CI)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
