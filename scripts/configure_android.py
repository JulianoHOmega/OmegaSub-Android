# Patches Gradle Flutter generated in CI
from pathlib import Path
import re
import os

root = Path('android')
settings = root / 'settings.gradle.kts'
if not settings.exists():
    raise SystemExit('Esperado Flutter Android Kotlin DSL: android/settings.gradle.kts')
s = settings.read_text()
needle = 'id("com.chaquo.python") version "17.2.0" apply false'
if needle not in s:
    s = s.replace('plugins {', 'plugins {\n    ' + needle, 1)
settings.write_text(s)

app = root / 'app/build.gradle.kts'
s = app.read_text()
if 'id("com.chaquo.python")' not in s:
    s = s.replace('plugins {', 'plugins {\n    id("com.chaquo.python")', 1)
s = re.sub(r'(?m)^(\s*)minSdk\s*=.*$', r'\g<1>minSdk = 24', s, count=1)
if 'minSdk = 24' not in s:
    raise SystemExit('Não foi possível configurar minSdk')
# Add ABI filters for Python 3.11 on supported Android architectures.
s = s.replace('defaultConfig {', 'defaultConfig {\n        ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64") }', 1)
s += """

chaquopy {
    defaultConfig {
        version = "3.11"
        buildPython = System.getenv("OMEGASUB_BUILD_PYTHON") ?: "python3.11"
        pip {
            install("subliminal>=2.2,<3")
        }
    }
}
"""
app.write_text(s)
manifest = root / 'app/src/main/AndroidManifest.xml'
s = manifest.read_text()
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
manifest.write_text(s)
print('Chaquopy, SDK e Python configurados')

import shutil
python_dest = root / 'app/src/main/python'
python_dest.mkdir(parents=True, exist_ok=True)
shutil.copy2('native/python/omegasub_local.py', python_dest / 'omegasub_local.py')
kt_dest = root / 'app/src/main/kotlin/com/omegasub/omegasub_android'
kt_dest.mkdir(parents=True, exist_ok=True)
shutil.copy2('native/MainActivity.kt', kt_dest / 'MainActivity.kt')
