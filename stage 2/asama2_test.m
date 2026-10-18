%% ========================================================================
%  DOKUZ EYLUL UNIVERSITY - EED4101 DIGITAL COMMUNICATION PROJECT #6
%  STAGE 2 ANA TEST SCRIPTI (asama2_test.m)
%  8-PSK Gray Mapping Modulator, AWGN Kanal & Maximum Likelihood Demodulator
%
%  KULLANIM:
%  1. "psk8_modulator.m", "psk8_demodulator.m" ve "asama2_test.m"
%     dosyalarinin ucunu de MATLAB'da AYNI KLASORE koyun.
%  2. Bu dosyayi (asama2_test.m) acip "Run" (F5) tusuna basin.
% =========================================================================

clear; clc; close all;

% MATLAB Koyu Tema (Dark Mode) kullanicilari icin beyaz grafik arka plani ayari
set(groot, 'defaultAxesColor', 'w', 'defaultAxesXColor', 'k', ...
           'defaultAxesYColor', 'k', 'defaultTextColor', 'k', ...
           'defaultLegendTextColor', 'k', 'defaultLegendColor', 'w');

%% 1. RASTGELE IKILI VERI (RANDOM BINARY DATA) URETIMI
rng(42);                    % Tekrarlanabilir sonuclar icin sabit tohum
N_bits = 300000;            % 300.000 bit (100.000 adet 8-PSK sembolu)
tx_bits = randi([0 1], 1, N_bits);

%% 2. 8-PSK GRAY MODULASYONU (SABIT SINYAL GUCU: Es = 1)
[tx_symbols, constellation, gray_labels, num_pad] = psk8_modulator(tx_bits);
signal_power = mean(abs(tx_symbols).^2); % Sabit sinyal gucu = 1.0 W

%% 3. AWGN KANAL VE MAXIMUM LIKELIHOOD DEMODULASYON (SNR: 0 dB .. 14 dB)
% Proje foyunde 0 dB ile 10 dB (1 dB adimla) istenmektedir; egriyi tam
% gormek icin 0..14 dB araliginda tarama yapiyoruz.
snr_db_vec = 0:1:14;
ber_sim    = zeros(size(snr_db_vec));
ser_sim    = zeros(size(snr_db_vec));
ber_theo   = zeros(size(snr_db_vec));

% Yildiz kumesi (Constellation) gorsellestirmesi icin ornek kayitlar
rx_sym_0dB  = [];
rx_sym_5dB  = [];
rx_sym_10dB = [];

for idx = 1:length(snr_db_vec)
    snr_db  = snr_db_vec(idx);
    snr_lin = 10^(snr_db / 10); % SNR = P_signal / P_noise = Es / N0
    
    % Sinyal gucu sabit (Es = 1), gurultu gucu SNR'ye gore degisir:
    noise_power = signal_power / snr_lin;
    
    % Karmasik AWGN: Gercek ve sanal bilesenlerin her birinin varyansi noise_power/2
    sigma = sqrt(noise_power / 2);
    awgn_noise = sigma * (randn(size(tx_symbols)) + 1j * randn(size(tx_symbols)));
    
    % Kanal cikisi: r = s + n
    rx_symbols = tx_symbols + awgn_noise;
    
    % Belirli SNR degerlerinde yildiz diyagrami icin ilk 2000 sembolu sakla
    if snr_db == 0,  rx_sym_0dB  = rx_symbols(1:2000); end
    if snr_db == 5,  rx_sym_5dB  = rx_symbols(1:2000); end
    if snr_db == 10, rx_sym_10dB = rx_symbols(1:2000); end
    
    % Maximum Likelihood (ML) 8-PSK Demodulasyon
    [rx_bits, decided_symbols] = psk8_demodulator(rx_symbols, num_pad);
    
    % Bit Hata Orani (BER) ve Sembol Hata Orani (SER) Hesabi
    num_bit_errors = sum(tx_bits ~= rx_bits);
    ber_sim(idx)   = num_bit_errors / N_bits;
    ser_sim(idx)   = sum(abs(tx_symbols - decided_symbols) > 1e-6) / length(tx_symbols);
    
    % Teorik 8-PSK Gray Kodlamali BER Hesabi (Yuksek SNR yaklasimi):
    % Ps_theo ~= erfc(sqrt(Es/N0) * sin(pi/8)),  Pb_theo ~= Ps_theo / 3
    ber_theo(idx) = (1/3) * erfc(sqrt(snr_lin) * sin(pi/8));
end

%% 4. SONUC TABLOSUNU KOMUT PENCERESINE YAZDIRMA
fprintf('======================================================================\n');
fprintf('   EED4101 PROJE #6 - 2. ASAMA (8-PSK MODULATOR & DEMODULATOR)\n');
fprintf('   Bit Sayisi: %d | Sembol Sayisi: %d | Sinyal Gucu: %.2f W\n', ...
        N_bits, length(tx_symbols), signal_power);
fprintf('======================================================================\n');
fprintf('  SNR (dB)  |  Simulasyon BER  |   Teorik BER    |  Simulasyon SER\n');
fprintf('----------------------------------------------------------------------\n');
for idx = 1:length(snr_db_vec)
    fprintf('   %5.1f    |    %.6f      |    %.6f     |    %.6f\n', ...
            snr_db_vec(idx), ber_sim(idx), ber_theo(idx), ser_sim(idx));
end
fprintf('======================================================================\n');

%% 5. GRAFIKLERIN CIZDIRILMESI (1. ARA RAPOR ICIN SEKILLER)

% SEKIL 1: 8-PSK Gray Mapping Referans Yildiz Kumesi (Constellation)
figure('Name', 'Sekil 1 - 8-PSK Gray Mapping Yildiz Kumesi', 'Color', 'w', 'Position', [80 120 620 560]);
theta_circle = linspace(0, 2*pi, 300);
plot(cos(theta_circle), sin(theta_circle), '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2); hold on;
plot(real(constellation), imag(constellation), 'bo', 'MarkerSize', 11, 'MarkerFaceColor', [0.1 0.45 0.85]);
line([-1.35 1.35], [0 0], 'Color', [0.4 0.4 0.4], 'LineStyle', ':');
line([0 0], [-1.35 1.35], 'Color', [0.4 0.4 0.4], 'LineStyle', ':');

% Karar bolgesi sinir cizgileri (ML karar bolgeleri: pi/8 + k*pi/4 acilari)
for k = 0:7
    ang = pi/8 + k * pi/4;
    line([0 1.35*cos(ang)], [0 1.35*sin(ang)], 'Color', [0.85 0.3 0.3], 'LineStyle', '--', 'LineWidth', 1.0);
end

% Her sembolun yanina 3-bitlik Gray kodunu yaz
for m = 1:8
    cx = 1.18 * real(constellation(m));
    cy = 1.18 * imag(constellation(m));
    lbl_str = sprintf('%d%d%d\n(s_%d)', gray_labels(m,1), gray_labels(m,2), gray_labels(m,3), m-1);
    text(cx, cy, lbl_str, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 10, 'Color', 'k');
end
axis equal; xlim([-1.4 1.4]); ylim([-1.4 1.4]); grid on;
xlabel('In-Phase (I)', 'FontWeight', 'bold');
ylabel('Quadrature (Q)', 'FontWeight', 'bold');
title('8-PSK Gray Mapping Yildiz Kumesi ve Maximum Likelihood (ML) Karar Bolgeleri');
legend('Birim Cember (E_s = 1)', '8-PSK Sembolleri', 'Location', 'southoutside');

% SEKIL 2: Farkli SNR Degerlerinde AWGN Kanal Etkisi (0 dB, 5 dB, 10 dB)
figure('Name', 'Sekil 2 - Farkli SNR Degerlerinde Alinan 8-PSK Sembolleri', 'Color', 'w', 'Position', [140 140 1050 380]);

snr_examples = {rx_sym_0dB, rx_sym_5dB, rx_sym_10dB};
snr_titles   = {'SNR = 0 dB (Yuksek Gurultu)', 'SNR = 5 dB (Orta Gurultu)', 'SNR = 10 dB (Dusuk Gurultu)'};

for p = 1:3
    subplot(1, 3, p);
    plot(real(snr_examples{p}), imag(snr_examples{p}), '.', 'Color', [0.25 0.55 0.85], 'MarkerSize', 5); hold on;
    plot(real(constellation), imag(constellation), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'LineWidth', 1.5);
    for k = 0:7
        ang = pi/8 + k * pi/4;
        line([0 2.2*cos(ang)], [0 2.2*sin(ang)], 'Color', [0.3 0.3 0.3], 'LineStyle', ':');
    end
    axis equal; xlim([-2.2 2.2]); ylim([-2.2 2.2]); grid on;
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    title(snr_titles{p}, 'FontWeight', 'bold');
    if p == 1
        legend('Alinan r_k = s_k + n_k', 'Referans s_m', 'Location', 'southwest');
    end
end

% SEKIL 3: Logaritmik Eksende BER vs. SNR Grafigi (Simulasyon vs Teorik)
figure('Name', 'Sekil 3 - 8-PSK BER vs SNR Performansi (Logaritmik Eksen)', 'Color', 'w', 'Position', [200 160 820 500]);
semilogy(snr_db_vec, ber_theo, 'k--', 'LineWidth', 2.0); hold on;
semilogy(snr_db_vec, ber_sim, 'bo-', 'LineWidth', 2.0, 'MarkerSize', 7, 'MarkerFaceColor', 'b');
semilogy(snr_db_vec, ser_sim, 'rs-', 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
grid on;
xlabel('SNR (E_s / N_0) [dB]', 'FontWeight', 'bold');
ylabel('Hata Orani (Logaritmik Eksen)', 'FontWeight', 'bold');
title('AWGN Kanalda 8-PSK (Gray Mapping + ML Demodulator) BER ve SER Performansi');
legend('Teorik 8-PSK BER Yaklasimi', 'Simulasyon BER (Bit Error Rate)', 'Simulasyon SER (Symbol Error Rate)', ...
       'Location', 'southwest');
ylim([1e-5 1]);
xlim([0 14]);
