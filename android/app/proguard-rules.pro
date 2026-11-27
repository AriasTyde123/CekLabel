# Keep Google ML Kit, ComponentRegistrar (reflection), VisionKit, and Flutter plugin classes in R8 release builds
-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }
-keep class com.google.firebase.components.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google.android.libraries.vision.visionkit.** { *; }
-keep class com.google.android.odml.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_commons.** { *; }

# Suppress R8 missing class warnings for optional ML Kit non-Latin text recognizers
# that are not bundled by default in google_mlkit_text_recognition.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-dontwarn com.google.android.libraries.vision.visionkit.**
-dontwarn com.google.firebase.components.**
