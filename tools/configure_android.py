"""Set the Android launcher label (the Flutter scaffold is created by CI)."""
from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
text = manifest.read_text(encoding="utf-8")
if 'android:label="mayak"' not in text:
    raise SystemExit("Generated AndroidManifest.xml label pattern changed")
manifest.write_text(
    text.replace('android:label="mayak"', 'android:label="Маяк"'),
    encoding="utf-8",
)
print("Android app label: Маяк")
