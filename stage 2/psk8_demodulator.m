function [rx_bits, decided_symbols] = psk8_demodulator(rx_symbols, num_pad)
% PSK8_DEMODULATOR Gurultulu 8-PSK karmasik sembollerini Maximum Likelihood
% (ML - Minimum Oklid Mesafesi) karar algoritmasi ile ikili bitlere cozer.
%
% Onemli: Bu dosyayi MATLAB'da tam olarak "psk8_demodulator.m" adiyla kaydedin.
%         MATLAB Communication Toolbox fonksiyonlari KULLANILMAMISTIR.
%
% Girisler:
%   rx_symbols      : Kanaldan alinan gurultulu karmasik semboller (1xK veya Kx1)
%   num_pad         : Modulatorde eklenen dolgu (padding) biti sayisi (varsayilan 0)
%
% Cikislar:
%   rx_bits         : Cozulmus ikili bit dizisi (0 ve 1'lerden olusan satir vektoru)
%   decided_symbols : ML karar sonrasi en yakin referans yildiz sembolleri

    if nargin < 2
        num_pad = 0;
    end
    
    rx_col = rx_symbols(:); % Sutun vektoru (K x 1)
    K = length(rx_col);
    
    % 8-PSK referans yildiz kumesi noktalari (1 x 8)
    m_idx = 0:7;
    constellation = exp(1j * (2 * pi * m_idx / 8));
    
    % Her yildiz noktasina karsilik gelen 3-bitlik Gray etiket tablosu (8 x 3)
    gray_labels = [
        0 0 0;  % m = 0 -> Faz: 0
        0 0 1;  % m = 1 -> Faz: pi/4
        0 1 1;  % m = 2 -> Faz: 2*pi/4
        0 1 0;  % m = 3 -> Faz: 3*pi/4
        1 1 0;  % m = 4 -> Faz: 4*pi/4
        1 1 1;  % m = 5 -> Faz: 5*pi/4
        1 0 1;  % m = 6 -> Faz: 6*pi/4
        1 0 0   % m = 7 -> Faz: 7*pi/4
    ];
    
    % Maximum Likelihood (ML) Karar Kurali:
    % AWGN kanalda ML karar kurali, alinan r_k sembolunun 8 referans noktasi
    % c_m ile arasindaki Oklid mesafesinin karesini |r_k - c_m|^2 minimize eder.
    dist_sq = abs(repmat(rx_col, 1, 8) - repmat(constellation, K, 1)).^2;
    
    % En kucuk mesafeye sahip referans sembol indisini (1..8) sec
    [~, min_idx] = min(dist_sq, [], 2);
    
    % Secilen yildiz noktalarini ve bunlara ait 3-bitlik Gray dizilerini al
    decided_symbols = constellation(min_idx);
    rx_bit_matrix = gray_labels(min_idx, :); % (K x 3)
    
    % (K x 3) matrisini satir satir okuyarak tek boyutlu bit dizisine cevir
    rx_bits = reshape(rx_bit_matrix', 1, 3 * K);
    
    % Eger modulatorde padding yapildiysa sondaki fazla bitleri cikar
    if num_pad > 0 && length(rx_bits) > num_pad
        rx_bits = rx_bits(1 : end - num_pad);
    end
end
