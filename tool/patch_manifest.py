#!/usr/bin/env python3
"""افزودن مجوزهای لازم و برچسب فارسی به AndroidManifest.xml (فقط زمان CI اجرا می‌شود)"""
import re
import pathlib
import sys

manifest_path = pathlib.Path('android/app/src/main/AndroidManifest.xml')
if not manifest_path.exists():
    print('ERROR: AndroidManifest.xml not found')
    sys.exit(1)

s = manifest_path.read_text(encoding='utf-8')

permissions = [
    'android.permission.ACTIVITY_RECOGNITION',
    'android.permission.VIBRATE',
]

inject = ''
for perm in permissions:
    if perm not in s:
        inject += f'    <uses-permission android:name="{perm}" />\n'

if 'android.hardware.sensor.stepcounter' not in s:
    inject += '    <uses-feature android:name="android.hardware.sensor.stepcounter" android:required="false" />\n'

if inject:
    s = re.sub(r'(<manifest[^>]*>)', r'\1\n' + inject.rstrip('\n'), s, count=1)

if 'android:label=' in s:
    s = re.sub(r'android:label="[^"]*"', 'android:label="پایش سلامت"', s, count=1)

manifest_path.write_text(s, encoding='utf-8')
print('Manifest patched OK')
