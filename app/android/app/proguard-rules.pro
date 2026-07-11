# 작업온 릴리스(R8/ProGuard) keep 규칙
# Flutter 코어/임베딩
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase (푸시)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# 카카오 로그인 SDK
-keep class com.kakao.sdk.**.model.* { <fields>; }
-keep class * extends com.google.gson.TypeAdapter
-dontwarn com.kakao.sdk.**

# 홈 위젯(home_widget) Provider
-keep class kr.workon.workon.** { *; }

# 일반적으로 반사(reflection)로 접근되는 모델 보호(GSON/직렬화)
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod
