%% 1. ADIM: GERÇEK VERİ SETİ YÜKLEME VE HAZIRLIK
clc; clear; close all;
fprintf('SİSTEM BAŞLATILIYOR...\n');
fprintf('1. ADIM: Dış Veri Seti Yükleniyor...\n');

% --- A: Dosyayı Oku ---
dosya_adi = 'driver-data.csv'; 

try
    tablo = readtable(dosya_adi);
    fprintf('  > Dosya başarıyla okundu: %s\n', dosya_adi);
    
    % Hata ayıklama için sütun isimlerini ekrana basalım
    fprintf('  > Dosyadaki Sütunlar: %s\n', strjoin(tablo.Properties.VariableNames, ', '));
catch
    error('Dosya bulunamadı! Dosya adını kontrol et veya Matlab klasörüne at.');
end

% --- B: Sütun Seçimi (DÜZELTİLEN KISIM) ---
% driver_data.csv için genellikle 2. ve 3. sütunlar veridir.
secilen_sutunlar = [2, 3]; 

% HIZLANDIRMA YAMASI: Sadece ilk 500 satırı al (Bilgisayar donmasın diye)
try
    Ham_X = table2array(tablo(1:500, secilen_sutunlar));
catch
    error('HATA: Seçilen sütun numaraları dosyada yok. [2, 3] yerine [1, 2] deneyin.');
end

% --- C: Normalizasyon ---
X = (Ham_X - min(Ham_X)) ./ (max(Ham_X) - min(Ham_X));

toplam_veri_sayisi = size(X, 1);
fprintf('  > Kullanılan Sütun İndeksleri: %d ve %d\n', secilen_sutunlar(1), secilen_sutunlar(2));
fprintf('  > Veri Sayısı: %d (Performans için sınırlandırıldı)\n', toplam_veri_sayisi);
fprintf('  > Veri Normalizasyonu: Tamamlandı (0-1 aralığı)\n');

% Görsel Penceresini Hazırla
figure('Name', 'Otonom K-Means (Gerçek Veri)', 'Units', 'normalized', 'OuterPosition', [0.05 0.05 0.9 0.9]);

% --- Veri Dağılımını Görelim ---
subplot(2,2,1); 
plot(X(:,1), X(:,2), 'k.', 'MarkerSize', 10);
title('Sürücü Verileri (Mesafe vs Hız)');
xlabel('Özellik 1 (Mesafe)'); ylabel('Özellik 2 (Hız)');
grid on;


%% 2. ADIM: K SAYISINI BULMA (AJAN 1: K-SCOUT)
% ---------------------------------------------------------
% Amaç: Veri boyutuna göre arama aralığını belirleyip en iyi K'yı bulmak.
% ---------------------------------------------------------
fprintf('\nAJAN 1 DEVREDE: En uygun grup sayısı (K) aranıyor...\n');

% --- A: Dinamik Arama Aralığı (Rule of Thumb) ---
% Veri sayısının kareköküne kadar bak, ama sunum için 12'yi geçme.
hesaplanan_sinir = ceil(sqrt(toplam_veri_sayisi)); 
max_k_limit = min(hesaplanan_sinir, 12); 

fprintf('  > Veri Sayısı: %d\n', toplam_veri_sayisi);
fprintf('  > Otonom Tarama Aralığı: K=1 ile K=%d arası.\n', max_k_limit);

k_range = 1:max_k_limit;
wcss = zeros(1, length(k_range));
sil_scores = zeros(1, length(k_range));

for k = k_range
    % Hızlı tarama için standart K-Means kullan
    [idx, C, sumd] = kmeans(X, k, 'Replicates', 3, 'Display', 'off');
    wcss(k) = sum(sumd);
    
    if k > 1
        s = silhouette(X, idx);
        sil_scores(k) = mean(s);
    else
        sil_scores(k) = 0;
    end
end

% --- B: Geometrik Dirsek (Elbow) Hesabı ---
firstPt = [k_range(1), wcss(1)];
lastPt = [k_range(end), wcss(end)];
max_dist = 0;
elbow_k = 1;
for i = 1:length(k_range)
    currentPt = [k_range(i), wcss(i)];
    dist = abs(det([lastPt-firstPt; currentPt-firstPt])) / norm(lastPt-firstPt);
    if dist > max_dist
        max_dist = dist;
        elbow_k = k_range(i);
    end
end

% --- C: Karar Mekanizması ---
[max_sil, sil_k] = max(sil_scores);
SECILEN_K = sil_k; % Güvenilirlik için Silhouette seçiyoruz

fprintf('  > Geometrik Dirsek Analizi Sonucu: K=%d\n', elbow_k);
fprintf('  > Silhouette Analizi Sonucu:       K=%d (Skor: %.2f)\n', sil_k, max_sil);
fprintf('  > SİSTEM KARARI: K=%d olarak sabitlendi.\n', SECILEN_K);

% --- Grafik 1: K Seçimi ---
subplot(2, 2, 1);
yyaxis left; plot(k_range, wcss, '-ob', 'LineWidth', 2); ylabel('WCSS (Hata)');
yyaxis right; plot(k_range, sil_scores, '-or', 'LineWidth', 2); ylabel('Silhouette (Kalite)');
xline(SECILEN_K, '--k', ['Seçilen K=' num2str(SECILEN_K)], 'LineWidth', 2, 'LabelVerticalAlignment', 'bottom');
title(['AJAN 1: K Değeri Analizi (K=' num2str(SECILEN_K) ')'], 'FontSize', 12); 
xlabel('Küme Sayısı'); grid on;

%% 3. ADIM: METRİK SEÇİMİ (AJAN 2: METRIC-SCOUT)
% ---------------------------------------------------------
% Amaç: Bulunan K değeri ile Öklid, Manhattan ve Minkowski'yi yarıştırmak.
% ---------------------------------------------------------
fprintf('\nAJAN 2 DEVREDE: En uygun mesafe formülü test ediliyor...\n');

adaylar = {'oklit', 'manhattan', 'minkowski'};
en_iyi_skor = -2;
SECILEN_METRIK = '';
skorlar_bar = zeros(1, 3);

for m = 1:length(adaylar)
    metrik = adaylar{m};
    
    % Test için manuel döngü (Tek iterasyon yeterli)
    Merkezler_Test = X(randperm(size(X,1), SECILEN_K), :);
    Uzakliklar = zeros(size(X,1), SECILEN_K);
    
    for k = 1:SECILEN_K
        fark = X - Merkezler_Test(k, :);
        if strcmp(metrik, 'oklit')
            Uzakliklar(:, k) = sqrt(sum(fark.^2, 2));
        elseif strcmp(metrik, 'manhattan')
            Uzakliklar(:, k) = sum(abs(fark), 2);
        elseif strcmp(metrik, 'minkowski')
            Uzakliklar(:, k) = sum(abs(fark).^3, 2).^(1/3); % p=3
        end
    end
    [~, atama] = min(Uzakliklar, [], 2);
    
    % Puanlama (Silhouette)
    try
        ss = silhouette(X, atama);
        skor = mean(ss);
    catch
        skor = 0; 
    end
    
    skorlar_bar(m) = skor;
    fprintf('  > Test Ediliyor: %-10s -> Skor: %.4f\n', metrik, skor);
    
    if skor > en_iyi_skor
        en_iyi_skor = skor;
        SECILEN_METRIK = metrik;
    end
end

fprintf('  > SİSTEM KARARI: En iyi metrik >> %s << seçildi.\n', upper(SECILEN_METRIK));

% --- Grafik 2: Metrik Yarışı ---
subplot(2, 2, 2);
b = bar(skorlar_bar, 'FaceColor', [0.2 0.6 0.5]);
set(gca, 'XTickLabel', adaylar);
text(1:length(skorlar_bar), skorlar_bar, num2str(skorlar_bar', '%.2f'), ...
    'vert', 'bottom', 'horiz', 'center'); 
title(['AJAN 2: Metrik Seçimi (Kazanan: ' upper(SECILEN_METRIK) ')'], 'FontSize', 12);
grid on;

%% 4. ADIM: FİNAL CANLI SİMÜLASYON
% ---------------------------------------------------------
% Amaç: Seçilen K ve Metrik ile kümeleme sürecini izletmek.
% ---------------------------------------------------------
fprintf('\nBAŞLATILIYOR: %s kullanılarak K=%d ile kümeleme işlemi...\n', upper(SECILEN_METRIK), SECILEN_K);

subplot(2, 2, [3, 4]); % Alt kısmı kapla

% Merkezleri Başlat
Merkezler = X(randperm(size(X,1), SECILEN_K), :);
renkler = lines(SECILEN_K);

max_iter = 15;
for iter = 1:max_iter
    
    % --- A: Mesafe Hesabı (Seçilen Metrik ile) ---
    Uzakliklar = zeros(size(X,1), SECILEN_K);
    for k = 1:SECILEN_K
        fark = X - Merkezler(k, :);
        if strcmp(SECILEN_METRIK, 'oklit')
            Uzakliklar(:, k) = sqrt(sum(fark.^2, 2));
        elseif strcmp(SECILEN_METRIK, 'manhattan')
            Uzakliklar(:, k) = sum(abs(fark), 2);
        elseif strcmp(SECILEN_METRIK, 'minkowski')
            Uzakliklar(:, k) = sum(abs(fark).^3, 2).^(1/3);
        end
    end
    [~, idx] = min(Uzakliklar, [], 2);
    
    % --- B: Görselleştirme (Canlı) ---
    cla;
    gscatter(X(:,1), X(:,2), idx, renkler);
    hold on;
    % Merkezleri Çiz
    plot(Merkezler(:,1), Merkezler(:,2), 'ko', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'y'); % Sarı Daire
    plot(Merkezler(:,1), Merkezler(:,2), 'kx', 'MarkerSize', 12, 'LineWidth', 2); % Siyah Çarpı
    
    title(sprintf('CANLI SİMÜLASYON: İterasyon %d (Yöntem: %s)', iter, upper(SECILEN_METRIK)), 'FontSize', 14);
    legend('off'); grid on;
    drawnow; 
    pause(0.7); % Sunum hızı
    
    % --- C: Merkez Güncelleme ---
    Eski_Merkezler = Merkezler;
    for k = 1:SECILEN_K
        if sum(idx == k) > 0
            Merkezler(k, :) = mean(X(idx == k, :), 1);
        end
    end
    
    % Durma Kontrolü
    if isequal(Eski_Merkezler, Merkezler)
        title(sprintf('ANALİZ TAMAMLANDI! (K=%d, %s, %d Adımda Yakınsadı)', SECILEN_K, upper(SECILEN_METRIK), iter), 'FontSize', 14, 'Color', 'b');
        break;
    end
end

fprintf('\n>>> SİSTEM BAŞARIYLA TAMAMLANDI. <<<\n');
msgbox('Otonom Kümeleme Analizi Tamamlandı.', 'İşlem Bitti');

%% 5. ADIM: SONUÇLARIN LİSTELENMESİ VE RAPORLAMA
% ---------------------------------------------------------
% Amaç: Hangi verinin hangi kümeye atandığını tablo haline getirmek.
% ---------------------------------------------------------
fprintf('\n------------------------------------------------\n');
fprintf('RAPORLAMA: Veriler ve Atandıkları Kümeler Listeleniyor...\n');

% 1. Verileri ve Sonuçları Birleştirme
% X: Veri noktaları, idx: Atandığı Küme No
Sonuc_Tablosu = array2table(X, 'VariableNames', {'Ozellik_1', 'Ozellik_2'});
Sonuc_Tablosu.Atanan_Kume = idx; % Yeni sütun olarak ekle

% 2. Ekrana İlk 10 Satırı Yazdıralım (Önizleme)
fprintf('>> İlk 10 Verinin Durumu:\n');
disp(head(Sonuc_Tablosu, 10));

% 3. İstatistiksel Özet (Hangi kümede kaç kişi var?)
fprintf('>> Küme Dağılım İstatistiği:\n');
tabulate(idx); % Yüzdelik ve sayısal dağılımı otomatik döker

% 4. (Opsiyonel) Excel'e Kaydetme
% Eğer hoca "Sonuçları bana dosya olarak ver" derse:
try
    writetable(Sonuc_Tablosu, 'KMeans_Sonuclari.xlsx');
    fprintf('>> BAŞARILI: Tüm liste "KMeans_Sonuclari.xlsx" olarak kaydedildi.\n');
catch
    fprintf('>> UYARI: Excel dosyası kaydedilemedi (Matlab Online kullanıyorsan olabilir).\n');
end

% 5. Tabloyu Matlab içinde açarak gösterme
open('Sonuc_Tablosu');