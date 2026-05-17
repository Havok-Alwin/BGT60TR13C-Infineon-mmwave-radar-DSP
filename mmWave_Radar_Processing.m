clc; clear;

%% PARAMETERS
c = 3e8;
fc = 60e9;
lambda = c/fc;
d = lambda/2;

Fs = 2e6;
numRx = 3;
numFrames = 100;
numChirps = 128;
numSamples = 64;

B = 2e9;
Tchirp = 0.0005;
slope = B/Tchirp;

%% LOAD DATA
S = load('angle_allwin1.mat');
fields = fieldnames(S);
rawData = S.(fields{1});

disp(size(rawData)); % should be [3, frames, chirps, samples]

%% ---------------- FRAME SELECTION ----------------
frameIdx = 1;  % you can loop later

data = squeeze(rawData(:, frameIdx, :, :));
% size: [3 × chirps × samples]

%% ---------------- RX SEPARATION ----------------
rx1 = squeeze(data(1,:,:)); % [chirps × samples]
rx2 = squeeze(data(2,:,:));
rx3 = squeeze(data(3,:,:));

%% ---------------- COMPLEX SIGNAL ----------------
rx1 = hilbert(double(rx1.')).'; % ensure along samples
rx2 = hilbert(double(rx2.')).';
rx3 = hilbert(double(rx3.')).';

%% ---------------- RANGE FFT ----------------
Nfft_r = 128;

R1 = fft(rx1, Nfft_r, 2); % along samples
R2 = fft(rx2, Nfft_r, 2);
R3 = fft(rx3, Nfft_r, 2);

R1 = R1(:,1:Nfft_r/2);
R2 = R2(:,1:Nfft_r/2);
R3 = R3(:,1:Nfft_r/2);

%% ---------------- DOPPLER FFT ----------------
Nfft_d = 128;

D1 = fftshift(fft(R1, Nfft_d, 1),1);
D2 = fftshift(fft(R2, Nfft_d, 1),1);
D3 = fftshift(fft(R3, Nfft_d, 1),1);

%% ---------------- AXES ----------------
fb = (0:Nfft_r/2-1)*(Fs/Nfft_r);
range_axis = (c*fb)/(2*slope);

fd = (-Nfft_d/2:Nfft_d/2-1)/(numChirps*Tchirp);
velocity_axis = (lambda/2)*fd;

%% ---------------- RANGE-DOPPLER ----------------
RD = abs(D1 + D2 + D3);

%% ---------------- TARGET DETECTION ----------------
[~, idx] = max(RD(:));
[d_idx, r_idx] = ind2sub(size(RD), idx);

target_range = range_axis(r_idx);
target_velocity = velocity_axis(d_idx);

%% ===============================
%% 🎯 MUSIC DOA (CORRECT SNAPSHOT)
%% ===============================

% Snapshot across antennas (IMPORTANT FIX)
X = [
    D1(d_idx, r_idx);
    D2(d_idx, r_idx);
    D3(d_idx, r_idx)
];

% Covariance
Rxx = (X * X');

% MUSIC
music = phased.MUSICEstimator( ...
    'SensorArray', phased.ULA(3,d), ...
    'OperatingFrequency', fc, ...
    'NumSignalsSource','Property', ...
    'NumSignals',1, ...
    'ScanAngles', -90:0.5:90);

Pmusic = music(Rxx);                                              
angles = music.ScanAngles;       

[~, max_idx] = max(Pmusic);
doa_angle = angles(max_idx);

%% DISPLAY
fprintf('\n===== FINAL RESULT =====\n');
fprintf('Range    : %.2f m\n', target_range);
fprintf('Velocity : %.2f m/s\n', target_velocity);
fprintf('DOA      : %.2f deg\n', doa_angle);

%% ===============================
%% 📊 REQUIRED PLOTS
%% ===============================

% 1️⃣ RANGE-DOPPLER
figure;
imagesc(velocity_axis, range_axis, 20*log10(RD.'/max(RD(:))));
xlabel('Velocity (m/s)');
ylabel('Range (m)');
title('Range-Doppler Map');
axis xy; colorbar;

% 2️⃣ RANGE PROFILE
figure;
plot(range_axis, 20*log10(mean(abs(R1),1)));
xlabel('Range (m)');
ylabel('Magnitude (dB)');
title('Range Profile');
grid on;

% 3️⃣ MUSIC SPECTRUM
figure;
plot(angles, 10*log10(Pmusic/max(Pmusic)));
xlabel('Angle (deg)');
ylabel('Spectrum (dB)');
title('MUSIC DOA');
grid on;