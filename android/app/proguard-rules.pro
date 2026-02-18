# Add project specific ProGuard rules here.
# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }

-dontwarn com.google.android.play.core.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Firestore
-keep class com.google.firebase.firestore.** { *; }
-keepclassmembers class com.google.firebase.firestore.** { *; }

# Keep authentication
-keep class com.google.firebase.auth.** { *; }

# Keep Google Sign In
-keep class com.google.android.gms.auth.** { *; }

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve Flutter plugin classes
-keep class io.flutter.embedding.** { *; }
