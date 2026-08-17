# تشغيل بناء APK على GitHub

1. ارفع كل ملفات هذا المشروع إلى Repository جديد.
2. اعمل Commit على فرع `main`.
3. افتح تبويب **Actions**.
4. اختار **Build Moltazem APK**.
5. اضغط **Run workflow** إذا لم يبدأ تلقائيًا.
6. بعد نجاح البناء افتح الـWorkflow ثم قسم **Artifacts**.
7. نزّل `moltazem-release-apk` وستجد داخله `app-release.apk`.

ملاحظة:
- الدفع الحقيقي غير موصول في هذه النسخة.
- المصحف واللوجو موجودان داخل `assets/`.
- بناء Android يتم داخل GitHub Actions تلقائيًا، لذلك لا تحتاج Android Studio على الهاتف.
