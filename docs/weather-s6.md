# Weather Detail — Step 6 · เพิ่ม cool + snow (ตัวอย่างการขยาย template)

## เป้าหมายของสเต็ป
- เพิ่ม **2 สภาพอากาศใหม่** (`cool`, `snow`) พร้อม SVG ของตัวเอง
- **แสดงวิธี extend template** ที่วางไว้ในสเต็ป s2 — เพิ่ม case แล้วให้ compiler บอกว่ายังต้องแก้ตรงไหน
- Preview ได้ทันทีใน mock forecast

## ไฟล์ที่เปลี่ยน / สร้าง

| ไฟล์ | สิ่งที่ทำ |
|---|---|
| `assets/illustrations/weather/cool.svg` | ภาพ 3 wind swirls สไตล์เซน (สายลมเย็น) |
| `assets/illustrations/weather/snow.svg` | ภาพเกล็ดหิมะใหญ่ + เกล็ดเล็ก 4 ตัวลอยรอบ |
| `lib/features/weather/models/weather_condition.dart` | เพิ่ม `cool`, `snow` ใน enum + assetPath + shortLabel + palette + mapping ใน fromApi |
| `lib/features/weather/widgets/weather_detail_screen.dart` | Mock forecast — เปลี่ยน tue เป็น cool, fri เป็น snow |

## Palette ใหม่

| condition | background | ink | accent | อารมณ์ |
|---|---|---|---|---|
| `cool` | `#EDE7DA` cream | `#2E3B47` slate | `#4A6572` teal | หมอกเช้า / ลมเย็น |
| `snow` | `#F1F3F5` เกือบขาว | `#243447` navy | `#3E5B78` icy blue | เย็นสะอาด |

## API mapping ที่เพิ่ม (`fromApi`)

```dart
if (apiCondition == 'Snow') return WeatherCondition.snow;
if (['Mist','Fog','Haze','Smoke','Clouds'].contains(apiCondition)) {
  return WeatherCondition.cool;
}
```

- `"Snow"` จาก OpenWeatherMap → snow (ตรงตัว)
- `"Mist"`, `"Fog"`, `"Haze"`, `"Smoke"`, `"Clouds"` ทั้งหมด → cool  
  (บ้าน editorial mood = "หมอกเช้าเย็นสบาย" ไม่ต้องแยก 5 แบบให้ผู้ใช้เห็น)

## จุดสำคัญที่ควรจำจากสเต็ปนี้

### 1. Compiler เป็นเพื่อนที่ดีที่สุด
พอเพิ่ม case ใหม่ใน enum ทันทีที่ save Dart analyzer จะฟ้อง **ทุก switch** ที่ยังไม่ handle case ใหม่ (ที่ `assetPath`, `shortLabel`, `palette`) — ไม่มีทางลืม  
นี่คือเหตุผลที่ s2 เลือกใช้ enum + `switch pattern` ตั้งแต่แรก ไม่ใช่ Map<String, ...>

### 2. เพิ่ม condition ใหม่ = แก้ไฟล์เดียว (+ SVG asset)
- ไม่ต้องแตะ `hero_illustration.dart`
- ไม่ต้องแตะ `weather_detail_screen.dart` (นอกจากอยากใส่ใน mock forecast)
- ไม่ต้องแตะ `day_selector.dart`
- ไม่ต้องแตะ `paper_background.dart`

เพราะทุก widget อ่านจาก `WeatherCondition.palette` / `.assetPath` / `.shortLabel` เท่านั้น

**นี่คือประโยชน์ของ Mapping Layer จาก s2** — ตอนออกแบบใช้เวลามากขึ้นหน่อย แต่คืนทุนตอนต้อง extend

### 3. Template นี้ใช้ได้ทันที
คุณเอาไปใช้ได้เลย — เปิด `flutter run` แล้วแตะการ์ด "สภาพอากาศ" บน dashboard จะเห็น 6 วันในแถบล่าง แต่ละวัน tap แล้ว hero + palette เปลี่ยนตาม

## วิธีเพิ่ม condition ที่ 6, 7, 8, ... ในอนาคต

ทำ 3 ขั้นแค่นี้:

1. **วาง SVG ใหม่** ใน `assets/illustrations/weather/` (viewBox `0 0 400 400`, filename เป็น kebab-case)
2. **เพิ่ม case ใน enum** `WeatherCondition` — analyzer จะบอกทันทีว่ายังต้องเพิ่ม `assetPath`/`shortLabel`/`palette` ตรงไหน
3. **เพิ่มใน `fromApi`** ถ้า OpenWeatherMap ส่ง string ที่ควร map ไปสู่ condition นี้

ไม่ต้องแก้ widget หน้า detail เลย เพราะทุก layer ผูกกับ enum

## Verify
- `flutter analyze` → **No issues found**
- SVG ใหม่โหลดได้ ไม่ต้องรัน `flutter pub get` ใหม่ (แค่ hot restart ก็เห็น เพราะ pubspec assets ประกาศเป็น **ทั้ง folder** ตั้งแต่ s1)

## ต่อไป (ถ้าอยากขยาย)
- เพิ่ม `thunder.svg` (พายุ) — currently รวมกับ rainy
- เพิ่ม `windy.svg` แยกจาก cool ถ้าอยากได้ 2 อารมณ์ต่างกัน
- ทำ `AnimatedSwitcher` ครอบ HeroIllustration เพื่อ crossfade ระหว่างเปลี่ยนวัน
