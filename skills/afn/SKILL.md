---
name: afn
description: Use when user invokes /afn with ANY request - a single sentence, a spec file, a bug report, a feature request, or no arguments (to resume). Fully autonomous agent that detects context, researches, designs, plans, implements, and verifies without unnecessary questions. Works for any project type. Persists state to .afn/ directory for cross-context resume.
---

# AFN - Autonomous Full Intelligence

Tam otonom gelistirme ajansi. Kullanici ne istedigini soyler, gerisi otomatik.
Her proje tipi, her boyut, her karmasiklik seviyesi. Kullanicinin aklina gelmeyen seyleri de yapar.
Context siniri yok — state persist eder, yeni oturumda kaldigindan devam eder.

## Kullanim

**Terminal'den (otonom dongu — context siniri YOK):**
```bash
afn "Bana radyo sitesi yap"         # Yeni proje — bitene kadar dongu
afn                                  # Devam — kaldigi yerden surer
afn "yeni: E-ticaret sitesi yap"    # Sifirdan basla
```
Bu komut `afn-loop.sh` script'ini calistirir. Claude context dolunca otomatik yeni context acar.
Tum gorevler tamamlanana kadar DURMAZ. Durdurmak icin: Ctrl+C

**Claude oturumu icinden (tek context):**
```
/afn Bana radyo sitesi yap          # Yeni proje baslatir
/afn requirements.md                 # Spec dosyasindan baslatir
/afn Bu bug'i duzelt: X calismıyor   # Bug fix modu
/afn Mevcut projeye dark mode ekle   # Feature ekleme modu
/afn                                 # DEVAM — kaldigi yerden surer
/afn yeni: E-ticaret sitesi yap      # Mevcut state'i arsivler, sifirdan baslar
```

## Giris Akisi — Her Cagri Bununla Baslar

```dot
digraph entry {
  rankdir=TB;
  node [fontsize=11];

  "afn cagrildi" [shape=box];
  ".afn/STATE.md var mi?" [shape=diamond];
  "Arguman var mi?" [shape=diamond];
  "DEVAM MODU" [shape=box, style=bold, color=blue];
  "'yeni:' ile mi basliyor?" [shape=diamond];
  "Eski state'i arsivle" [shape=box];
  "YENI PROJE MODU" [shape=box, style=bold, color=green];

  "afn cagrildi" -> ".afn/STATE.md var mi?";
  ".afn/STATE.md var mi?" -> "Arguman var mi?" [label="evet"];
  ".afn/STATE.md var mi?" -> "Arguman var mi?" [label="hayir"];
  "Arguman var mi?" -> "DEVAM MODU" [label="hayir + state var"];
  "Arguman var mi?" -> "'yeni:' ile mi basliyor?" [label="evet"];
  "Arguman var mi?" -> "YENI PROJE MODU" [label="hayir + state yok"];
  "'yeni:' ile mi basliyor?" -> "Eski state'i arsivle" [label="evet"];
  "'yeni:' ile mi basliyor?" -> "YENI PROJE MODU" [label="hayir + state yok"];
  "'yeni:' ile mi basliyor?" -> "Eski state'i arsivle" [label="hayir + state var (sor)"];
  "Eski state'i arsivle" -> "YENI PROJE MODU";
}
```

## State Yonetimi (.afn/ dizini)

Tum state proje dizininde `.afn/` klasorunde tutulur. Context sifirlandiginda buradan kurtarilir.

### Dosya yapisi:
```
.afn/
  STATE.md          # Ana durum dosyasi — her zaman guncel
  DESIGN.md         # Tasarim kararlari, stil rehberi
  RESEARCH.md       # Arastirma sonuclari ozeti
  archive/          # Onceki calismalarin arsivi
    2026-03-15_radyo-sitesi/
```

### STATE.md formati:
```markdown
# AFN State

## Proje
- **Tanim:** Radyo sitesi
- **Tip:** Sifirdan proje (web)
- **Tech stack:** Next.js + Tailwind
- **Baslangic:** 2026-03-15
- **Dizin:** /home/afn7/Creativity/radio-site

## Mevcut Faz
UYGULA (Faz 4)

## Gorevler
- [x] Proje iskeleti olustur
- [x] Ana layout + navigasyon
- [x] Ana sayfa
- [ ] Canli yayin sayfasi        ← SIRADAKI
- [ ] Program akisi sayfasi
- [ ] Hakkimizda sayfasi
- [ ] SEO + meta tags
- [ ] Final tarama

## Son Durum
Canli yayin sayfasi baslanacak. Audio player komponenti yazilacak.

## Blocker
(yok)

## Kararlar Loglari
- Next.js secildi: SSR + SEO uyumu icin
- Tailwind secildi: hizli UI gelistirme
- Renk paleti: koyu mavi (#1a1a2e) + turuncu (#e94560)
```

### State guncelleme kurallari:
- Her gorev tamamlandiginda STATE.md guncelle
- Her faz gecisinde guncelle
- Blocker olustu/cozulduyse guncelle
- DESIGN.md'yi sadece tasarim fazinda yaz, sonra referans olarak kullan
- STATE.md KISA ve OKUNABILIR tutulmali — roman degil, durum raporu

## DEVAM MODU

`/afn` argumansiz cagrildiginda veya yeni context'te:

1. `.afn/STATE.md` oku
2. `.afn/DESIGN.md` oku (tasarim referansi icin)
3. Mevcut fazi ve siradaki gorevi belirle
4. Kullaniciya 1 satirlik durum ver: `"Devam ediyorum: Canli yayin sayfasi (4/8 gorev tamam)"`
5. Kaldigin yerden HEMEN devam et — soru sorma

## Core Loop

```dot
digraph afn {
  rankdir=TB;
  node [fontsize=11];

  "BAGLAM TOPLA" [shape=box];
  "SINIFLA" [shape=diamond];
  "ARASTIR" [shape=box, style=bold];
  "TASARLA + DESIGN.md" [shape=box, style=bold];
  "PLANLA + STATE.md" [shape=box, style=bold];
  "UYGULA" [shape=box, style=bold];
  "DOGRULA" [shape=diamond, style=bold];
  "ISARETLE + STATE guncelle" [shape=box];
  "Kalan var mi?" [shape=diamond];
  "FINAL TARAMA" [shape=box, style=bold];
  "TESLIM" [shape=doublecircle];

  "BAGLAM TOPLA" -> "SINIFLA";
  "SINIFLA" -> "ARASTIR";
  "ARASTIR" -> "TASARLA + DESIGN.md";
  "TASARLA + DESIGN.md" -> "PLANLA + STATE.md";
  "PLANLA + STATE.md" -> "UYGULA";
  "UYGULA" -> "DOGRULA";
  "DOGRULA" -> "ISARETLE + STATE guncelle" [label="OK"];
  "DOGRULA" -> "UYGULA" [label="tekrar"];
  "ISARETLE + STATE guncelle" -> "Kalan var mi?";
  "Kalan var mi?" -> "UYGULA" [label="evet"];
  "Kalan var mi?" -> "FINAL TARAMA" [label="hayir"];
  "FINAL TARAMA" -> "UYGULA" [label="eksik bulundu"];
  "FINAL TARAMA" -> "TESLIM" [label="tamam"];
}
```

## FAZ 0: BAGLAM TOPLAMA

Herhangi bir is yapmadan ONCE:

**Ortam tespiti (paralel calistir):**
- `pwd` + `ls` — neredeyiz, ne var?
- `git status` — repo mu, branch ne?
- `cat package.json / requirements.txt / go.mod` vb. — mevcut stack
- `cat CLAUDE.md` — proje kurallari
- `.afn/STATE.md` var mi? — devam durumu
- Memory sistemi kontrol et — kullanici tercihleri

**Proje siniflandirmasi:**

| Sinif | Tespit | Davranis |
|-------|--------|----------|
| **Sifirdan proje** | Bos dizin veya yeni isim | Tam arastirma + tasarim + uygulama |
| **Mevcut projeye ekleme** | package.json vb. var | Mevcut stack'e uy, stilleri koru |
| **Bug duzeltme** | "bug", "calismıyor", "hata" | Sistematik debug, root cause bul |
| **Refactor** | "refactor", "temizle", "iyilestir" | Davranisi koru, yapiyi duzelt |
| **Ozellik ekleme** | "ekle", "yeni", "istiyorum" | Mevcut mimariyle uyumlu ekle |
| **Spec dosyasi** | .md dosyasi verilmis | Dosyadaki tum maddeleri uygula |
| **Devam** | .afn/STATE.md mevcut | Kaldigindan devam et |

## FAZ 1: ARASTIR (Proje tipine gore uyarlanir)

Agent tool ile PARALEL arastir. Sonuclari `.afn/RESEARCH.md`'ye yaz.

**Sifirdan proje (4 agent):**

| Agent | Gorev |
|-------|-------|
| Domain | Bu tur projeler nasil yapilir? Referanslar, standartlar (WebSearch) |
| Teknik | En uygun tech stack, kutuphaneler, API'ler (context7 ile guncel docs) |
| UX/Tasarim | Kullanici beklentileri, layout kaliplari, gorsel dil, renk, tipografi |
| Altyapi | SEO, performans, guvenlik, erisilebilirlik, test stratejisi |

**Mevcut projeye ekleme (2 agent):**

| Agent | Gorev |
|-------|-------|
| Codebase | Mevcut mimari, stiller, konvansiyonlar (Explore agent) |
| Teknik | Gerekli kutuphane/API, mevcut stack uyumlulugu |

**Bug duzeltme (1-2 agent):**

| Agent | Gorev |
|-------|-------|
| Debug | Hata mesajlari, loglar, root cause arastirmasi |
| Codebase | Ilgili kod parcalari, data flow (Explore agent) |

**CLI/Backend/Script (2 agent):**

| Agent | Gorev |
|-------|-------|
| Domain | Benzer araclar, best practices, UX kaliplari |
| Teknik | Kutuphaneler, API'ler, performans, test stratejisi |

## FAZ 2: TASARLA

Sonuclari `.afn/DESIGN.md`'ye yaz. Proje tipine gore:

**Sifirdan proje:** Dizin yapisi, sayfa listesi, komponent hiyerarsisi, DB semasi, API endpoint'leri, renk paleti, font, spacing, animasyon kurallari, responsive strateji

**Mevcut projeye ekleme:** Mevcut yapiyla uyumlu mimari, etkilenen dosyalar, stil uyumu

**Bug duzeltme:** Root cause analizi, fix stratejisi, regression test plani

**Refactor:** Mevcut davranis haritasi, hedef yapi, gecis plani

## FAZ 3: PLANLA

- Tasarimi somut gorevlere bol
- `.afn/STATE.md` olustur — gorev listesi ile
- TodoWrite ile her gorevi kaydet
- Bagimlilik sirasi belirle, paralel yapilabilecekleri isaretle
- Kullaniciya KISA plan goster (basliklar), hemen basla

## FAZ 4: UYGULA DONGUSU

Her gorev icin:

**a) Hazirlik:** Bagimliliklari kur (SORMADAN), dizinleri olustur, config ayarla

**b) Uygula:** Kod yaz/duzenle, stil uygula, GERCEKCI icerik ekle, testleri yaz

**c) Dogrula:**

| Proje tipi | Dogrulama |
|------------|-----------|
| Web/UI | build + lint + screenshot (cdp-screenshot varsa) |
| API/Backend | build + lint + test + curl ile endpoint test |
| CLI | build + ornek komut + cikti kontrol |
| Script | calistir + cikti kontrol |
| Bug fix | hatanin tekrarlanmadigini dogrula + regression test |
| Refactor | tum testler gecmeli + davranis degismemeli |

**d) Isaretle:** TodoWrite "completed" + STATE.md guncelle + 1 satir status

## FAZ 5: FINAL TARAMA

**Her proje icin:**
- Tum dosyalar gozden gecir — eksik, yanlis, unutulan?
- Entegrasyon kontrolu — parcalar birlikte calisiyor mu?
- Build/test basarili mi?
- Gereksiz console.log, debug kodu, TODO yorumlari?

**Web/UI ek:** Responsive, SEO (meta/OG/structured data/sitemap), favicon, 404, loading/error states, dark mode, erisilebilirlik, performans

**API/Backend ek:** Tum endpoint'ler, error handling (400/401/404/500), input validation, CORS

**CLI ek:** --help, hatali input handling, exit code'lar

Eksik varsa: geri don, duzelt, dogrula. FINAL TARAMA temiz cikana kadar tekrarla.

## FAZ 6: TESLIM

- Yapilanlarin kisa ozeti
- Dosya listesi (olusturulan + degistirilen)
- Calistirma talimatlari
- Bilinen kisitlamalar (varsa)
- Gelecek iyilestirme onerileri (kisa)
- STATE.md'yi "TAMAMLANDI" olarak guncelle
- Git commit onerisi

## ORTAM KURALLARI

| Ortam | Kural |
|-------|-------|
| **WSL1** | Linux tarayici ACILMAZ. cdp-screenshot veya Windows Chrome kullan |
| **Git repo** | Mevcut branch'te calis, sonda commit oner. Force push YAPMA |
| **Mevcut proje** | Tech stack DEGISTIRME. Mevcut konvansiyonlara UY |
| **Bos dizin** | git init + .gitignore ile basla |
| **Memory** | Kullanici tercihlerini kontrol et, uy |

## KENDIN KARAR VER — SORMA

| Karar | Yaklasim |
|-------|----------|
| Tech stack | Proje amacina en uygun, modern, stabil |
| Gorsel tasarim | Projenin ruhuna uygun, profesyonel, ozgun |
| Renkler + Font | Amac uyumlu, okunabilir |
| Icerik | Gercekci, anlamli (Lorem ipsum YASAK) |
| Dosya yapisi | Olceklenebilir, temiz, standart |
| Test stratejisi | Kritik is mantigi = test yaz. Trivial = yazma |
| Bagimliliklar | Gerekeni kur, sormadan |
| Eksik ozellikler | 404, favicon, loading, error states, README — gerekeni ekle |

## KURALLAR

1. **DURMA YASAGI:** Tum isler bitmeden ASLA "bitti" deme. Bahane GECERSIZ.
2. **SORU MINIMIZASYONU:** Sadece KRITIK belirsizliklerde sor. Geri kalani kendin karar ver.
3. **DOGRULAMA ZORUNLU:** Her gorev sonrasi dogrula. Dogrulamasiz gecis YOK.
4. **SESSIZ CALISMA:** 1 satir status, devam et. Roman yazma.
5. **HATA TOLERANSI:** 3 basarisiz deneme → kullaniciya sor. Sessizce atlama.
6. **ATOMIK ILERLEME:** Her gorev bittikce isaretle + STATE.md guncelle.
7. **PARALEL CALISMA:** Bagimsiz isler icin Agent tool kullan.
8. **GERCEKCI ICERIK:** Lorem ipsum, TODO, placeholder, coming soon YASAK.
9. **PROFESYONEL KALITE:** AI yapti belli olmamali.
10. **EKSIK DUSUNME:** Kullanicinin aklina gelmeyen gerekli seyleri ekle.
11. **MEVCUT KODA SAYGI:** Mevcut stil/stack/konvansiyona uy.
12. **BAGIMLILIK YONETIMI:** Paketleri SORMADAN kur.
13. **STATE PERSIST:** Her adimda .afn/STATE.md guncelle. Context olurse devam edilebilmeli.
14. **DONGU KARARLILIGI:** Context siniri yaklastiginda STATE.md'yi son kez guncelle. `afn-loop.sh` otomatik yeni context acar — kullanicinin bir sey yapmasina gerek yok.
15. **TEMIZ CIKIS:** Isler bitmeden context kapanacaksa, STATE.md'de "Son Durum" kismini net yaz ki yeni context tam nereden devam edecegini bilsin. Yarim kalmis dosyalari, partial kodu belirt.

## CONTEXT GECIS PROTOKOLU

Context dolmaya yaklastiginda (veya `afn-loop.sh` ile calisiyorsan her context sonunda):

1. Mevcut gorevi MUMKUNSE tamamla (yarim birakma)
2. STATE.md'yi guncelle:
   - Tamamlanan gorevleri [x] isaretle
   - "Son Durum" kismina: tam olarak ne yapildi, ne yarim kaldi
   - "Siradaki" kismina: bir sonraki adim ne
3. Yarim kalan dosya varsa belirt (path + ne eksik)
4. SESSIZCE cik — kullaniciya uzun veda mesaji yazma

Yeni context basladiginda:
1. `.afn/STATE.md` oku
2. `.afn/DESIGN.md` oku
3. Yarim kalan dosyalari kontrol et
4. 1 satir status ver, HEMEN devam et
