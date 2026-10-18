function [x_reconstructed, x_stair, delta_hist] = dm_adm_decoder(bit_stream, delta_init, mode, fs, fm_cutoff)
% DM_ADM_DECODER Alinan bit dizisini (0 ve 1) toplayici (accumulator) ve
% Alcak Geciren Filtre (LPF) kullanarak analog sinyale geri catar.
%
% Onemli: Bu dosyayi MATLAB'da tam olarak "dm_adm_decoder.m" adiyla kaydedin.
%
% Girisler:
%   bit_stream : Alinan ikili bit dizisi (0 ve 1)
%   delta_init : Baslangic adim boyutu (Step size, Volt)
%   mode       : 'DM' (Sabit adimli) veya 'ADM' (Adaptif adimli)
%   fs         : Ornekleme frekansi (Hz) - varsayilan 8000 Hz
%   fm_cutoff  : Mesaj sinyali bant genisligi / referans frekansi (Hz)
%
% Cikislar:
%   x_reconstructed : LPF sonrasi yumusatilmis geri catilan sinyal
%   x_stair         : Filtreleme oncesi merdiven (staircase) sinyali
%   delta_hist      : Cozucude hesaplanan adim boyutu gecmisi

    if nargin < 4, fs = 8000; end
    if nargin < 5, fm_cutoff = 200; end

    bit_stream = bit_stream(:)';
    N = length(bit_stream);
    
    x_stair    = zeros(1, N);
    delta_hist = zeros(1, N);
    
    % Kodlayici ile birebir ayni ADM parametreleri
    K_up   = 1.25;
    K_down = 1 / 1.25;
    delta_min = delta_init * 0.25;
    delta_max = delta_init * 16;
    
    x_pred = 0;
    curr_delta = delta_init;
    prev_b = 1;
    
    for n = 1:N
        if bit_stream(n) == 1
            curr_b = 1;
        else
            curr_b = -1;
        end
        
        % ADM modunda adim boyutunu guncelle
        if strcmpi(mode, 'ADM') && n > 1
            if curr_b == prev_b
                curr_delta = min(curr_delta * K_up, delta_max);
            else
                curr_delta = max(curr_delta * K_down, delta_min);
            end
        end
        
        % Merdiven (staircase) degerini olustur
        x_pred = x_pred + curr_b * curr_delta;
        
        x_stair(n)    = x_pred;
        delta_hist(n) = curr_delta;
        prev_b        = curr_b;
    end
    
    % Kuantalama (yuksek frekansli merdiven) gurultusunu bastirmak icin
    % sifir-faz gecikmeli Hamming pencereli Sinc Alcak Geciren Filtre (LPF)
    % (Toolbox fonksiyonu kullanmadan kendi yazdigimiz FIR LPF)
    fc = min(2.5 * fm_cutoff, 0.45 * fs); % Kesim frekansi (Hz)
    norm_fc = fc / (fs / 2);              % Normalize kesim frekansi (0..1)
    M = 20;                               % Filtre yari-derecesi (2*M+1 katsayi)
    n_idx = -M:M;
    
    % Ideal alcak geciren sinc cevabi: sin(pi*wc*n) / (pi*n)
    x_arg = norm_fc * n_idx;
    sinc_val = ones(size(x_arg));
    nz = (x_arg ~= 0);
    sinc_val(nz) = sin(pi * x_arg(nz)) ./ (pi * x_arg(nz));
    h = norm_fc * sinc_val;
    
    % Hamming penceresi (0.54 - 0.46*cos(2*pi*k/(2*M)))
    k_win = 0:(2*M);
    w_hamm = 0.54 - 0.46 * cos(2 * pi * k_win / (2 * M));
    h = h .* w_hamm;
    h = h / sum(h); % Birim DC kazanc normalizasyonu
    
    % Uclardaki gecici etkileri azaltmak icin simetrik uzatma ve konvolusyon
    pad_left  = fliplr(x_stair(1:M));
    pad_right = fliplr(x_stair(end-M+1:end));
    x_padded  = [pad_left, x_stair, pad_right];
    
    y_conv = conv(x_padded, h, 'valid');
    x_reconstructed = y_conv(1:N);
end
