%% ========================================================================
%  DOKUZ EYLUL UNIVERSITY - EED4101 DIGITAL COMMUNICATION PROJECT #6
%  STAGE 1 ANA TEST SCRIPTI (asama1_test.m)
%
%  KULLANIM:
%  1. "dm_adm_encoder.m", "dm_adm_decoder.m" ve "asama1_test.m" dosyalarinin
%     ucunu de MATLAB'da AYNI KLASORE koyun.
%  2. Bu dosyayi (asama1_test.m) acip "Run" (F5) tusuna basin (veya
%     Command Window'a yapistirin). Icinde hicbir "function" tanimi
%     olmadigi icin hata vermeden dogrudan calisir.
% =========================================================================

clear; clc; close all;

%% 1. SINUZOIDAL TEST SINYALI OLUSTURMA
fs = 8000;                  % Ornekleme frekansi (Proje sartnamesi: 8000 Hz)
T_sim = 0.02;               % Gorsellestirme icin 20 ms sure (160 ornek)
t = 0:1/fs:(T_sim - 1/fs);  % Zaman vektoru

Am = 1.0;                   % Giris sinuzoidinin genligi (Volt)
fm = 200;                   % Giris sinuzoidinin frekansi (Hz)
x = Am * sin(2 * pi * fm * t); % Giris sinyali x(n)

% Teorik egim asimi (slope overload) siniri: delta_min = 2*pi*fm*Am / fs
delta_theoretical = (2 * pi * fm * Am) / fs;

%% 2. STANDART DM ICIN OPTIMUM ADIM BOYUTU (MAX SQNR) ARAMASI
delta_sweep = linspace(0.01, 0.60, 120);
sqnr_dm_list = zeros(size(delta_sweep));

for k = 1:length(delta_sweep)
    d_val = delta_sweep(k);
    bits_dm = dm_adm_encoder(x, d_val, 'DM');
    x_rec_dm = dm_adm_decoder(bits_dm, d_val, 'DM', fs, fm);
    
    q_error = x - x_rec_dm;
    sqnr_dm_list(k) = 10 * log10(sum(x.^2) / sum(q_error.^2));
end

[max_sqnr_dm, idx_opt] = max(sqnr_dm_list);
delta_opt = delta_sweep(idx_opt);

%% 3. OPTIMUM DM, DUSUK/YUKSEK DELTA VE ADM KARSILASTIRMASI
% a) Optimum Adim Boyutlu Standart DM
bits_dm_opt = dm_adm_encoder(x, delta_opt, 'DM');
[x_rec_dm_opt, x_stair_dm_opt] = dm_adm_decoder(bits_dm_opt, delta_opt, 'DM', fs, fm);

% b) Egim Asimi Gosterimi (Cok Kucuk Adim Boyutu: 0.30 * delta_opt)
delta_small = 0.30 * delta_opt;
bits_dm_small = dm_adm_encoder(x, delta_small, 'DM');
[x_rec_small, x_stair_small] = dm_adm_decoder(bits_dm_small, delta_small, 'DM', fs, fm);
sqnr_dm_small = 10 * log10(sum(x.^2) / sum((x - x_rec_small).^2));

% c) Tanecik Gurultusu Gosterimi (Cok Buyuk Adim Boyutu: 2.50 * delta_opt)
delta_large = 2.50 * delta_opt;
bits_dm_large = dm_adm_encoder(x, delta_large, 'DM');
[x_rec_large, x_stair_large] = dm_adm_decoder(bits_dm_large, delta_large, 'DM', fs, fm);
sqnr_dm_large = 10 * log10(sum(x.^2) / sum((x - x_rec_large).^2));

% d) Adaptif Delta Modulasyonu (ADM)
delta_init_adm = delta_small;
bits_adm = dm_adm_encoder(x, delta_init_adm, 'ADM');
[x_rec_adm, x_stair_adm, delta_history_adm] = dm_adm_decoder(bits_adm, delta_init_adm, 'ADM', fs, fm);
sqnr_adm = 10 * log10(sum(x.^2) / sum((x - x_rec_adm).^2));

%% 4. DINAMIK GENLIK DEGISIMINDE DM VE ADM PERFORMANSI
amp_factors = linspace(0.15, 2.5, 25);
sqnr_vs_amp_dm  = zeros(size(amp_factors));
sqnr_vs_amp_adm = zeros(size(amp_factors));

for m = 1:length(amp_factors)
    x_scaled = amp_factors(m) * x;
    
    b_dm = dm_adm_encoder(x_scaled, delta_opt, 'DM');
    xr_dm = dm_adm_decoder(b_dm, delta_opt, 'DM', fs, fm);
    sqnr_vs_amp_dm(m) = 10 * log10(sum(x_scaled.^2) / sum((x_scaled - xr_dm).^2));
    
    b_adm = dm_adm_encoder(x_scaled, delta_init_adm, 'ADM');
    xr_adm = dm_adm_decoder(b_adm, delta_init_adm, 'ADM', fs, fm);
    sqnr_vs_amp_adm(m) = 10 * log10(sum(x_scaled.^2) / sum((x_scaled - xr_adm).^2));
end

%% 5. SONUCLARI KOMUT PENCERESINE YAZDIRMA
fprintf('==============================================================\n');
fprintf('   EED4101 PROJE #6 - 1. ASAMA (DM & ADM) TEST SONUCLARI\n');
fprintf('==============================================================\n');
fprintf('Ornekleme Frekansi (fs)        : %d Hz\n', fs);
fprintf('Giris Sinuzoidi (Am, fm)       : %.2f V, %d Hz\n', Am, fm);
fprintf('Teorik Egim Asimi Siniri       : %.4f V\n', delta_theoretical);
fprintf('Deneysel Optimum Step Size (DM): %.4f V\n', delta_opt);
fprintf('Maksimum Standart DM SQNR      : %.2f dB\n', max_sqnr_dm);
fprintf('Kucuk Adimli (%.4f V) DM SQNR : %.2f dB (Slope Overload)\n', delta_small, sqnr_dm_small);
fprintf('Buyuk Adimli (%.4f V) DM SQNR : %.2f dB (Granular Noise)\n', delta_large, sqnr_dm_large);
fprintf('Adaptif DM (ADM) SQNR          : %.2f dB (Baslangic: %.4f V)\n', sqnr_adm, delta_init_adm);
fprintf('==============================================================\n');

%% 6. GRAFIKLERIN CIZDIRILMESI
figure('Name', 'Sekil 1 - DM Optimum Step Size ve SQNR Analizi', 'Color', 'w', 'Position', [100 100 850 420]);
plot(delta_sweep, sqnr_dm_list, 'b-', 'LineWidth', 2); hold on;
plot(delta_opt, max_sqnr_dm, 'ro', 'MarkerSize', 9, 'MarkerFaceColor', 'r');
line([delta_theoretical delta_theoretical], ylim, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.2);
grid on;
xlabel('Adim Boyutu (\Delta) [Volt]', 'FontWeight', 'bold');
ylabel('SQNR [dB]', 'FontWeight', 'bold');
title('Standart Delta Modulasyonunda Adim Boyutu (\Delta) - SQNR Iliskisi');
legend('DM SQNR Egrisi', sprintf('Optimum \\Delta = %.4f V (SQNR = %.2f dB)', delta_opt, max_sqnr_dm), ...
       'Teorik Sinir (\Delta_{min})', 'Location', 'best');

figure('Name', 'Sekil 2 - DM Bozulma Turleri ve Optimum DM', 'Color', 'w', 'Position', [120 120 900 720]);
subplot(3,1,1);
plot(t*1000, x, 'k--', 'LineWidth', 1.5); hold on;
stairs(t*1000, x_stair_small, 'r-', 'LineWidth', 1.4);
grid on;
title(sprintf('Cok Kucuk Adim Boyutu (\\Delta = %.4f V, SQNR = %.2f dB) -> Egim Asimi (Slope Overload)', delta_small, sqnr_dm_small));
ylabel('Genlik [V]');
legend('Giris Sinyali x(t)', 'DM Merdiven Tahmini', 'Location', 'northeast');

subplot(3,1,2);
plot(t*1000, x, 'k--', 'LineWidth', 1.5); hold on;
stairs(t*1000, x_stair_large, 'm-', 'LineWidth', 1.4);
grid on;
title(sprintf('Cok Buyuk Adim Boyutu (\\Delta = %.4f V, SQNR = %.2f dB) -> Tanecik Gurultusu (Granular Noise)', delta_large, sqnr_dm_large));
ylabel('Genlik [V]');
legend('Giris Sinyali x(t)', 'DM Merdiven Tahmini', 'Location', 'northeast');

subplot(3,1,3);
plot(t*1000, x, 'k--', 'LineWidth', 1.5); hold on;
stairs(t*1000, x_stair_dm_opt, 'b-', 'LineWidth', 1.2);
plot(t*1000, x_rec_dm_opt, 'g-', 'LineWidth', 1.8);
grid on;
title(sprintf('Optimum Adim Boyutlu DM (\\Delta_{opt} = %.4f V, SQNR = %.2f dB)', delta_opt, max_sqnr_dm));
xlabel('Zaman [ms]'); ylabel('Genlik [V]');
legend('Giris Sinyali x(t)', 'Merdiven (Staircase) Cikisi', 'LPF Sonrasi Geri Catilan Sinyal', 'Location', 'northeast');

figure('Name', 'Sekil 3 - Adaptif Delta Modulasyonu (ADM) Performansi', 'Color', 'w', 'Position', [150 150 900 720]);
subplot(3,1,1);
plot(t*1000, x, 'k--', 'LineWidth', 1.5); hold on;
stairs(t*1000, x_stair_adm, 'b-', 'LineWidth', 1.2);
plot(t*1000, x_rec_adm, 'r-', 'LineWidth', 1.8);
grid on;
title(sprintf('Adaptif Delta Modulasyonu (ADM) Takibi ve Geri Catilan Sinyal (SQNR = %.2f dB)', sqnr_adm));
ylabel('Genlik [V]');
legend('Giris Sinyali x(t)', 'ADM Merdiven Tahmini', 'ADM Geri Catilan Sinyal', 'Location', 'northeast');

subplot(3,1,2);
stairs(t*1000, delta_history_adm, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.5);
grid on;
title('ADM Algoritmasinin Zamana Gore Degisen Dinamik Adim Boyutu \Delta(n)');
xlabel('Zaman [ms]'); ylabel('\Delta(n) [V]');

subplot(3,1,3);
plot(20*log10(amp_factors), sqnr_vs_amp_dm, 'b-s', 'LineWidth', 1.8, 'MarkerSize', 5); hold on;
plot(20*log10(amp_factors), sqnr_vs_amp_adm, 'r-o', 'LineWidth', 1.8, 'MarkerSize', 5);
grid on;
title('Giris Sinyali Genlik Degisimine Karsi DM ve ADM Dinamik Aralik Karsilastirmasi');
xlabel('Giris Genligi Olcegi [dB]'); ylabel('SQNR [dB]');
legend('Sabit Adimli DM', 'Adaptif DM (ADM)', 'Location', 'southwest');
