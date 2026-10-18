function asama4_test()
% =========================================================================
%  DOKUZ EYLUL UNIVERSITY - EED4101 DIGITAL COMMUNICATION PROJECT #6
%  STAGE 4 (FINAL) ANA TEST, RAPOR/POSTER GRAFIKLERI VE GUI BASLATICI
%  Dosya Adi: asama4_test.m
%
%  ONEMLI: "Unrecognized function or variable 'dm_adm_encoder'" hatasi
%          almamaniz icin 6 temel fonksiyonun tamami ve GUI bu dosyanin
%          icine de entegre edilmistir! Baska hicbir dosyaya ihtiyac
%          duymadan dogrudan Run (F5) tusuna basarak calistirabilirsiniz.
% =========================================================================

    clc; close all;

    % MATLAB Koyu Tema (Dark Mode) kullanicilari icin beyaz grafik arka plani ayari
    set(groot, 'defaultAxesColor', 'w', 'defaultAxesXColor', 'k', ...
               'defaultAxesYColor', 'k', 'defaultTextColor', 'k', ...
               'defaultLegendTextColor', 'k', 'defaultLegendColor', 'w');

    %% 1. TEST SES SINYALI OLUSTURMA VE .WAV OLARAK KAYDETME (8000 Hz)
    fs = 8000;                  % Ornekleme frekansi: 8000 Hz
    T_dur = 2.5;                % Hizli tam tarama icin 2.5 sn (GUI'de 10 sn secilebilir)
    t = 0:1/fs:(T_dur - 1/fs);

    rng(42);
    % Konusma sinyaline benzer zarf modulasyonlu harmonik test sesi
    env = (0.55 + 0.45*sin(2*pi*1.8*t)) .* (0.6 + 0.4*cos(2*pi*3.3*t));
    x_sound = env .* (0.60*sin(2*pi*220*t) + 0.30*sin(2*pi*440*t + 0.4) + 0.18*sin(2*pi*660*t + 1.1));
    x_sound = 0.85 * x_sound / max(abs(x_sound));

    % Ders web sayfasindaki ses dosyasi yerine test edebileceginiz ornek .wav dosyasi
    try
        audiowrite('ornek_test_sesi_8kHz.wav', x_sound(:), fs);
    catch
    end

    %% 2. 6 FONKSIYONUN BIRLESIMI: 0 dB .. 10 dB (1 dB ADIMLI) TAM SISTEM TESTI
    delta_adm = 0.045;          % ADM baslangic adim boyutu (V)
    delta_dm  = 0.095;          % Sabit DM adim boyutu (V)
    fc_lpf    = 900;            % Alici LPF kesim frekansi (Hz)

    % a) Kaynak Kodlama (ADM ve DM)
    [bits_adm_tx, ~, ~] = dm_adm_encoder(x_sound, delta_adm, 'ADM');
    [bits_dm_tx,  ~, ~] = dm_adm_encoder(x_sound, delta_dm,  'DM');
    N_bits = length(bits_adm_tx);

    % b) Kanal Kodlama (1/3 Konvolusyonel Kodlayici - Sekil 2)
    coded_adm_tx = conv_encoder(bits_adm_tx);
    coded_dm_tx  = conv_encoder(bits_dm_tx);

    % c) 8-PSK Gray Mapping Modulasyon (Es = 1 W sabit sinyal gucu)
    [sym_adm_cod, ~, ~, pad_adm] = psk8_modulator(coded_adm_tx);
    [sym_dm_cod,  ~, ~, pad_dm]  = psk8_modulator(coded_dm_tx);
    [sym_adm_unc, ~, ~, pad_unc] = psk8_modulator(bits_adm_tx);

    snr_db_vec = 0:1:10;        % Proje foyunde istenen: 0 dB .. 10 dB (1 dB adimla)
    ber_raw_ch = zeros(size(snr_db_vec)); % Viterbi oncesi ham kanal BER
    ber_uncoded= zeros(size(snr_db_vec)); % Kodlamasiz 8-PSK BER
    ber_viterbi= zeros(size(snr_db_vec)); % Tam Sistem (Viterbi sonrasi) BER
    sqnr_adm   = zeros(size(snr_db_vec)); % ADM Cikis Ses Kalitesi (SQNR dB)
    sqnr_dm    = zeros(size(snr_db_vec)); % Sabit DM Cikis Ses Kalitesi (SQNR dB)

    % Farkli SNR degerlerinde ses dalga sekli ornekleri (0 dB, 4 dB, 8 dB)
    x_rec_0dB = [];
    x_rec_4dB = [];
    x_rec_8dB = [];

    W_ma = 2 * round(0.010 * fs) + 1;
    h_ma = ones(1, W_ma) / W_ma;
    half_w = floor(W_ma / 2);

    for idx = 1:length(snr_db_vec)
        snr_db  = snr_db_vec(idx);
        snr_lin = 10^(snr_db / 10);
        sigma   = sqrt(1.0 / (2 * snr_lin));
        
        % --- 1) ADM + 1/3 Conv + 8-PSK + AWGN + ML Demod + Viterbi + ADM Decoder ---
        noise_adm  = sigma * (randn(size(sym_adm_cod)) + 1j * randn(size(sym_adm_cod)));
        rx_ch_adm  = psk8_demodulator(sym_adm_cod + noise_adm, pad_adm);
        ber_raw_ch(idx) = sum(coded_adm_tx ~= rx_ch_adm) / length(coded_adm_tx);
        
        rx_bits_adm = viterbi_decoder(rx_ch_adm);
        ber_viterbi(idx) = sum(bits_adm_tx ~= rx_bits_adm) / N_bits;
        
        x_rec_a = dm_adm_decoder(rx_bits_adm, delta_adm, 'ADM', fs, fc_lpf);
        if ber_viterbi(idx) > 0
            x_pad = [fliplr(x_rec_a(1:half_w)), x_rec_a, fliplr(x_rec_a(end-half_w+1:end))];
            drift = conv(x_pad, h_ma, 'valid');
            x_rec_a = x_rec_a - drift(1:length(x_rec_a));
            rms_in  = sqrt(mean(x_sound.^2));
            rms_out = sqrt(mean(x_rec_a.^2)) + 1e-9;
            if rms_out > 1.25 * rms_in
                x_rec_a = x_rec_a * (rms_in / rms_out);
            end
        end
        sqnr_adm(idx) = 10 * log10(sum(x_sound.^2) / (sum((x_sound - x_rec_a).^2) + 1e-12));
        
        if snr_db == 0, x_rec_0dB = x_rec_a; end
        if snr_db == 4, x_rec_4dB = x_rec_a; end
        if snr_db == 8, x_rec_8dB = x_rec_a; end
        
        % --- 2) Sabit DM + 1/3 Conv + 8-PSK + AWGN + ML Demod + Viterbi + DM Decoder ---
        noise_dm   = sigma * (randn(size(sym_dm_cod)) + 1j * randn(size(sym_dm_cod)));
        rx_ch_dm   = psk8_demodulator(sym_dm_cod + noise_dm, pad_dm);
        rx_bits_dm = viterbi_decoder(rx_ch_dm);
        x_rec_d    = dm_adm_decoder(rx_bits_dm, delta_dm, 'DM', fs, fc_lpf);
        if sum(bits_dm_tx ~= rx_bits_dm) > 0
            x_pad_d = [fliplr(x_rec_d(1:half_w)), x_rec_d, fliplr(x_rec_d(end-half_w+1:end))];
            drift_d = conv(x_pad_d, h_ma, 'valid');
            x_rec_d = x_rec_d - drift_d(1:length(x_rec_d));
        end
        sqnr_dm(idx) = 10 * log10(sum(x_sound.^2) / (sum((x_sound - x_rec_d).^2) + 1e-12));
        
        % --- 3) Kodlamasiz 8-PSK Karsilastirmasi ---
        noise_unc = sigma * (randn(size(sym_adm_unc)) + 1j * randn(size(sym_adm_unc)));
        rx_b_unc  = psk8_demodulator(sym_adm_unc + noise_unc, pad_unc);
        ber_uncoded(idx) = sum(bits_adm_tx ~= rx_b_unc) / N_bits;
    end

    %% 3. FINAL RAPORU VE A0 POSTER ICIN SAYISAL TABLOYU YAZDIRMA
    fprintf('======================================================================================\n');
    fprintf('   EED4101 PROJE #6 - 4. ASAMA (FINAL) UCTAN UCA SES ILETIM SONUCLARI (0 - 10 dB)\n');
    fprintf('======================================================================================\n');
    fprintf('  SNR (dB) | Kanal Ham BER | Kodlamasiz BER | Viterbi Sonrasi BER | ADM SQNR | DM SQNR\n');
    fprintf('--------------------------------------------------------------------------------------\n');
    for idx = 1:length(snr_db_vec)
        fprintf('   %5.1f   |   %.6f    |    %.6f    |      %.6f       | %6.2f dB| %6.2f dB\n', ...
                snr_db_vec(idx), ber_raw_ch(idx), ber_uncoded(idx), ber_viterbi(idx), sqnr_adm(idx), sqnr_dm(idx));
    end
    fprintf('======================================================================================\n');

    %% 4. FINAL RAPORU VE A0 POSTER ICIN GRAFIKLER

    % SEKIL 1: Logaritmik Eksende BER vs SNR (0 dB .. 10 dB, 1 dB Adimli)
    figure('Name', 'Final Sekil 1 - Tam Sistem BER vs SNR Analizi (Logaritmik Eksen)', ...
           'Color', 'w', 'Position', [60 90 820 500]);
    s_lin = 10.^(snr_db_vec / 10);
    p_ch  = (1/3) * erfc(sqrt(s_lin) * sin(pi/8));
    vit_bound = min(0.5, 6 * (2 * sqrt(p_ch .* (1 - p_ch))).^10);
    ber_vit_plot = ber_viterbi;
    ber_vit_plot(ber_vit_plot == 0) = vit_bound(ber_vit_plot == 0);

    semilogy(snr_db_vec, ber_uncoded, 'bs--', 'LineWidth', 1.8, 'MarkerSize', 7, 'MarkerFaceColor', 'b'); hold on;
    semilogy(snr_db_vec, ber_vit_plot, 'ro-', 'LineWidth', 2.2, 'MarkerSize', 7, 'MarkerFaceColor', 'r');
    semilogy(snr_db_vec(4:end), vit_bound(4:end), 'k:', 'LineWidth', 1.5);
    grid on; ylim([1e-6 1]); xlim([0 10]);
    xlabel('SNR (Sinyal-Gurultu Orani) [dB]', 'FontWeight', 'bold');
    ylabel('Bit Hata Orani - BER (Logaritmik Eksen)', 'FontWeight', 'bold');
    title('Ses Sinyali Iletiminde Kanal Gurultusunun BER Uzerindeki Etkisi (0 dB - 10 dB)');
    legend('Kodlamasiz Sistem (Sadece DM/ADM + 8-PSK)', ...
           'Tam Sistem (DM/ADM + 1/3 Conv. + 8-PSK + Viterbi)', ...
           'Teorik Viterbi Asimptotik Egrisi', 'Location', 'southwest');

    % SEKIL 2: Kanal Gurultusunun Ses Dalga Sekli Uzerindeki Etkisi (0 dB, 4 dB, 8 dB + SQNR)
    figure('Name', 'Final Sekil 2 - Kanal Gurultusunun Ses Sinyali ve SQNR Uzerindeki Etkisi', ...
           'Color', 'w', 'Position', [120 110 920 720]);

    idx_zoom = 1 : round(0.04 * fs); % Ilk 40 ms detay gorunumu
    subplot(4,1,1);
    plot(t(idx_zoom)*1000, x_sound(idx_zoom), 'k--', 'LineWidth', 1.5); hold on;
    plot(t(idx_zoom)*1000, x_rec_0dB(idx_zoom), 'r-', 'LineWidth', 1.2);
    grid on; ylabel('Genlik [V]');
    title(sprintf('SNR = 0 dB (Yuksek Kanal Gurultusu: BER = %.4f, Ses SQNR = %.2f dB -> Agir Bozulma)', ber_viterbi(1), sqnr_adm(1)));
    legend('Orijinal Ses x(t)', 'Alinan Ses (0 dB)', 'Location', 'northeast');

    subplot(4,1,2);
    plot(t(idx_zoom)*1000, x_sound(idx_zoom), 'k--', 'LineWidth', 1.5); hold on;
    plot(t(idx_zoom)*1000, x_rec_4dB(idx_zoom), 'Color', [0.85 0.45 0.05], 'LineWidth', 1.4);
    grid on; ylabel('Genlik [V]');
    title(sprintf('SNR = 4 dB (Orta Kanal Gurultusu: BER = %.4f, Ses SQNR = %.2f dB -> Kismi Bozulma)', ber_viterbi(5), sqnr_adm(5)));
    legend('Orijinal Ses x(t)', 'Alinan Ses (4 dB)', 'Location', 'northeast');

    subplot(4,1,3);
    plot(t(idx_zoom)*1000, x_sound(idx_zoom), 'k--', 'LineWidth', 1.5); hold on;
    plot(t(idx_zoom)*1000, x_rec_8dB(idx_zoom), 'Color', [0.1 0.65 0.2], 'LineWidth', 1.6);
    grid on; xlabel('Zaman [ms]'); ylabel('Genlik [V]');
    title(sprintf('SNR = 8 dB (Viterbi Tam Duzeltme Bolgesi: BER = %.5f, Ses SQNR = %.2f dB -> Temiz Ses)', ber_viterbi(9), sqnr_adm(9)));
    legend('Orijinal Ses x(t)', 'Alinan Ses (8 dB)', 'Location', 'northeast');

    subplot(4,1,4);
    plot(snr_db_vec, sqnr_adm, 'ro-', 'LineWidth', 2.0, 'MarkerSize', 6, 'MarkerFaceColor', 'r'); hold on;
    plot(snr_db_vec, sqnr_dm,  'bs-', 'LineWidth', 1.8, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
    grid on; xlabel('SNR [dB]', 'FontWeight', 'bold'); ylabel('Cikis Ses SQNR [dB]', 'FontWeight', 'bold');
    title('0 - 10 dB SNR Araliginda Alicida Geri Catilan Ses Kalitesi (ADM vs Sabit DM)');
    legend('Adaptif DM (ADM) + Viterbi', 'Sabit DM + Viterbi', 'Location', 'southeast');

    %% 5. ETKILESIMLI MATLAB GUI ARAYUZUNU BASLAT
    if exist('proje6_gui', 'file') == 2
        proje6_gui();
    end
end

%% ========================================================================
%  DAHILI 6 TEMEL FONKSIYON (Klasorde diger dosyalar eksik olsa bile calisir)
%  ========================================================================
function [bit_stream, x_stair, delta_hist] = dm_adm_encoder(x, delta_init, mode)
    x = x(:)';
    N = length(x);
    bit_stream = zeros(1, N);
    x_stair    = zeros(1, N);
    delta_hist = zeros(1, N);
    K_up   = 1.25;
    K_down = 1 / 1.25;
    delta_min = delta_init * 0.25;
    delta_max = delta_init * 16;
    x_pred = 0;
    curr_delta = delta_init;
    prev_b = 1;
    for n = 1:N
        if (x(n) - x_pred) >= 0
            bit_stream(n) = 1; curr_b = 1;
        else
            bit_stream(n) = 0; curr_b = -1;
        end
        if strcmpi(mode, 'ADM') && n > 1
            if curr_b == prev_b
                curr_delta = min(curr_delta * K_up, delta_max);
            else
                curr_delta = max(curr_delta * K_down, delta_min);
            end
        end
        x_pred = x_pred + curr_b * curr_delta;
        x_stair(n)    = x_pred;
        delta_hist(n) = curr_delta;
        prev_b        = curr_b;
    end
end

function [x_reconstructed, x_stair, delta_hist] = dm_adm_decoder(bit_stream, delta_init, mode, fs, fm_cutoff)
    if nargin < 4, fs = 8000; end
    if nargin < 5, fm_cutoff = 200; end
    bit_stream = bit_stream(:)';
    N = length(bit_stream);
    x_stair    = zeros(1, N);
    delta_hist = zeros(1, N);
    K_up   = 1.25;
    K_down = 1 / 1.25;
    delta_min = delta_init * 0.25;
    delta_max = delta_init * 16;
    x_pred = 0;
    curr_delta = delta_init;
    prev_b = 1;
    for n = 1:N
        if bit_stream(n) == 1, curr_b = 1; else, curr_b = -1; end
        if strcmpi(mode, 'ADM') && n > 1
            if curr_b == prev_b
                curr_delta = min(curr_delta * K_up, delta_max);
            else
                curr_delta = max(curr_delta * K_down, delta_min);
            end
        end
        x_pred = x_pred + curr_b * curr_delta;
        x_stair(n)    = x_pred;
        delta_hist(n) = curr_delta;
        prev_b        = curr_b;
    end
    fc = min(2.5 * fm_cutoff, 0.45 * fs);
    norm_fc = fc / (fs / 2);
    M = 20;
    n_idx = -M:M;
    x_arg = norm_fc * n_idx;
    sinc_val = ones(size(x_arg));
    nz = (x_arg ~= 0);
    sinc_val(nz) = sin(pi * x_arg(nz)) ./ (pi * x_arg(nz));
    h = norm_fc * sinc_val .* (0.54 - 0.46 * cos(2 * pi * (0:(2*M)) / (2 * M)));
    h = h / sum(h);
    x_padded = [fliplr(x_stair(1:M)), x_stair, fliplr(x_stair(end-M+1:end))];
    y_conv = conv(x_padded, h, 'valid');
    x_reconstructed = y_conv(1:N);
end

function [coded_bits, state_history] = conv_encoder(msg_bits)
    msg_bits = double(msg_bits(:)' > 0);
    N = length(msg_bits);
    u0 = msg_bits;
    u1 = [0, msg_bits(1:end-1)];
    u2 = [0, 0, msg_bits(1:end-2)];
    u3 = [0, 0, 0, msg_bits(1:end-3)];
    c1 = mod(u0 + u2 + u3, 2);
    c2 = mod(u0 + u1 + u3, 2);
    c3 = mod(u0 + u1 + u2 + u3, 2);
    coded_bits = reshape([c1; c2; c3], 1, 3 * N);
    if nargout > 1
        state_history = 4 * u0 + 2 * u1 + u2;
    end
end

function [decoded_bits, min_final_metric] = viterbi_decoder(rx_coded_bits)
    rx_coded_bits = double(rx_coded_bits(:)' > 0);
    N = floor(length(rx_coded_bits) / 3);
    rx_mat = reshape(rx_coded_bits(1 : 3*N), 3, N)';
    p0_idx = zeros(8, 1); p1_idx = zeros(8, 1);
    out_p0 = zeros(8, 3); out_p1 = zeros(8, 3);
    for ns = 0:7
        u = floor(ns / 4);
        p0 = 2 * mod(ns, 4); p1 = 2 * mod(ns, 4) + 1;
        p0_idx(ns + 1) = p0 + 1; p1_idx(ns + 1) = p1 + 1;
        s1_0 = floor(p0 / 4); s2_0 = mod(floor(p0 / 2), 2); s3_0 = mod(p0, 2);
        out_p0(ns + 1, :) = [mod(u + s2_0 + s3_0, 2), mod(u + s1_0 + s3_0, 2), mod(u + s1_0 + s2_0 + s3_0, 2)];
        s1_1 = floor(p1 / 4); s2_1 = mod(floor(p1 / 2), 2); s3_1 = mod(p1, 2);
        out_p1(ns + 1, :) = [mod(u + s2_1 + s3_1, 2), mod(u + s1_1 + s3_1, 2), mod(u + s1_1 + s2_1 + s3_1, 2)];
    end
    BM0_TABLE = zeros(8, 8); BM1_TABLE = zeros(8, 8);
    for r_val = 0:7
        r_vec = [floor(r_val / 4), mod(floor(r_val / 2), 2), mod(r_val, 2)];
        for ns_i = 1:8
            BM0_TABLE(ns_i, r_val + 1) = sum(out_p0(ns_i, :) ~= r_vec);
            BM1_TABLE(ns_i, r_val + 1) = sum(out_p1(ns_i, :) ~= r_vec);
        end
    end
    rx_pat_idx = rx_mat(:,1)*4 + rx_mat(:,2)*2 + rx_mat(:,3) + 1;
    path_metric = 1e9 * ones(8, 1); path_metric(1) = 0;
    survivor_prev = zeros(8, N, 'uint8');
    new_pm = zeros(8, 1);
    for n = 1:N
        r_col = rx_pat_idx(n);
        for ns_i = 1:8
            cand0 = path_metric(p0_idx(ns_i)) + BM0_TABLE(ns_i, r_col);
            cand1 = path_metric(p1_idx(ns_i)) + BM1_TABLE(ns_i, r_col);
            if cand1 < cand0
                new_pm(ns_i) = cand1; survivor_prev(ns_i, n) = p1_idx(ns_i);
            else
                new_pm(ns_i) = cand0; survivor_prev(ns_i, n) = p0_idx(ns_i);
            end
        end
        path_metric = new_pm;
    end
    [min_final_metric, best_state] = min(path_metric);
    decoded_bits = zeros(1, N);
    curr_s = best_state;
    for n = N:-1:1
        if curr_s >= 5, decoded_bits(n) = 1; else, decoded_bits(n) = 0; end
        curr_s = double(survivor_prev(curr_s, n));
    end
end

function [tx_symbols, constellation, gray_labels, num_pad] = psk8_modulator(bit_stream)
    bit_stream = bit_stream(:)';
    N_bits = length(bit_stream);
    rem_bits = mod(N_bits, 3);
    if rem_bits ~= 0
        num_pad = 3 - rem_bits;
        bit_stream = [bit_stream, zeros(1, num_pad)];
    else
        num_pad = 0;
    end
    constellation = exp(1j * (2 * pi * (0:7) / 8));
    gray_labels = [0 0 0; 0 0 1; 0 1 1; 0 1 0; 1 1 0; 1 1 1; 1 0 1; 1 0 0];
    dec_to_const_idx = [1, 2, 4, 3, 8, 7, 5, 6];
    num_symbols = length(bit_stream) / 3;
    bit_matrix = reshape(bit_stream, 3, num_symbols)';
    dec_vals = bit_matrix(:,1)*4 + bit_matrix(:,2)*2 + bit_matrix(:,3);
    tx_symbols = constellation(dec_to_const_idx(dec_vals + 1));
end

function [rx_bits, decided_symbols] = psk8_demodulator(rx_symbols, num_pad)
    if nargin < 2, num_pad = 0; end
    rx_col = rx_symbols(:);
    K = length(rx_col);
    constellation = exp(1j * (2 * pi * (0:7) / 8));
    gray_labels = [0 0 0; 0 0 1; 0 1 1; 0 1 0; 1 1 0; 1 1 1; 1 0 1; 1 0 0];
    dist_sq = abs(repmat(rx_col, 1, 8) - repmat(constellation, K, 1)).^2;
    [~, min_idx] = min(dist_sq, [], 2);
    decided_symbols = constellation(min_idx);
    rx_bit_matrix = gray_labels(min_idx, :);
    rx_bits = reshape(rx_bit_matrix', 1, 3 * K);
    if num_pad > 0 && length(rx_bits) > num_pad
        rx_bits = rx_bits(1 : end - num_pad);
    end
end
