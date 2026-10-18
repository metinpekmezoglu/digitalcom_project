%% ========================================================================
%  DOKUZ EYLUL UNIVERSITY - EED4101 DIGITAL COMMUNICATION PROJECT #6
%  STAGE 3 ANA TEST SCRIPTI (asama3_test.m)
%  1/3 Convolutional Encoder (Sekil 2) & Viterbi Decoder Testi ve
%  1. Ara Rapor (Kodlamasiz 8-PSK) ile Performans Karsilastirmasi
%
%  KULLANIM:
%  1. "conv_encoder.m", "viterbi_decoder.m", "psk8_modulator.m",
%     "psk8_demodulator.m" ve "asama3_test.m" dosyalarini AYNI KLASORE koyun.
%  2. Bu dosyayi (asama3_test.m) acip "Run" (F5) tusuna basin.
% =========================================================================

clear; clc; close all;

% MATLAB Koyu Tema (Dark Mode) kullanicilari icin beyaz grafik arka plani ayari
set(groot, 'defaultAxesColor', 'w', 'defaultAxesXColor', 'k', ...
           'defaultAxesYColor', 'k', 'defaultTextColor', 'k', ...
           'defaultLegendTextColor', 'k', 'defaultLegendColor', 'w');

%% 1. DOGRULAMA TESTI: KISA BIT DIZISI VE YAPAY HATA DUZELTME GOSTERIMI
rng(42);
demo_msg = [1 0 1 1 0 0 1 1 1 0 1 0 0 0 0]; % 15 bitlik ornek mesaj
[demo_coded, demo_states] = conv_encoder(demo_msg);

% Kodlanmis 45 bitlik diziye kasitli olarak 4 farkli noktada bit hatasi ekleyelim
demo_rx_corrupted = demo_coded;
error_positions = [5, 14, 27, 38];
demo_rx_corrupted(error_positions) = 1 - demo_rx_corrupted(error_positions);

% Viterbi cozucu ile mesaj bitlerini geri cikaralim
[demo_decoded, demo_metric] = viterbi_decoder(demo_rx_corrupted);
demo_remaining_errors = sum(demo_msg ~= demo_decoded);

%% 2. TEST A: DOGRUDAN IKILI SIMETRIK KANALDA (BSC) ENCODER-DECODER TESTI
% (Sadece conv_encoder ve viterbi_decoder bloklarinin rastgele bit hatalarina karsi testi)
N_bsc = 60000;
bsc_msg = randi([0 1], 1, N_bsc);
bsc_coded = conv_encoder(bsc_msg);

pe_vec = linspace(0.005, 0.20, 15); % Kanal bit terslenme olasiligi (Crossover prob.)
ber_bsc_out = zeros(size(pe_vec));

for k = 1:length(pe_vec)
    pe = pe_vec(k);
    err_mask = (rand(size(bsc_coded)) < pe);
    rx_bsc = mod(bsc_coded + err_mask, 2);
    dec_bsc = viterbi_decoder(rx_bsc);
    ber_bsc_out(k) = sum(bsc_msg ~= dec_bsc) / N_bsc;
end

%% 3. TEST B: 1. ARA RAPOR (KODLAMASIZ 8-PSK) VS 2. ARA RAPOR (KODLAMALI 8-PSK)
% Proje foyunde istenen: "compare your results with that of interim report 1"
N_msg = 100000;                      % 100.000 mesaj biti
msg_bits = randi([0 1], 1, N_msg);

% a) Kodlamali Sistem: Mesaj (N) -> 1/3 Conv. Encoder (3N) -> 8-PSK (N sembol)
coded_bits = conv_encoder(msg_bits); % 300.000 kodlanmis bit
[tx_sym_coded, ~, ~, pad_cod] = psk8_modulator(coded_bits);

% b) Kodlamasiz Sistem (1. Ara Rapor): 300.000 bit -> 8-PSK (100.000 sembol)
uncoded_bits = randi([0 1], 1, 3 * N_msg);
[tx_sym_uncoded, ~, ~, pad_unc] = psk8_modulator(uncoded_bits);

signal_power = 1.0;                  % Birim cember (Es = 1 W sabit sinyal gucu)
snr_db_vec   = 0:1:10;               % 0 dB .. 10 dB (1 dB adimlarla)

ber_uncoded  = zeros(size(snr_db_vec)); % 1. Ara Rapor (Kodlamasiz 8-PSK) BER
ber_coded    = zeros(size(snr_db_vec)); % 2. Ara Rapor (1/3 Conv + Viterbi + 8-PSK) BER
ber_theo_unc = zeros(size(snr_db_vec)); % Teorik Kodlamasiz 8-PSK BER
ber_bound_vit= zeros(size(snr_db_vec)); % Viterbi Asimptotik Ust Sinir Yaklasimi

for idx = 1:length(snr_db_vec)
    snr_db  = snr_db_vec(idx);
    snr_lin = 10^(snr_db / 10);
    noise_power = signal_power / snr_lin;
    sigma = sqrt(noise_power / 2);
    
    % --- 1. Ara Rapor: Kodlamasiz 8-PSK ---
    noise_unc = sigma * (randn(size(tx_sym_uncoded)) + 1j * randn(size(tx_sym_uncoded)));
    rx_sym_unc = tx_sym_uncoded + noise_unc;
    rx_bits_unc = psk8_demodulator(rx_sym_unc, pad_unc);
    ber_uncoded(idx) = sum(uncoded_bits ~= rx_bits_unc) / length(uncoded_bits);
    
    % --- 2. Ara Rapor: 1/3 Konvolusyonel Kodlamali 8-PSK + Viterbi ---
    noise_cod = sigma * (randn(size(tx_sym_coded)) + 1j * randn(size(tx_sym_coded)));
    rx_sym_cod = tx_sym_coded + noise_cod;
    rx_bits_raw = psk8_demodulator(rx_sym_cod, pad_cod);
    decoded_msg = viterbi_decoder(rx_bits_raw);
    ber_coded(idx) = sum(msg_bits ~= decoded_msg) / N_msg;
    
    % Teorik Kodlamasiz 8-PSK BER ve Serbest Mesafe (dfree = 10) Viterbi Ust Siniri
    p_ch = (1/3) * erfc(sqrt(snr_lin) * sin(pi/8));
    ber_theo_unc(idx)  = p_ch;
    % K=4, r=1/3, (13,15,17)_8 kodu icin serbest mesafe dfree = 10:
    ber_bound_vit(idx) = min(0.5, 6 * (2 * sqrt(p_ch * (1 - p_ch)))^10);
end

%% 4. SONUCLARI KOMUT PENCERESINE YAZDIRMA
fprintf('==============================================================================\n');
fprintf('   EED4101 PROJE #6 - 3. ASAMA (CONVOLUTIONAL ENCODER & VITERBI DECODER)\n');
fprintf('==============================================================================\n');
fprintf('Ornek 15-Bit Testi -> Kanalda Eklenen Bit Hatasi: %d | Viterbi Sonrasi Hata: %d\n', ...
        length(error_positions), demo_remaining_errors);
fprintf('------------------------------------------------------------------------------\n');
fprintf('  SNR (dB)  |  1. Ara Rapor (Kodlamasiz BER)  |  2. Ara Rapor (Viterbi BER)\n');
fprintf('------------------------------------------------------------------------------\n');
for idx = 1:length(snr_db_vec)
    fprintf('   %5.1f    |            %.6f             |           %.6f\n', ...
            snr_db_vec(idx), ber_uncoded(idx), ber_coded(idx));
end
fprintf('==============================================================================\n');

%% 5. GRAFIKLERIN CIZDIRILMESI (2. ARA RAPOR ICIN SEKILLER)

% SEKIL 1: Ornek Mesaj Kodlama, Kanalda Bozulma ve Viterbi Hata Duzeltme Grafigi
figure('Name', 'Sekil 1 - Konvolusyonel Kodlama ve Viterbi Hata Duzeltme Dogrulamasi', ...
       'Color', 'w', 'Position', [70 100 900 640]);

subplot(3,1,1);
stem(1:length(demo_msg), demo_msg, 'b', 'filled', 'LineWidth', 1.6, 'MarkerSize', 6);
ylim([-0.2 1.3]); xlim([0.5 length(demo_msg)+0.5]); grid on;
title('Gonderilen Orijinal 15-Bitlik Mesaj Dizisi u(n)');
ylabel('Bit Degeri');

subplot(3,1,2);
stem(1:length(demo_coded), demo_coded, 'Color', [0.2 0.6 0.2], 'LineWidth', 1.2, 'MarkerSize', 4); hold on;
stem(error_positions, demo_rx_corrupted(error_positions), 'ro', 'filled', 'LineWidth', 1.8, 'MarkerSize', 8);
ylim([-0.2 1.3]); xlim([0.5 length(demo_coded)+0.5]); grid on;
title(sprintf('1/3 Konvolusyonel Kodlanmis 45-Bitlik Dizi c(n) ve Kanalda Bozulan %d Bit (Kirmizi)', length(error_positions)));
ylabel('Bit Degeri');
legend('Kodlanmis Bitler', 'Kanalda Terslenen (Hatali) Bitler', 'Location', 'northeast');

subplot(3,1,3);
stem(1:length(demo_decoded), demo_decoded, 'b', 'filled', 'LineWidth', 1.6, 'MarkerSize', 6); hold on;
plot(1:length(demo_msg), demo_msg, 'ro', 'MarkerSize', 10, 'LineWidth', 1.5);
ylim([-0.2 1.3]); xlim([0.5 length(demo_decoded)+0.5]); grid on;
title(sprintf('Viterbi Cozucu Cikisi u_{hat}(n) -> Kalan Bit Hatasi = %d (Tam Duzeltme)', demo_remaining_errors));
xlabel('Mesaj Bit Indisi (n)'); ylabel('Bit Degeri');
legend('Viterbi Cozucu Cikisi', 'Orijinal Mesaj', 'Location', 'northeast');

% SEKIL 2: Dogrudan Rastgele Bit Hatalarina (BSC) Karsi Viterbi Performansi
figure('Name', 'Sekil 2 - Dogrudan Rastgele Bit Hatasi (BSC) Altinda Viterbi Performansi', ...
       'Color', 'w', 'Position', [130 130 780 460]);
ber_bsc_plot = max(ber_bsc_out, 0.5 / N_bsc); % Log eksende 0 degerlerini gostermek icin alt sinir
semilogy(pe_vec, pe_vec, 'k--', 'LineWidth', 1.8); hold on;
semilogy(pe_vec, ber_bsc_plot, 'ro-', 'LineWidth', 2.0, 'MarkerSize', 7, 'MarkerFaceColor', 'r');
grid on;
xlabel('Kanal Gecis Hata Olasiligi (Input Bit Error Rate, p_e)', 'FontWeight', 'bold');
ylabel('Cozucu Cikisi BER (Logaritmik Eksen)', 'FontWeight', 'bold');
title('Rastgele Ikili Veri ile Kanal Kodlayici + Viterbi Cozucu Performansi (BSC)');
legend('Kodlamasiz Durum (Cikis BER = p_e)', '1/3 Konvolusyonel + Viterbi Cikisi BER', 'Location', 'southeast');
ylim([1e-5 1]);

% SEKIL 3: 1. Ara Rapor (Kodlamasiz 8-PSK) vs 2. Ara Rapor (Kodlamali 8-PSK + Viterbi)
figure('Name', 'Sekil 3 - 1. Ara Rapor (Kodlamasiz) ve 2. Ara Rapor (Kodlamali) BER Karsilastirmasi', ...
       'Color', 'w', 'Position', [190 150 840 520]);

% Logaritmik eksende 0 hatali noktalari kesintisiz gostermek icin
ber_coded_plot = ber_coded;
zero_mask = (ber_coded_plot == 0);
ber_coded_plot(zero_mask) = ber_bound_vit(zero_mask);

semilogy(snr_db_vec, ber_theo_unc, 'k:', 'LineWidth', 1.6); hold on;
semilogy(snr_db_vec, ber_uncoded, 'bs-', 'LineWidth', 2.0, 'MarkerSize', 7, 'MarkerFaceColor', 'b');
semilogy(snr_db_vec, ber_coded_plot, 'ro-', 'LineWidth', 2.2, 'MarkerSize', 7, 'MarkerFaceColor', 'r');
semilogy(snr_db_vec(4:end), ber_bound_vit(4:end), 'r--', 'LineWidth', 1.3);
grid on;
xlabel('SNR (E_s / N_0) [dB]', 'FontWeight', 'bold');
ylabel('Bit Hata Orani - BER (Logaritmik Eksen)', 'FontWeight', 'bold');
title('AWGN Kanalda Kodlamasiz 8-PSK (1. Ara Rapor) ve 1/3 Konvolusyonel Kodlu 8-PSK (2. Ara Rapor) Karsilastirmasi');
legend('Teorik Kodlamasiz 8-PSK BER', ...
       '1. Ara Rapor: Kodlamasiz 8-PSK (Simulasyon)', ...
       '2. Ara Rapor: 1/3 Conv. Kodlu 8-PSK + Viterbi', ...
       'Teorik Viterbi Ust Siniri (d_{free} = 10)', ...
       'Location', 'southwest');
ylim([1e-6 1]);
xlim([0 10]);
