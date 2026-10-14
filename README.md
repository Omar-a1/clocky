# ⏰ Clocky - تطبيق المنبه الذكي العصري

تطبيق منبه ومؤقت ذكي مبني بواسطة **Flutter** و **Dart** بتصميم **Material 3** عصري مع **Floating Navigation Bar** ودعم كامل للغة العربية.

## ✨ المميزات الرئيسية
- 🔔 **تنبيهات تعمل في الخلفية:** باستخدام `flutter_local_notifications` و `timezone` بدقة متناهية (`exactAllowWhileIdle`).
- 🎨 **واجهة عصرية (Custom UI):** تصميم Material 3 بألوان داكنة راقية (Deep Slate & Amber/Sky) وشريط تنقل عائم (Floating Nav Bar).
- ⏱️ **ساعة حية ومؤقت سريع:** عداد رقمي حي يعرض الوقت والتاريخ بالعربية وتبويب للمؤقتات السريعة (Quick Presets).
- 🎛️ **تخصيص كامل:** اختيار النغمات، تكرار الأيام (كل يوم، أيام العمل، عطلة الأسبوع)، وتفعيل الاهتزاز.
- 💫 **أنيميشن سلس:** تأثير تكبير وتصغير للكروت النشطة وتأثير حركة ارتدادي لزر التأجيل (Snooze).
- 💾 **حفظ محلي:** حفظ جميع المنبهات وتفضيلات المستخدم محلياً عبر `shared_preferences`.

## 🚀 تشغيل المشروع
```bash
# تثبيت التبعيات
flutter pub get

# تشغيل التطبيق
flutter run
```

## 📦 استخراج ملف الـ APK
```bash
flutter build apk --release
```
ستجد الملف في:
`build/app/outputs/flutter-apk/app-release.apk`
