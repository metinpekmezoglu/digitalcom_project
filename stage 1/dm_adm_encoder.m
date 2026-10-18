function [bit_stream, x_stair, delta_hist] = dm_adm_encoder(x, delta_init, mode)
% DM_ADM_ENCODER Giris sinyalini Sabit (DM) veya Adaptif (ADM) Delta
% Modulasyonu ile ikili (0 ve 1) bit dizisine kodlar.
%
% Onemli: Bu dosyayi MATLAB'da tam olarak "dm_adm_encoder.m" adiyla kaydedin.
%
% Girisler:
%   x          : Giris analog/ayrik sinyali (1xN veya Nx1 vektor)
%   delta_init : Baslangic adim boyutu (Step size, Volt)
%   mode       : 'DM' (Sabit adimli) veya 'ADM' (Adaptif adimli)
%
% Cikislar:
%   bit_stream : Kodlanmis ikili bit dizisi (0 ve 1'lerden olusur)
%   x_stair    : Kodlayici icindeki merdiven (staircase) tahmin sinyali
%   delta_hist : Her ornekteki adim boyutu degisimi

    x = x(:)'; % Satir vektorune cevir
    N = length(x);
    
    bit_stream = zeros(1, N);
    x_stair    = zeros(1, N);
    delta_hist = zeros(1, N);
    
    % Adaptif DM (Jayant Sabit Carpanli Adaptasyon) parametreleri
    K_up   = 1.25;                 % Ardisik ayni bit geldiginde buyutme carpani
    K_down = 1 / 1.25;             % Bit degistiginde kucultme carpani (0.80)
    delta_min = delta_init * 0.25; % Minimum adim boyutu siniri
    delta_max = delta_init * 16;   % Maksimum adim boyutu siniri
    
    x_pred = 0;                    % Baslangic tahmin degeri
    curr_delta = delta_init;
    prev_b = 1;                    % Onceki isaret (+1 veya -1)
    
    for n = 1:N
        % Fark (hata) sinyali e(n) = x(n) - x_pred(n-1)
        err = x(n) - x_pred;
        
        if err >= 0
            bit_stream(n) = 1;
            curr_b = 1;
        else
            bit_stream(n) = 0;
            curr_b = -1;
        end
        
        % ADM modunda adim boyutunu guncelle
        if strcmpi(mode, 'ADM') && n > 1
            if curr_b == prev_b
                % Egim asimini onlemek icin adimi buyut
                curr_delta = min(curr_delta * K_up, delta_max);
            else
                % Tanecik gurultusunu azaltmak icin adimi kucult
                curr_delta = max(curr_delta * K_down, delta_min);
            end
        end
        
        % Merdiven (staircase) tahminini guncelle
        x_pred = x_pred + curr_b * curr_delta;
        
        x_stair(n)    = x_pred;
        delta_hist(n) = curr_delta;
        prev_b        = curr_b;
    end
end
