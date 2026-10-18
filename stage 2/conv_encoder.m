function [coded_bits, state_history] = conv_encoder(msg_bits)
% CONV_ENCODER Sekil 2'deki 1/3 oranli, 3 flip-flop'lu (K = 4, 8 durumlu)
% sistematik olmayan konvolusyonel kodlayiciyi (Convolutional Encoder) gerceklestirir.
%
% Onemli: Bu dosyayi MATLAB'da tam olarak "conv_encoder.m" adiyla kaydedin.
%         MATLAB Communication Toolbox fonksiyonlari KULLANILMAMISTIR.
%
% Sekil 2 Baglanti Polinomlari (Generator Polynomials):
%   Flip-Flop durumlari: s1 = u(n-1), s2 = u(n-2), s3 = u(n-3)
%   Output 1 (ust kol)  : g1 = [1 0 1 1] -> c1(n) = u(n) + u(n-2) + u(n-3) (mod 2)
%   Output 2 (orta kol) : g2 = [1 1 0 1] -> c2(n) = u(n) + u(n-1) + u(n-3) (mod 2)
%   Output 3 (alt kol)  : g3 = [1 1 1 1] -> c3(n) = u(n) + u(n-1) + u(n-2) + u(n-3) (mod 2)
%
% Giris:
%   msg_bits      : Giris ikili mesaj bit dizisi (1xN veya Nx1 vektor, 0 ve 1)
%
% Cikislar:
%   coded_bits    : 1/3 oraninda kodlanmis bit dizisi (1 x 3N satir vektoru)
%   state_history : Her adimdaki flip-flop durumu (0..7 arasinda tam sayi)

    msg_bits = double(msg_bits(:)' > 0); % Satir vektoru (0 ve 1)
    N = length(msg_bits);
    
    % Kaydirmali kaydedici (Shift Register) gecikmeli bit dizileri
    % Baslangic durumu tum flip-floplarda 000 kabul edilir.
    u0 = msg_bits;                        % u(n)   - giris biti
    u1 = [0, msg_bits(1:end-1)];          % u(n-1) - 1. Flip-Flop cikisi
    u2 = [0, 0, msg_bits(1:end-2)];       % u(n-2) - 2. Flip-Flop cikisi
    u3 = [0, 0, 0, msg_bits(1:end-3)];    % u(n-3) - 3. Flip-Flop cikisi
    
    % Modulo-2 toplayicilar (XOR islemi: mod(a+b, 2))
    c1 = mod(u0 + u2 + u3, 2);            % Output 1: g1 = [1 0 1 1]
    c2 = mod(u0 + u1 + u3, 2);            % Output 2: g2 = [1 1 0 1]
    c3 = mod(u0 + u1 + u2 + u3, 2);       % Output 3: g3 = [1 1 1 1]
    
    % Cikis bitlerini [c1(1) c2(1) c3(1) c1(2) c2(2) c3(2) ...] sirasiyla diz
    coded_matrix = [c1; c2; c3];          % (3 x N)
    coded_bits = reshape(coded_matrix, 1, 3 * N);
    
    % Istege bagli durum gecmisi: s = 4*s1 + 2*s2 + s3 (0..7)
    if nargout > 1
        s1_after = u0;
        s2_after = u1;
        s3_after = u2;
        state_history = 4 * s1_after + 2 * s2_after + s3_after;
    end
end
