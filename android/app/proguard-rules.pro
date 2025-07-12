# Flutter проект - правила обфускации для релиза

# Общие правила для Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Play Billing
-keep class com.android.billingclient.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# ДОБАВЛЕНО: Google Maps - КРИТИЧНО для работы карты!
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.maps.** { *; }
-dontwarn com.google.android.gms.maps.**
-dontwarn com.google.maps.**

# ДОБАВЛЕНО: Geolocator - для определения местоположения
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ДОБАВЛЕНО: Google Maps Flutter plugin
-keep class io.flutter.plugins.googlemaps.** { *; }
-dontwarn io.flutter.plugins.googlemaps.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Kotlinx Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Gson (если используется)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Сохранить имена классов для отладки
-keepattributes SourceFile,LineNumberTable

# Optimization
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Сохранить аннотации для рефлексии
-keepattributes *Annotation*,InnerClasses,Signature,Exceptions

# ДОБАВЛЕНО: Защита от удаления важных классов
-keepclasseswithmembers class * {
    @com.google.android.gms.common.annotation.KeepForSdk <methods>;
}

-keepclasseswithmembers class * {
    @com.google.android.gms.common.annotation.KeepForSdk <fields>;
}

# ДОБАВЛЕНО: Сохранить методы с аннотациями
-keepclasseswithmembers class * {
    @com.google.android.gms.common.util.VisibleForTesting <methods>;
}

# ДОБАВЛЕНО: Для WebView (если используется в картах)
-keep class android.webkit.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.android.gms.internal.**