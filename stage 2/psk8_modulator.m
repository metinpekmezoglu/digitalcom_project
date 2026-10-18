function [tx_symbols, constellation, gray_labels, num_pad] = psk8_modulator(bit_stream)
% PSK8_MODULATOR Ikili bit dizisini Gray kodlamali (Gray mapping) 8-PSK
% tabanbant (baseband) karmasik sembollerine esler.
%
% Onemli: Bu dosyayi MATLAB'da tam olarak "psk8_modulator.m" adiyla kaydedin.
%         MATLAB Communication Toolbox fonksiyonlari KULLANILMAMISTIR.
%
% Giris:
%   bit_stream    : Giris bit dizisi (0 ve 1'lerden olusan vektor)
%
% Cikislar:
%   tx_symbols    : Birim cember uzerindeki 8-PSK karmasik sembolleri (Es = 1)
%   constellation : 8 referans yildiz kumesi noktasi (m = 0..7)
%   gray_labels   : Her yildiz noktasina karsilik gelen 3-bitlik Gray etiketleri
%   num_pad       : Bit sayisi 3'un kati degilse sona eklenen sifir sayisi

    bit_stream = bit_stream(:)'; % Satir vektorune cevir
    N_bits = length(bit_stream);
    
    % Bit sayisi 3'un kati degilse sona 0 ekle (padding)
    rem_bits = mod(N_bits, 3);
    if rem_bits ~= 0
        num_pad = 3 - rem_bits;
        bit_stream = [bit_stream, zeros(1, num_pad)];
    else
        num_pad = 0;
    end
    
    % 8-PSK referans yildiz kumesi (Birim cember: Es = 1 sabit sinyal gucu)
    m_idx = 0:7;
    constellation = exp(1j * (2 * pi * m_idx / 8));
    
    % 3-bitlik Gray kod tablosu (komsu semboller arasinda sadece 1 bit fark vardir)
    % Indeks (m+1):  1(000), 2(001), 3(011), 4(010), 5(110), 6(111), 7(101), 8(100)
    gray_labels = [
        0 0 0;  % m = 0 -> Faz: 0
        0 0 1;  % m = 1 -> Faz: pi/4
        0 1 1;  % m = 2 -> Faz: 2*pi/4 (pi/2)
        0 1 0;  % m = 3 -> Faz: 3*pi/4
        1 1 0;  % m = 4 -> Faz: 4*pi/4 (pi)
        1 1 1;  % m = 5 -> Faz: 5*pi/4
        1 0 1;  % m = 6 -> Faz: 6*pi/4 (3*pi/2)
        1 0 0   % m = 7 -> Faz: 7*pi/4
    ];
    
    % 3-bitlik decimal degerden (0..7) Gray yildiz indisine (1..8) donusum tablosu
    % dec = b1*4 + b2*2 + b3 (0..7) -> dec+1 indisi:
    % 000(0)->1, 001(1)->2, 010(2)->4, 011(3)->3, 100(4)->8, 101(5)->7, 110(6)->5, 111(7)->6
    dec_to_const_idx = [1, 2, 4, 3, 8, 7, 5, 6];
    
    % Bitleri 3'erli gruplara ayir (Her sutun 1 sembolun 3 bitidir)
    num_symbols = length(bit_stream) / 3;
    bit_matrix = reshape(bit_stream, 3, num_symbols)'; % (num_symbols x 3)
    
    % Ikili ucluleri onluk (0..7) sayiya cevir
    dec_vals = bit_matrix(:,1)*4 + bit_matrix(:,2)*2 + bit_matrix(:,3);
    
    % Gray esleme ile sembol indislerini bul ve karmasik sembolleri uret
    symbol_indices = dec_to_const_idx(dec_vals + 1);
    tx_symbols = constellation(symbol_indices);
end
