#  Dijital Haberleşme Sistemi Simülasyonu (8-PSK & AWGN)

##  Proje Hakkında
Bu proje, Dokuz Eylül Üniversitesi Mühendislik Fakültesi Elektrik-Elektronik Mühendisliği Bölümü EED4101 Dijital Haberleşme dersi kapsamında geliştirilmiştir . Çalışmanın temel amacı, uçtan uca bir dijital haberleşme sisteminin MATLAB üzerinde simüle edilmesidir. 

Proje; kaynak sinyalinin alınması, delta modülasyonu, kanal kodlaması, temel bant dijital modülasyon ve kanal gürültüsü altındaki performansın analiz edilmesini içermektedir.

##  Temel Özellikler ve Sistem Bileşenleri
* **Kaynak Sinyali:** MATLAB kullanılarak 8000 Hz örnekleme frekansında 10 saniyelik ses dalgası kaydı.
* **Delta Modülasyonu (DM/ADM):** Sinyal-kuantalama gürültü oranını (SQNR) maksimize eden Delta Modülatörü ve değişken adım boyutuna sahip Adaptif Delta Modülasyonu.
* **Kanal Kodlama:** 1/3 oranlı sistematik olmayan  konvolüsyonel kodlama ve alıcı tarafında orijinal mesajı elde etmek için Viterbi kod çözme algoritması.
* **Modülasyon ve Demodülasyon:** Gray mapping tekniği kullanan 8-ary Phase Shift Keying (8-PSK) modülasyonu. Demodülasyon için maksimum olabilirlik  karar algoritması kullanılmıştır.
* **Kanal:** Toplanabilir Beyaz Gauss Gürültüsü.
* **Arayüz:** Tüm sistem bileşenlerinin ve giriş parametrelerinin kontrol edilebildiği Grafiksel Kullanıcı Arayüzü.

##  Sistem Blok Diyagramı İşleyişi
Sistem sırasıyla şu bloklardan oluşmaktadır:
1. Ses Kaynağı 
2. Delta Modülasyon Kodlayıcı
3. Kanal Kodlayıcı
4. Modülatör (8-PSK)
5. Kanal (AWGN)
6. Demodülatör
7. Kanal Kod Çözücü (Viterbi)
8. Delta Modülasyon Kod Çözücü
9. Veri Çıkışı 

##  Performans Analizi
Proje, dijital haberleşme sisteminin başarımını ölçmek için Bit Hata Oranı (BER) ile Sinyal-Gürültü Oranı (SNR) karşılaştırması yapmaktadır.
* AWGN gücü değiştirilerek 0 dB ile 10 dB arasında 1 dB'lik adımlarla farklı SNR değerleri elde edilmiştir.
* Sistem performansı, logaritmik BER eksenine sahip BER vs. SNR grafikleri çizdirilerek analiz edilmiştir.

##  Nasıl Çalıştırılır?
1. Repoyu bilgisayarınıza klonlayın.
2. MATLAB'i açın ve proje dizinine gidin.
3. MATLAB üzerinden GUI dosyasını (`proje6_gui.m`) çalıştırın.
4. Arayüz üzerinden giriş parametrelerini belirleyin veya test ses dosyasını yükleyin.
5. Simülasyonu başlatıp SNR ve BER analiz sonuçlarını grafikler üzerinden inceleyin.

