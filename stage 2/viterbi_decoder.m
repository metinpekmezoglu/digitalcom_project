function [decoded_bits, min_final_metric] = viterbi_decoder(rx_coded_bits)
% VITERBI_DECODER Sekil 2'deki 1/3 oranli (g1=[1 0 1 1], g2=[1 1 0 1], g3=[1 1 1 1])
% konvolusyonel kod icin Trellis diyagrami uzerinde Minimum Hamming Mesafesi
% (Maximum Likelihood) tabanli Viterbi cozucu algoritmasini calistirir.
%
% Onemli: Bu dosyayi MATLAB'da tam olarak "viterbi_decoder.m" adiyla kaydedin.
%         MATLAB Communication Toolbox fonksiyonlari KULLANILMAMISTIR.
%
% Giris:
%   rx_coded_bits    : Kanaldan/demodulatorden alinan kodlanmis bit dizisi (1 x 3N)
%
% Cikislar:
%   decoded_bits     : Cozulmus (hata duzeltilmis) mesaj bit dizisi (1 x N)
%   min_final_metric : En iyi yolun toplam Hamming hata metrigi

    rx_coded_bits = double(rx_coded_bits(:)' > 0);
    N = floor(length(rx_coded_bits) / 3);
    rx_mat = reshape(rx_coded_bits(1 : 3*N), 3, N)'; % (N x 3) her satir [r1 r2 r3]
    
    % ---------------------------------------------------------------------
    % 1. TRELLIS YAPISININ ON-HESABI (8 Durum: 000..111 -> Indis 1..8)
    % ---------------------------------------------------------------------
    % Durum tanimi: s = 4*s1 + 2*s2 + s3 (s = 0..7, MATLAB indisi = s+1)
    % Yeni bit u (0 veya 1) geldiginde yeni durum:
    %   ns = 4*u + 2*s1 + s2
    % Dolayisiyla bir hedef duruma (ns = 0..7) ulasan giris biti u = floor(ns / 4)
    % olup, o hedef duruma sadece 2 onceki durumdan (p0 ve p1) gelinebilir:
    %   p0 = 2 * mod(ns, 4) + 0   (s3 = 0 olan onceki durum)
    %   p1 = 2 * mod(ns, 4) + 1   (s3 = 1 olan onceki durum)
    
    p0_idx = zeros(8, 1); % MATLAB 1..8 indisleri
    p1_idx = zeros(8, 1);
    out_p0 = zeros(8, 3); % p0 -> ns gecisinin 3-bitlik beklenen cikisi
    out_p1 = zeros(8, 3); % p1 -> ns gecisinin 3-bitlik beklenen cikisi
    
    for ns = 0:7
        u = floor(ns / 4);          % Hedef duruma gecisi saglayan giris biti (0 veya 1)
        p0 = 2 * mod(ns, 4);        % 1. aday onceki durum (0..7)
        p1 = 2 * mod(ns, 4) + 1;    % 2. aday onceki durum (0..7)
        
        p0_idx(ns + 1) = p0 + 1;
        p1_idx(ns + 1) = p1 + 1;
        
        % p0 durumu icin flip-flop bitleri (s1, s2, s3) ve cikis [c1 c2 c3]
        s1_0 = floor(p0 / 4);
        s2_0 = mod(floor(p0 / 2), 2);
        s3_0 = mod(p0, 2);
        out_p0(ns + 1, :) = [mod(u + s2_0 + s3_0, 2), ...
                             mod(u + s1_0 + s3_0, 2), ...
                             mod(u + s1_0 + s2_0 + s3_0, 2)];
                         
        % p1 durumu icin flip-flop bitleri (s1, s2, s3) ve cikis [c1 c2 c3]
        s1_1 = floor(p1 / 4);
        s2_1 = mod(floor(p1 / 2), 2);
        s3_1 = mod(p1, 2);
        out_p1(ns + 1, :) = [mod(u + s2_1 + s3_1, 2), ...
                             mod(u + s1_1 + s3_1, 2), ...
                             mod(u + s1_1 + s2_1 + s3_1, 2)];
    end
    
    % Olasi 8 farkli 3-bitlik alinan grup (000..111 -> r_pat = 1..8) icin
    % Dal Metrigi (Branch Metric / Hamming Mesafesi) Arama Tablosu (8 x 8)
    BM0_TABLE = zeros(8, 8);
    BM1_TABLE = zeros(8, 8);
    for r_val = 0:7
        r_vec = [floor(r_val / 4), mod(floor(r_val / 2), 2), mod(r_val, 2)];
        for ns_i = 1:8
            BM0_TABLE(ns_i, r_val + 1) = sum(out_p0(ns_i, :) ~= r_vec);
            BM1_TABLE(ns_i, r_val + 1) = sum(out_p1(ns_i, :) ~= r_vec);
        end
    end
    
    % Alinan her 3-bitlik grubu 1..8 arasinda tablo indisine cevir
    rx_pat_idx = rx_mat(:,1)*4 + rx_mat(:,2)*2 + rx_mat(:,3) + 1;
    
    % ---------------------------------------------------------------------
    % 2. ILERI YONLU TRELLIS TARAMASI (ADD - COMPARE - SELECT / ACS)
    % ---------------------------------------------------------------------
    INF_VAL = 1e9;
    path_metric = INF_VAL * ones(8, 1);
    path_metric(1) = 0; % Baslangicta kodlayici Durum 0 (000 -> indis 1)'dadir
    
    survivor_prev = zeros(8, N, 'uint8'); % Hayatta kalan yollarin onceki durumlari
    new_pm = zeros(8, 1);
    
    for n = 1:N
        r_col = rx_pat_idx(n);
        for ns_i = 1:8
            cand0 = path_metric(p0_idx(ns_i)) + BM0_TABLE(ns_i, r_col);
            cand1 = path_metric(p1_idx(ns_i)) + BM1_TABLE(ns_i, r_col);
            
            if cand1 < cand0
                new_pm(ns_i) = cand1;
                survivor_prev(ns_i, n) = p1_idx(ns_i);
            else
                new_pm(ns_i) = cand0;
                survivor_prev(ns_i, n) = p0_idx(ns_i);
            end
        end
        path_metric = new_pm;
    end
    
    % ---------------------------------------------------------------------
    % 3. GERIYE DOGRU IZ SURME (TRACEBACK)
    % ---------------------------------------------------------------------
    [min_final_metric, best_state] = min(path_metric);
    decoded_bits = zeros(1, N);
    
    curr_s = best_state; % 1..8 arasinda durum indisi
    for n = N:-1:1
        % Durum indisi 1..4 (000..011) ise giris biti u=0; 5..8 (100..111) ise u=1
        if curr_s >= 5
            decoded_bits(n) = 1;
        else
            decoded_bits(n) = 0;
        end
        curr_s = double(survivor_prev(curr_s, n));
    end
end
