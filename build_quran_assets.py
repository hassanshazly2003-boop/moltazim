import json, re, sys
from pathlib import Path

# Input: a Tanzil-style quran-uthmani.txt where each line is SURA|AYA|TEXT.
# The Quran text must not be edited; this script only restructures it for Flutter.
SURAH_NAMES = [
'الفاتحة','البقرة','آل عمران','النساء','المائدة','الأنعام','الأعراف','الأنفال','التوبة','يونس','هود','يوسف','الرعد','إبراهيم','الحجر','النحل','الإسراء','الكهف','مريم','طه','الأنبياء','الحج','المؤمنون','النور','الفرقان','الشعراء','النمل','القصص','العنكبوت','الروم','لقمان','السجدة','الأحزاب','سبأ','فاطر','يس','الصافات','ص','الزمر','غافر','فصلت','الشورى','الزخرف','الدخان','الجاثية','الأحقاف','محمد','الفتح','الحجرات','ق','الذاريات','الطور','النجم','القمر','الرحمن','الواقعة','الحديد','المجادلة','الحشر','الممتحنة','الصف','الجمعة','المنافقون','التغابن','الطلاق','التحريم','الملك','القلم','الحاقة','المعارج','نوح','الجن','المزمل','المدثر','القيامة','الإنسان','المرسلات','النبأ','النازعات','عبس','التكوير','الانفطار','المطففين','الانشقاق','البروج','الطارق','الأعلى','الغاشية','الفجر','البلد','الشمس','الليل','الضحى','الشرح','التين','العلق','القدر','البينة','الزلزلة','العاديات','القارعة','التكاثر','العصر','الهمزة','الفيل','قريش','الماعون','الكوثر','الكافرون','النصر','المسد','الإخلاص','الفلق','الناس'
]

src, out = map(Path, sys.argv[1:3])
surahs = [{'id': i+1, 'name': n, 'ayahCount': 0, 'verses': []} for i,n in enumerate(SURAH_NAMES)]
for line in src.read_text(encoding='utf-8').splitlines():
    if not line or '|' not in line: continue
    sid, aid, text = line.split('|', 2)
    s = surahs[int(sid)-1]
    s['verses'].append({'ayah': int(aid), 'text': text})
    s['ayahCount'] += 1
assert sum(s['ayahCount'] for s in surahs) == 6236
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({'source':'Tanzil Project Uthmani','surahs':surahs}, ensure_ascii=False, separators=(',',':')), encoding='utf-8')
print(out)
