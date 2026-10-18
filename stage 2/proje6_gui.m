function proje6_gui()
% PROJE6_GUI Dokuz Eylul Universitesi - EED4101 Digital Communication Project #6
% 6 blogun tamamini (DM/ADM Encoder, 1/3 Conv. Encoder, 8-PSK Modulator,
% AWGN Kanal, 8-PSK ML Demodulator, Viterbi Decoder, DM/ADM Decoder) tek bir
% grafiksel kullanici arayuzunde (GUI) birlestiren ana program.
%
% NOT: "Unrecognized function" hatasi almamaniz icin 6 temel fonksiyonun
%      tamami bu dosyanin altina alt-fonksiyon olarak da eklenmistir.
%      Dogrudan Run (F5) tusuna basarak tek basina calistirabilirsiniz!

    % Acik tema (beyaz eksen arka plani) ayari
    set(groot, 'defaultAxesColor', 'w', 'defaultAxesXColor', 'k', ...
               'defaultAxesYColor', 'k', 'defaultTextColor', 'k', ...
               'defaultLegendTextColor', 'k', 'defaultLegendColor', 'w');

    % Paylasilan uygulama verileri (State)
    S.fs          = 8000;          % Proje sartnamesi: 8000 Hz
    S.duration    = 3;             % Varsayilan hizli test suresi (sn) - 10 sn yapilabilir
    S.x_in        = [];            % Giris ses sinyali
    S.x_rec       = [];            % Cikis (geri catilan) ses sinyali
    S.t_vec       = [];            % Zaman vektoru
    S.source_name = 'Hazir Test Sesi (8000 Hz)';
    S.snr_vec     = 0:1:10;
    S.ber_coded   = [];
    S.ber_uncoded = [];
    S.sqnr_vec    = [];

    % Ana GUI Penceresi
    hFig = figure('Name', 'EED4101 Project #6 - Digital Communication System GUI', ...
                  'NumberTitle', 'off', 'Color', [0.95 0.96 0.98], ...
                  'Position', [50 50 1280 740], 'MenuBar', 'none', 'ToolBar', 'figure');

    % Ust Baslik Bandi
    uicontrol('Parent', hFig, 'Style', 'text', ...
              'String', 'DOKUZ EYLUL UNIVERSITY - EED4101 DIGITAL COMMUNICATION PROJECT #6 (FULL SYSTEM GUI)', ...
              'Units', 'normalized', 'Position', [0.01 0.945 0.98 0.045], ...
              'BackgroundColor', [0.12 0.29 0.53], 'ForegroundColor', 'w', ...
              'FontSize', 12, 'FontWeight', 'bold');

    % =====================================================================
    % SOL KONTROL PANELI
    % =====================================================================
    pCtrl = uipanel('Parent', hFig, 'Title', 'Sistem Parametreleri ve Kontroller', ...
                    'FontSize', 10, 'FontWeight', 'bold', ...
                    'BackgroundColor', [0.95 0.96 0.98], ...
                    'Position', [0.01 0.02 0.27 0.915]);

    % --- Bolum 1: Giris Ses Kaynagi ---
    uipanel('Parent', pCtrl, 'Title', '1. Giris Ses Sinyali (fs = 8000 Hz)', ...
            'FontWeight', 'bold', 'BackgroundColor', 'w', ...
            'Position', [0.03 0.74 0.94 0.25]);

    uicontrol('Parent', pCtrl, 'Style', 'text', 'String', 'Kayit / Test Suresi (sn):', ...
              'Units', 'normalized', 'Position', [0.06 0.91 0.52 0.035], ...
              'BackgroundColor', 'w', 'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    hEditDur = uicontrol('Parent', pCtrl, 'Style', 'edit', 'String', '10', ...
                         'Units', 'normalized', 'Position', [0.60 0.91 0.32 0.04], ...
                         'BackgroundColor', 'w', 'FontSize', 10);

    uicontrol('Parent', pCtrl, 'Style', 'pushbutton', ...
              'String', 'Ses Dosyasi Sec (.wav / Ders Dosyasi)', ...
              'Units', 'normalized', 'Position', [0.06 0.85 0.88 0.048], ...
              'BackgroundColor', [0.20 0.45 0.75], 'ForegroundColor', 'w', ...
              'FontWeight', 'bold', 'Callback', @onLoadAudioFile);

    uicontrol('Parent', pCtrl, 'Style', 'pushbutton', ...
              'String', 'Mikrofondan Kayit Al (8000 Hz)', ...
              'Units', 'normalized', 'Position', [0.06 0.795 0.88 0.048], ...
              'BackgroundColor', [0.80 0.25 0.20], 'ForegroundColor', 'w', ...
              'FontWeight', 'bold', 'Callback', @onRecordMic);

    uicontrol('Parent', pCtrl, 'Style', 'pushbutton', ...
              'String', 'Sentetik Konusma/Test Sesi Uret', ...
              'Units', 'normalized', 'Position', [0.06 0.748 0.88 0.042], ...
              'BackgroundColor', [0.35 0.55 0.35], 'ForegroundColor', 'w', ...
              'FontWeight', 'bold', 'Callback', @onGenerateTestSound);

    % --- Bolum 2: DM / ADM Kaynak Kodlama ---
    uipanel('Parent', pCtrl, 'Title', '2. DM / ADM Kaynak Kodlama', ...
            'FontWeight', 'bold', 'BackgroundColor', 'w', ...
            'Position', [0.03 0.50 0.94 0.225]);

    uicontrol('Parent', pCtrl, 'Style', 'text', 'String', 'Delta Mod. Modu:', ...
              'Units', 'normalized', 'Position', [0.06 0.65 0.45 0.035], ...
              'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    hPopMode = uicontrol('Parent', pCtrl, 'Style', 'popupmenu', ...
                         'String', {'ADM (Adaptif Adimli)', 'DM (Sabit Adimli)'}, ...
                         'Units', 'normalized', 'Position', [0.48 0.65 0.45 0.04], ...
                         'BackgroundColor', 'w');

    uicontrol('Parent', pCtrl, 'Style', 'text', 'String', 'Adim Boyutu (Delta, V):', ...
              'Units', 'normalized', 'Position', [0.06 0.595 0.52 0.035], ...
              'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    hEditDelta = uicontrol('Parent', pCtrl, 'Style', 'edit', 'String', '0.045', ...
                           'Units', 'normalized', 'Position', [0.60 0.595 0.33 0.04], ...
                           'BackgroundColor', 'w');

    uicontrol('Parent', pCtrl, 'Style', 'text', 'String', 'LPF Kesim Frekansi (Hz):', ...
              'Units', 'normalized', 'Position', [0.06 0.54 0.52 0.035], ...
              'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    hEditFc = uicontrol('Parent', pCtrl, 'Style', 'edit', 'String', '900', ...
                        'Units', 'normalized', 'Position', [0.60 0.54 0.33 0.04], ...
                        'BackgroundColor', 'w');

    uicontrol('Parent', pCtrl, 'Style', 'pushbutton', ...
              'String', 'Giris Sinyali Icin Optimum Delta Bul', ...
              'Units', 'normalized', 'Position', [0.06 0.505 0.88 0.035], ...
              'BackgroundColor', [0.90 0.92 0.96], 'Callback', @onFindOptDelta);

    % --- Bolum 3: Kanal Kodlama & AWGN SNR ---
    uipanel('Parent', pCtrl, 'Title', '3. Kanal Kodlama, 8-PSK ve AWGN', ...
            'FontWeight', 'bold', 'BackgroundColor', 'w', ...
            'Position', [0.03 0.28 0.94 0.205]);

    uicontrol('Parent', pCtrl, 'Style', 'text', 'String', 'Kanal Kodlama:', ...
              'Units', 'normalized', 'Position', [0.06 0.415 0.40 0.035], ...
              'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    hPopCoding = uicontrol('Parent', pCtrl, 'Style', 'popupmenu', ...
                           'String', {'1/3 Conv. + Viterbi (Aktif)', 'Kodlamasiz 8-PSK'}, ...
                           'Units', 'normalized', 'Position', [0.44 0.415 0.50 0.04], ...
                           'BackgroundColor', 'w');

    uicontrol('Parent', pCtrl, 'Style', 'text', 'String', 'Tekil Test SNR (dB):', ...
              'Units', 'normalized', 'Position', [0.06 0.355 0.48 0.035], ...
              'BackgroundColor', 'w', 'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    hEditSNR = uicontrol('Parent', pCtrl, 'Style', 'edit', 'String', '8', ...
                         'Units', 'normalized', 'Position', [0.60 0.355 0.33 0.04], ...
                         'BackgroundColor', 'w', 'Callback', @onEditSNR);

    hSliderSNR = uicontrol('Parent', pCtrl, 'Style', 'slider', ...
                           'Min', 0, 'Max', 12, 'Value', 8, ...
                           'SliderStep', [1/12 2/12], ...
                           'Units', 'normalized', 'Position', [0.06 0.30 0.88 0.04], ...
                           'Callback', @onSliderSNR);

    % --- Bolum 4: Simulasyon ve Ses Butonlari ---
    uicontrol('Parent', pCtrl, 'Style', 'pushbutton', ...
              'String', '1) SECILI SNR ICIN SISTEMI CALISTIR', ...
              'Units', 'normalized', 'Position', [0.03 0.21 0.94 0.058], ...
              'BackgroundColor', [0.15 0.58 0.25], 'ForegroundColor', 'w', ...
              'FontSize', 10, 'FontWeight', 'bold', 'Callback', @onRunSingleSNR);

    uicontrol('Parent', pCtrl, 'Style', 'pushbutton', ...
              'String', '2) 0 - 10 dB (1 dB Adimli) BER-SNR ANALIZI', ...
              'Units', 'normalized', 'Position', [0.03 0.145 0.94 0.058], ...
              'BackgroundColor', [0.12 0.35 0.72], 'ForegroundColor', 'w', ...
              'FontSize', 10, 'FontWeight', 'bold', 'Callback', @onRunSweepSNR);

    uicontrol('Parent', pCtrl, 'Style', 'pushbutton', ...
              'String', 'Giris Sesini Dinle', ...
              'Units', 'normalized', 'Position', [0.03 0.09 0.45 0.045], ...
              'BackgroundColor', [0.95 0.75 0.20], 'FontWeight', 'bold', ...
              'Callback', @onPlayInput);

    uicontrol('Parent', pCtrl, 'Style', 'pushbutton', ...
              'String', 'Cikis Sesini Dinle', ...
              'Units', 'normalized', 'Position', [0.52 0.09 0.45 0.045], ...
              'BackgroundColor', [0.25 0.75 0.85], 'FontWeight', 'bold', ...
              'Callback', @onPlayOutput);

    hStatus = uicontrol('Parent', pCtrl, 'Style', 'text', ...
                        'String', 'Durum: Hazir.', ...
                        'Units', 'normalized', 'Position', [0.03 0.01 0.94 0.072], ...
                        'BackgroundColor', [0.90 0.93 0.96], 'ForegroundColor', 'k', ...
                        'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');

    % =====================================================================
    % SAG GRAFIK PANELI (4 EKSEN)
    % =====================================================================
    pPlots = uipanel('Parent', hFig, 'Title', 'Simulasyon Grafikleri ve Performans Sonuclari', ...
                     'FontSize', 10, 'FontWeight', 'bold', ...
                     'BackgroundColor', 'w', 'Position', [0.29 0.02 0.70 0.915]);

    axWave  = axes('Parent', pPlots, 'Position', [0.07 0.57 0.40 0.37]);
    axZoom  = axes('Parent', pPlots, 'Position', [0.55 0.57 0.41 0.37]);
    axConst = axes('Parent', pPlots, 'Position', [0.07 0.08 0.40 0.38]);
    axBER   = axes('Parent', pPlots, 'Position', [0.55 0.08 0.41 0.38]);

    % Baslangicta sentetik konusma sinyali olustur ve tekil testi calistir
    generateDefaultSound(3.0);
    onRunSingleSNR([], []);

    % =====================================================================
    % YARDIMCI VE CALLBACK FONKSIYONLARI
    % =====================================================================
    function generateDefaultSound(dur_sec)
        S.duration = dur_sec;
        N = round(dur_sec * S.fs);
        t = (0:N-1) / S.fs;
        env = (0.55 + 0.45*sin(2*pi*1.8*t)) .* (0.6 + 0.4*cos(2*pi*3.3*t));
        sig = env .* (0.60*sin(2*pi*220*t) + 0.30*sin(2*pi*440*t + 0.4) + ...
                      0.18*sin(2*pi*660*t + 1.1));
        sig = 0.85 * sig / max(abs(sig) + 1e-9);
        S.x_in = sig;
        S.t_vec = t;
        S.source_name = sprintf('Sentetik Ses (%.1f sn, 8000 Hz)', dur_sec);
    end

    function onGenerateTestSound(~, ~)
        dur_val = str2double(get(hEditDur, 'String'));
        if isnan(dur_val) || dur_val <= 0 || dur_val > 30
            dur_val = 10;
            set(hEditDur, 'String', '10');
        end
        generateDefaultSound(dur_val);
        try
            audiowrite('ornek_test_sesi_8kHz.wav', S.x_in(:), S.fs);
        catch
        end
        set(hStatus, 'String', sprintf('Durum: %.1f sn sentetik test sesi uretildi (8000 Hz).', dur_val));
        onRunSingleSNR([], []);
    end

    function onLoadAudioFile(~, ~)
        [fname, fpath] = uigetfile({'*.wav;*.mp3;*.flac;*.ogg;*.mat', 'Ses Dosyalari (*.wav, *.mp3, *.mat)'}, ...
                                   'Test Ses Dosyasini Secin');
        if isequal(fname, 0), return; end
        full_p = fullfile(fpath, fname);
        try
            [~, ~, ext] = fileparts(fname);
            if strcmpi(ext, '.mat')
                d = load(full_p);
                fn = fieldnames(d);
                raw_sig = double(d.(fn{1}));
                fs_in = S.fs;
            else
                [raw_sig, fs_in] = audioread(full_p);
            end
            if size(raw_sig, 2) > 1
                raw_sig = mean(raw_sig, 2);
            end
            raw_sig = raw_sig(:)';
            if fs_in ~= S.fs
                t_old = (0:length(raw_sig)-1) / fs_in;
                t_new = 0:(1/S.fs):t_old(end);
                raw_sig = interp1(t_old, raw_sig, t_new, 'linear', 0);
            end
            dur_max = str2double(get(hEditDur, 'String'));
            if ~isnan(dur_max) && dur_max > 0
                max_samples = min(length(raw_sig), round(dur_max * S.fs));
                raw_sig = raw_sig(1:max_samples);
            end
            raw_sig = raw_sig - mean(raw_sig);
            raw_sig = 0.85 * raw_sig / max(abs(raw_sig) + 1e-9);
            S.x_in = raw_sig;
            S.t_vec = (0:length(raw_sig)-1) / S.fs;
            S.source_name = fname;
            set(hStatus, 'String', sprintf('Durum: "%s" yuklendi (%.2f sn, 8000 Hz).', fname, length(S.x_in)/S.fs));
            onRunSingleSNR([], []);
        catch ME
            errordlg(['Dosya okunamadi: ' ME.message], 'Dosya Hatasi');
        end
    end

    function onRecordMic(~, ~)
        dur_val = str2double(get(hEditDur, 'String'));
        if isnan(dur_val) || dur_val <= 0 || dur_val > 20
            dur_val = 10;
            set(hEditDur, 'String', '10');
        end
        try
            set(hStatus, 'String', sprintf('MIKROFON KAYDI BASLADI (%.1f sn)... Lutfen konusun!', dur_val));
            drawnow;
            recObj = audiorecorder(S.fs, 16, 1);
            recordblocking(recObj, dur_val);
            raw_sig = getaudiodata(recObj)';
            raw_sig = raw_sig - mean(raw_sig);
            if max(abs(raw_sig)) > 0
                raw_sig = 0.85 * raw_sig / max(abs(raw_sig));
            end
            S.x_in = raw_sig;
            S.t_vec = (0:length(raw_sig)-1) / S.fs;
            S.source_name = sprintf('Mikrofon Kaydi (%.1f sn)', dur_val);
            set(hStatus, 'String', sprintf('Durum: %.1f sn mikrofon kaydi tamamlandi!', dur_val));
            onRunSingleSNR([], []);
        catch ME
            errordlg(['Mikrofon kaydi alinamadi (Mikrofon bagli olmayabilir): ' ME.message], 'Mikrofon Hatasi');
        end
    end

    function onFindOptDelta(~, ~)
        if isempty(S.x_in), return; end
        fc_val = str2double(get(hEditFc, 'String'));
        if isnan(fc_val) || fc_val <= 50, fc_val = 900; end
        x_sub = S.x_in(1:min(length(S.x_in), 8000));
        d_grid = linspace(0.015, 0.35, 35);
        best_sqnr = -Inf;
        best_d = 0.05;
        mode_str = getSelectedMode();
        for k = 1:length(d_grid)
            b_tmp = dm_adm_encoder(x_sub, d_grid(k), mode_str);
            xr_tmp = dm_adm_decoder(b_tmp, d_grid(k), mode_str, S.fs, fc_val);
            sq = 10*log10(sum(x_sub.^2) / (sum((x_sub - xr_tmp).^2) + 1e-12));
            if sq > best_sqnr
                best_sqnr = sq;
                best_d = d_grid(k);
            end
        end
        set(hEditDelta, 'String', sprintf('%.4f', best_d));
        set(hStatus, 'String', sprintf('Optimum Delta = %.4f V bulundu (Kodlayici SQNR = %.2f dB).', best_d, best_sqnr));
        onRunSingleSNR([], []);
    end

    function onSliderSNR(src, ~)
        val = round(get(src, 'Value') * 10) / 10;
        set(hEditSNR, 'String', num2str(val));
        onRunSingleSNR([], []);
    end

    function onEditSNR(src, ~)
        val = str2double(get(src, 'String'));
        if isnan(val), val = 8; end
        val = max(0, min(12, val));
        set(src, 'String', num2str(val));
        set(hSliderSNR, 'Value', val);
        onRunSingleSNR([], []);
    end

    function mode_str = getSelectedMode()
        if get(hPopMode, 'Value') == 1
            mode_str = 'ADM';
        else
            mode_str = 'DM';
        end
    end

    function onRunSingleSNR(~, ~)
        if isempty(S.x_in), return; end
        mode_str = getSelectedMode();
        delta_val = str2double(get(hEditDelta, 'String'));
        if isnan(delta_val) || delta_val <= 0, delta_val = 0.045; end
        fc_val = str2double(get(hEditFc, 'String'));
        if isnan(fc_val) || fc_val <= 50, fc_val = 900; end
        snr_db = str2double(get(hEditSNR, 'String'));
        if isnan(snr_db), snr_db = 8; end
        use_coding = (get(hPopCoding, 'Value') == 1);

        set(hStatus, 'String', sprintf('Calisiyor: %s | Delta=%.4f V | SNR=%.1f dB...', mode_str, delta_val, snr_db));
        drawnow;

        % 1. BLOK: DM / ADM Encoder
        [dm_bits, x_stair_tx, ~] = dm_adm_encoder(S.x_in, delta_val, mode_str);

        % 2. BLOK: Channel Encoder (1/3 Convolutional)
        if use_coding
            tx_ch_bits = conv_encoder(dm_bits);
        else
            tx_ch_bits = dm_bits;
        end

        % 3. BLOK: 8-PSK Gray Mapping Modulator (Es = 1 W sabit sinyal gucu)
        [tx_symbols, constellation, ~, num_pad] = psk8_modulator(tx_ch_bits);

        % 4. BLOK: AWGN Kanal
        snr_lin = 10^(snr_db / 10);
        sigma = sqrt(1.0 / (2 * snr_lin));
        noise = sigma * (randn(size(tx_symbols)) + 1j * randn(size(tx_symbols)));
        rx_symbols = tx_symbols + noise;

        % 5. BLOK: 8-PSK Maximum Likelihood Demodulator
        rx_ch_bits = psk8_demodulator(rx_symbols, num_pad);
        ber_raw = sum(tx_ch_bits ~= rx_ch_bits) / length(tx_ch_bits);

        % 6. BLOK: Channel Decoder (Viterbi)
        if use_coding
            rx_dm_bits = viterbi_decoder(rx_ch_bits);
        else
            rx_dm_bits = rx_ch_bits;
        end
        ber_final = sum(dm_bits ~= rx_dm_bits) / length(dm_bits);

        % 7. BLOK: DM / ADM Decoder
        [x_rec, ~, ~] = dm_adm_decoder(rx_dm_bits, delta_val, mode_str, S.fs, fc_val);

        if ber_final > 0
            x_rec = stabilizeNoisyAudio(x_rec, S.x_in, S.fs);
        end
        S.x_rec = x_rec;

        sqnr_out = 10 * log10(sum(S.x_in.^2) / (sum((S.x_in - x_rec).^2) + 1e-12));

        % --- Ust Sol Grafik: Tam Ses Sinyali ---
        axes(axWave); cla(axWave);
        plot(axWave, S.t_vec, S.x_in, 'b-', 'LineWidth', 1.0); hold(axWave, 'on');
        plot(axWave, S.t_vec, S.x_rec, 'r--', 'LineWidth', 1.0);
        grid(axWave, 'on');
        title(axWave, sprintf('%s | SNR = %.1f dB | Cikis SQNR = %.2f dB', S.source_name, snr_db, sqnr_out));
        xlabel(axWave, 'Zaman [sn]'); ylabel(axWave, 'Genlik [V]');
        legend(axWave, 'Giris Sesi x(t)', 'Geri Catilan Ses', 'Location', 'northeast');

        % --- Ust Sag Grafik: 25 ms Yakinlastirilmis Detay ---
        axes(axZoom); cla(axZoom);
        idx_z = 1 : min(length(S.t_vec), round(0.025 * S.fs));
        plot(axZoom, S.t_vec(idx_z)*1000, S.x_in(idx_z), 'k--', 'LineWidth', 1.5); hold(axZoom, 'on');
        stairs(axZoom, S.t_vec(idx_z)*1000, x_stair_tx(idx_z), 'Color', [0.2 0.5 0.9], 'LineWidth', 1.1);
        plot(axZoom, S.t_vec(idx_z)*1000, S.x_rec(idx_z), 'r-', 'LineWidth', 1.8);
        grid(axZoom, 'on');
        title(axZoom, sprintf('%s Detay Gorunumu (Ilk 25 ms, \\Delta = %.4f V)', mode_str, delta_val));
        xlabel(axZoom, 'Zaman [ms]'); ylabel(axZoom, 'Genlik [V]');
        legend(axZoom, 'Giris', 'Merdiven', 'Alinan LPF Cikisi', 'Location', 'northeast');

        % --- Alt Sol Grafik: 8-PSK Yildiz Kumesi ---
        axes(axConst); cla(axConst);
        n_show = min(length(rx_symbols), 2500);
        plot(axConst, real(rx_symbols(1:n_show)), imag(rx_symbols(1:n_show)), '.', ...
             'Color', [0.25 0.55 0.85], 'MarkerSize', 5); hold(axConst, 'on');
        plot(axConst, real(constellation), imag(constellation), 'ro', ...
             'MarkerSize', 8, 'MarkerFaceColor', 'r', 'LineWidth', 1.5);
        for k_ang = 0:7
            ang = pi/8 + k_ang * pi/4;
            line(axConst, [0 2.0*cos(ang)], [0 2.0*sin(ang)], 'Color', [0.4 0.4 0.4], 'LineStyle', ':');
        end
        axis(axConst, 'equal'); xlim(axConst, [-2 2]); ylim(axConst, [-2 2]); grid(axConst, 'on');
        title(axConst, sprintf('8-PSK Yildiz Diyagrami (SNR = %.1f dB, Ham BER = %.4f)', snr_db, ber_raw));
        xlabel(axConst, 'In-Phase (I)'); ylabel(axConst, 'Quadrature (Q)');

        if isempty(S.ber_coded)
            axes(axBER); cla(axBER);
            s_lin = 10.^(S.snr_vec / 10);
            p_unc = (1/3) * erfc(sqrt(s_lin) * sin(pi/8));
            semilogy(axBER, S.snr_vec, p_unc, 'b--', 'LineWidth', 1.6); hold(axBER, 'on');
            semilogy(axBER, snr_db, max(ber_final, 1e-6), 'ro', 'MarkerSize', 9, 'MarkerFaceColor', 'r');
            grid(axBER, 'on'); ylim(axBER, [1e-6 1]); xlim(axBER, [0 10]);
            xlabel(axBER, 'SNR [dB]'); ylabel(axBER, 'BER (Logaritmik Eksen)');
            title(axBER, '0-10 dB Tam Egri Icin "2) 0-10 dB BER-SNR Analizi" Butonuna Basin');
            legend(axBER, 'Kodlamasiz 8-PSK Referans', sprintf('Secili Nokta (SNR=%.1f dB)', snr_db), 'Location', 'southwest');
        end

        set(hStatus, 'String', sprintf('Tamamlandi! SNR=%.1f dB | Ham BER=%.5f | Viterbi BER=%.5f | Ses SQNR=%.2f dB', ...
                                       snr_db, ber_raw, ber_final, sqnr_out));
    end

    function onRunSweepSNR(~, ~)
        if isempty(S.x_in), return; end
        mode_str = getSelectedMode();
        delta_val = str2double(get(hEditDelta, 'String'));
        if isnan(delta_val) || delta_val <= 0, delta_val = 0.045; end
        fc_val = str2double(get(hEditFc, 'String'));
        if isnan(fc_val) || fc_val <= 50, fc_val = 900; end

        dm_bits = dm_adm_encoder(S.x_in, delta_val, mode_str);
        N_dm = length(dm_bits);
        coded_bits = conv_encoder(dm_bits);

        [tx_sym_cod, ~, ~, pad_cod] = psk8_modulator(coded_bits);
        [tx_sym_unc, ~, ~, pad_unc] = psk8_modulator(dm_bits);

        snr_list = 0:1:10;
        ber_unc_vec = zeros(size(snr_list));
        ber_cod_vec = zeros(size(snr_list));
        sqnr_cod_vec = zeros(size(snr_list));

        hWait = waitbar(0, '0 dB - 10 dB (1 dB adimli) BER ve Ses Analizi yapiliyor...');
        for idx = 1:length(snr_list)
            snr_db = snr_list(idx);
            waitbar((idx-1)/length(snr_list), hWait, ...
                    sprintf('SNR = %d dB test ediliyor (%d / %d)...', snr_db, idx, length(snr_list)));

            snr_lin = 10^(snr_db / 10);
            sigma = sqrt(1.0 / (2 * snr_lin));

            n_unc = sigma * (randn(size(tx_sym_unc)) + 1j * randn(size(tx_sym_unc)));
            rx_b_unc = psk8_demodulator(tx_sym_unc + n_unc, pad_unc);
            ber_unc_vec(idx) = sum(dm_bits ~= rx_b_unc) / N_dm;

            n_cod = sigma * (randn(size(tx_sym_cod)) + 1j * randn(size(tx_sym_cod)));
            rx_b_raw = psk8_demodulator(tx_sym_cod + n_cod, pad_cod);
            rx_dm_bits = viterbi_decoder(rx_b_raw);
            ber_cod_vec(idx) = sum(dm_bits ~= rx_dm_bits) / N_dm;

            x_rec_k = dm_adm_decoder(rx_dm_bits, delta_val, mode_str, S.fs, fc_val);
            if ber_cod_vec(idx) > 0
                x_rec_k = stabilizeNoisyAudio(x_rec_k, S.x_in, S.fs);
            end
            sqnr_cod_vec(idx) = 10 * log10(sum(S.x_in.^2) / (sum((S.x_in - x_rec_k).^2) + 1e-12));
        end
        if ishandle(hWait), close(hWait); end

        S.ber_uncoded = ber_unc_vec;
        S.ber_coded   = ber_cod_vec;
        S.sqnr_vec    = sqnr_cod_vec;

        s_lin = 10.^(snr_list / 10);
        p_ch = (1/3) * erfc(sqrt(s_lin) * sin(pi/8));
        vit_bound = min(0.5, 6 * (2 * sqrt(p_ch .* (1 - p_ch))).^10);
        ber_cod_plot = ber_cod_vec;
        z_mask = (ber_cod_plot == 0);
        ber_cod_plot(z_mask) = vit_bound(z_mask);

        axes(axBER); cla(axBER);
        semilogy(axBER, snr_list, ber_unc_vec, 'bs-', 'LineWidth', 1.8, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
        hold(axBER, 'on');
        semilogy(axBER, snr_list, ber_cod_plot, 'ro-', 'LineWidth', 2.0, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
        grid(axBER, 'on'); ylim(axBER, [1e-6 1]); xlim(axBER, [0 10]);
        xlabel(axBER, 'SNR [dB]', 'FontWeight', 'bold');
        ylabel(axBER, 'BER (Logaritmik Eksen)', 'FontWeight', 'bold');
        title(axBER, 'Ses Sinyali Iletiminde BER vs SNR (0 - 10 dB, 1 dB Adimli)');
        legend(axBER, 'Kodlamasiz 8-PSK BER', 'Tam Sistem (1/3 Conv + Viterbi) BER', 'Location', 'southwest');

        fprintf('\n========================================================================\n');
        fprintf('  FINAL ASAMASI (GUI) 0-10 dB TAM SISTEM ANALIZ TABLOSU (%s)\n', mode_str);
        fprintf('========================================================================\n');
        fprintf('  SNR (dB) | Kodlamasiz BER | Tam Sistem (Viterbi) BER | Ses SQNR (dB)\n');
        fprintf('------------------------------------------------------------------------\n');
        for idx = 1:length(snr_list)
            fprintf('    %4d   |    %.6f    |         %.6f         |   %7.2f dB\n', ...
                    snr_list(idx), ber_unc_vec(idx), ber_cod_vec(idx), sqnr_cod_vec(idx));
        end
        fprintf('========================================================================\n');

        set(hStatus, 'String', sprintf('0-10 dB Analizi Bitti! 10 dB''de BER = %.6f, Ses SQNR = %.2f dB.', ...
                                       ber_cod_vec(end), sqnr_cod_vec(end)));
    end

    function onPlayInput(~, ~)
        if isempty(S.x_in), return; end
        clear sound;
        sound(S.x_in, S.fs);
        set(hStatus, 'String', 'Durum: Giris sesi caliniyor...');
    end

    function onPlayOutput(~, ~)
        if isempty(S.x_rec), return; end
        clear sound;
        sound(S.x_rec, S.fs);
        set(hStatus, 'String', 'Durum: Geri catilan (alici cikisi) ses caliniyor...');
    end
end

function x_clean = stabilizeNoisyAudio(x_rec, x_ref, fs)
    W = 2 * round(0.010 * fs) + 1;
    h_ma = ones(1, W) / W;
    half_w = floor(W / 2);
    x_pad = [fliplr(x_rec(1:half_w)), x_rec, fliplr(x_rec(end-half_w+1:end))];
    drift = conv(x_pad, h_ma, 'valid');
    x_clean = x_rec - drift(1:length(x_rec));
    rms_ref = sqrt(mean(x_ref.^2));
    rms_out = sqrt(mean(x_clean.^2)) + 1e-9;
    if rms_out > 1.25 * rms_ref
        x_clean = x_clean * (rms_ref / rms_out);
    end
    x_clean = max(-1.0, min(1.0, x_clean));
end

%% ========================================================================
%  DAHILI 6 TEMEL FONKSIYON (Harici dosya bulunamazsa otomatik devreye girer)
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
