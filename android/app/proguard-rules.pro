# Chrono Calendar ProGuard Rules
# 用于解决 R8 代码混淆导致的 flutter_local_notifications 崩溃问题

# ==================== Gson 规则 ====================
# Gson 使用泛型类型信息进行序列化/反序列化
# R8 默认会移除这些信息，需要显式保留

# 保留泛型签名（Gson 反射需要）
-keepattributes Signature

# 保留注解（Gson 的 @SerializedName 等）
-keepattributes *Annotation*

# 保留 Gson TypeToken 类
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# 保留 Gson 相关的内部类
-keep class com.google.gson.** { *; }

# ==================== flutter_local_notifications 规则 ====================
# 该插件使用 Gson 序列化通知数据，需要保留相关类

-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }

# ==================== Serializable 规则 ====================
# 保留所有实现 Serializable 接口的类的序列化方法

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ==================== Flutter 规则 ====================
# Flutter 引擎相关

-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ==================== 通用规则 ====================
# 防止混淆导致的反射问题

# 保留枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留 Parcelable 实现
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# 保留 R 文件
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ==================== Play Core 规则 ====================
# 忽略 Play Core 缺失类警告（Flutter deferred components 不使用）
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
