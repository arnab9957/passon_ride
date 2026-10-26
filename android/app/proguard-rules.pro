# Flutter & AndroidX WorkManager / Room ProGuard Rules
# Prevents R8 from stripping/obfuscating WorkDatabase and Room reflection classes required by Firebase & AndroidX Startup

-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.impl.WorkDatabase { *; }

# AndroidX Room
-keep class androidx.room.** { *; }
-keep @androidx.room.Entity class *
-dontwarn androidx.room.**
-dontwarn androidx.work.impl.**

# Google Play Services & reCAPTCHA / Firebase
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.recaptcha.** { *; }
-dontwarn com.google.android.recaptcha.**

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
