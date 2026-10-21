#  Dijital Haberleşme Sistemi Simülasyonu (8-PSK & AWGN)

##  Proje Hakkında
Bu proje, Dokuz Eylül Üniversitesi Mühendislik Fakültesi Elektrik-Elektronik Mühendisliği Bölümü EED4101 Dijital Haberleşme (Digital Communication) dersi 2015 Güz dönemi 6 numaralı projesi kapsamında geliştirilmiştir [cite: 1]. Çalışmanın temel amacı, uçtan uca bir dijital haberleşme sisteminin MATLAB üzerinde simüle edilmesidir [cite: 2]. 

Proje; kaynak sinyalinin alınması, delta modülasyonu, kanal kodlaması, temel bant dijital modülasyon ve kanal gürültüsü altındaki performansın analiz edilmesini içermektedir [cite: 2].

##  Temel Özellikler ve Sistem Bileşenleri
* **Kaynak Sinyali (Source):** MATLAB kullanılarak 8000 Hz örnekleme frekansında 10 saniyelik ses dalgası kaydı [cite: 2].
* **Delta Modülasyonu (DM/ADM):** Sinyal-kuantalama gürültü oranını (SQNR) maksimize eden Delta Modülatörü ve değişken adım boyutuna sahip Adaptif Delta Modülasyonu [cite: 2].
* **Kanal Kodlama (Channel Encoder/Decoder):** 1/3 oranlı sistematik olmayan  konvolüsyonel kodlama ve alıcı tarafında orijinal mesajı elde etmek için Viterbi kod çözme algoritması [cite: 2].
* **Modülasyon ve Demodülasyon:** Gray mapping (Gray haritalama) tekniği kullanan 8-ary Phase Shift Keying (8-PSK) modülasyonu[cite: 2, 3]. Demodülasyon için maksimum olabilirlik  karar algoritması kullanılmıştır [cite: 3].
* **Kanal (Channel):** Toplanabilir Beyaz Gauss Gürültüsü [cite: 2].
* **Arayüz:** Tüm sistem bileşenlerinin ve giriş parametrelerinin kontrol edilebildiği Grafiksel Kullanıcı Arayüzü (GUI) [cite: 4].

##  Kullanılan Teknolojiler ve Kısıtlamalar
* **Yazılım:** MATLAB[cite: 2].
* **Geliştirme Kriteri:** Sistem blok diyagramındaki her bir modül için MATLAB Communication Toolbox'taki hazır fonksiyonlar **kullanılmamış**, tüm algoritmalar sıfırdan özgün fonksiyonlar olarak yazılmıştır[cite: 3].

##  Sistem Blok Diyagramı İşleyişi
Sistem sırasıyla şu bloklardan oluşmaktadır[cite: 2]:
1. Ses Kaynağı [cite: 2]
2. Delta Modülasyon Kodlayıcı[cite: 2]
3. Kanal Kodlayıcı[cite: 2]
4. Modülatör (8-PSK)[cite: 2]
5. Kanal (AWGN)[cite: 2]
6. Demodülatör[cite: 2]
7. Kanal Kod Çözücü (Viterbi)[cite: 2]
8. Delta Modülasyon Kod Çözücü[cite: 2]
9. Veri Çıkışı [cite: 2]

##  Performans Analizi
Proje, dijital haberleşme sisteminin başarımını ölçmek için Bit Hata Oranı (BER) ile Sinyal-Gürültü Oranı (SNR) karşılaştırması yapmaktadır[cite: 2].
* AWGN gücü değiştirilerek 0 dB ile 10 dB arasında 1 dB'lik adımlarla farklı SNR değerleri elde edilmiştir[cite: 4].
* Sistem performansı, logaritmik BER eksenine sahip BER vs. SNR grafikleri çizdirilerek analiz edilmiştir[cite: 4].

##  Nasıl Çalıştırılır?
1. Repoyu bilgisayarınıza klonlayın.
2. MATLAB'i açın ve proje dizinine gidin.
3. MATLAB üzerinden GUI dosyasını (`proje6_gui.m`) çalıştırın[cite: 4].
4. Arayüz üzerinden giriş parametrelerini belirleyin veya test ses dosyasını yükleyin[cite: 4].
5. Simülasyonu başlatıp SNR ve BER analiz sonuçlarını grafikler üzerinden inceleyin.

