% rxsite.xlsx에서 데이터 읽기
data = readmatrix('rxsite.xlsx'); 
latitudes = data(:,1);  % A열 (위도)
longitudes = data(:,2); % B열 (경도)

% Site Viewer 설정
viewer = siteviewer(Buildings="toterminal.osm");

% 송신기 위치 설정
tx = [
    txsite("Latitude", 36.6311, "Longitude", 127.4326, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.6305, "Longitude", 127.4407, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.631573, "Longitude", 127.451441, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.6316, "Longitude", 127.46, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.6254, "Longitude", 127.432, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.6249, "Longitude", 127.4396, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.6249, "Longitude", 127.4501, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.624058, "Longitude", 127.459011, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.6173, "Longitude", 127.4319, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.617092, "Longitude", 127.439509, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.617, "Longitude", 127.4476, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.61661, "Longitude", 127.457781, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.6293291, "Longitude", 127.4441254, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.634563, "Longitude", 127.4583406, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
    txsite("Latitude", 36.6310529, "Longitude", 127.4325968, "TransmitterFrequency", 5.9e9, "TransmitterPower", 23);
];

% 송신기 시각화
for i = 1:length(tx)
end

%    show(tx(i));

% 수신기 생성 및 시각화
rx = rxsite.empty;
for i = 1:length(latitudes)
    rx(i) = rxsite(Latitude=latitudes(i), Longitude=longitudes(i));
end

%    show(rx(i));

% 전파 모델 설정 (Ray Tracing - SBR)
propModel = propagationModel("raytracing", ...
    "Method", "sbr", ...
    "MaxNumReflections", 6, ...
    "MaxNumDiffractions", 0);

% 고정 파라미터
Pt = 23;    % 송신 전력 [dBm]
Gt = 7.6;   % 송신 안테나 이득 [dBi]
Gr = 5.5;   % 수신 안테나 이득 [dBi]
Lf = 10;    % 페이딩 손실 [dB]
Lm = 3;     % 기타 손실 [dB]

% 수신기 및 송신기 수
numRx = length(rx);
numTx = length(tx);

% 결과 배열 초기화
rssi_matrix = zeros(numRx, numTx);
maxRssi = zeros(numRx, 1);
bestTxIdx = zeros(numRx, 1);
pathloss = zeros(numRx, 1);
rxLat = zeros(numRx, 1);
rxLon = zeros(numRx, 1);

% 계산 수행
for i = 1:numRx
    rxLat(i) = rx(i).Latitude;
    rxLon(i) = rx(i).Longitude;

    maxRssi(i) = -Inf; % 초기값 설정

    for j = 1:numTx
        ss = sigstrength(rx(i), tx(j), propModel); % RSSI 계산
        rssi_matrix(i,j) = ss;

        % 최대 RSSI 및 Best Tx 인덱스 갱신
        if ss > maxRssi(i)
            maxRssi(i) = ss;
            bestTxIdx(i) = j;
        end
    end

    % Pathloss 계산 (최대 RSSI 기준)
    if maxRssi(i) ~= -Inf
        pathloss(i) = Pt + Gt + Gr - maxRssi(i) - Lf - Lm;
    else
        pathloss(i) = NaN;
    end
end

% 결과 테이블 생성
txLabels = strings(1, numTx);
for j = 1:numTx
    txLabels(j) = sprintf("Tx%d_RSSI", j);
end

T = array2table(rssi_matrix, 'VariableNames', txLabels);
T.RxLatitude = rxLat;
T.RxLongitude = rxLon;
T.MaxRSSI_dBm = maxRssi;
T.BestTxIndex = bestTxIdx;
T.Pathloss_dB = pathloss;

% 열 순서 조정
T = movevars(T, {'RxLatitude', 'RxLongitude'}, 'Before', 'Tx1_RSSI');

% 엑셀로 저장
writetable(T, 'rx_results_with_location.xlsx');
disp("완료: RSSI, Pathloss, 위치 정보가 'rx_results_with_location.xlsx'에 저장되었습니다.");
