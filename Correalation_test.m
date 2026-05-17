clear;
clc;

%% 🔷 Load Data
data = readmatrix('noise_signal.csv');
I1 = data(:,1); Q1 = data(:,2);
I2 = data(:,3); Q2 = data(:,4);

ch1 = complex(I1, Q1);
ch2 = complex(I2, Q2);

%% 🔷 Remove DC Offset
ch1 = ch1 - mean(ch1);
ch2 = ch2 - mean(ch2);

Fs = 1e6; % sampling rate

%% 🔷 PSD Visualization
figure;
subplot(2,1,1);
pwelch(ch1, [], [], [], Fs, 'centered');
title('Channel 1 PSD');

subplot(2,1,2);
pwelch(ch2, [], [], [], Fs, 'centered');
title('Channel 2 PSD');

%% 🔷 Cross-Correlation
[R12, lags] = xcorr(ch1, ch2, 'biased');

figure;
plot(lags, abs(R12));
title('Cross-Correlation CH1 vs CH2');

[max_corr, idx] = max(abs(R12));
best_lag = lags(idx);

disp(['Max correlation: ', num2str(max_corr)]);
disp(['Best lag: ', num2str(best_lag)]);

%% 🔷 IQ Plot
figure;
subplot(1,2,1);
plot(real(ch1), imag(ch1), '.');
title('IQ CH1');

subplot(1,2,2);
plot(real(ch2), imag(ch2), '.');
title('IQ CH2');

%% 🔷 Construct Data Matrix
X = [ch1.'; ch2.']; % 2 x N

N = size(X,2);

%% 🔷 Covariance Matrix
Rxx = (X * X') / N;
disp('Covariance Matrix:');
disp(Rxx);

%% =========================================================
%% 🔷 DOA ESTIMATION USING MUSIC
%% =========================================================

c = 3e8;
fc = 2.4e9;
lambda = c / fc;
d = lambda / 2;

ula = phased.ULA('NumElements', 2, 'ElementSpacing', d);

music_est = phased.MUSICEstimator( ...
    'SensorArray', ula, ...
    'OperatingFrequency', fc, ...
    'NumSignals', 1, ...
    'DOAOutputPort', true);

[~, doa_est] = music_est(X.');

fprintf('Estimated DOA (Azimuth): %.2f degrees\n', doa_est);

%% =========================================================
%% 🔷 STEERING VECTOR + MVDR
%% =========================================================

pos_lambda = getElementPosition(ula) / lambda;
ang = [doa_est; 0];

a_target = steervec(pos_lambda, ang);

w_mvdr = mvdrweights(pos_lambda, ang, Rxx);

Y = w_mvdr' * X;

%% =========================================================
%% 🔷 DIRECTION VECTOR (PHYSICAL INTERPRETATION)
%% =========================================================

theta = deg2rad(doa_est);
phi = deg2rad(0); % ULA → elevation = 0

dir_vec = [sin(theta)*cos(phi);
           cos(theta)*cos(phi);
           sin(phi)];

disp('Direction Vector:');
disp(dir_vec);

%% =========================================================
%% 🔷 MUSIC SPECTRUM
%% =========================================================

[P_music, ~] = music_est(X.');
angles_music = music_est.ScanAngles;

P_music_dB = 10*log10(abs(P_music));
P_music_dB = P_music_dB - max(P_music_dB);

figure;
plot(angles_music, P_music_dB, 'LineWidth', 2);
hold on;
xline(doa_est, '--r', 'LineWidth', 1.5);

title('MUSIC Spectrum');
xlabel('Angle (Degrees)');
ylabel('Normalized Power (dB)');
grid on;

%% =========================================================
%% 🔷 MVDR BEAM PATTERN
%% =========================================================

scan_angles = -90:0.5:90;
beam_pattern = zeros(size(scan_angles));

for i = 1:length(scan_angles)
    a_scan = steervec(pos_lambda, [scan_angles(i); 0]);
    beam_pattern(i) = abs(w_mvdr' * a_scan)^2;
end

beam_pattern_dB = 10*log10(beam_pattern);
beam_pattern_dB = beam_pattern_dB - max(beam_pattern_dB);

figure;
plot(scan_angles, beam_pattern_dB, 'LineWidth', 2);
hold on;
xline(doa_est, '--k', 'LineWidth', 1.5);

title('MVDR Beam Pattern');
xlabel('Angle (Degrees)');
ylabel('Normalized Gain (dB)');
grid on;

%% =========================================================
%% 🔷 POLAR BEAM PATTERN
%% =========================================================

figure;
polarplot(deg2rad(scan_angles), beam_pattern_dB, 'LineWidth', 2);
title('Polar Beam Pattern');
rlim([-40 0]);

%% =========================================================
%% 🔷 3D DIRECTION VISUALIZATION
%% =========================================================

figure;
quiver3(0,0,0, dir_vec(1), dir_vec(2), dir_vec(3), 0, 'LineWidth', 2);
grid on;
axis equal;

xlabel('X');
ylabel('Y');
zlabel('Z');

title(sprintf('Direction (Azimuth = %.2f°, Elevation = 0°)', doa_est));

%% =========================================================
%% 🔷 OUTPUT SIGNAL (VALIDATION)
%% =========================================================

figure;
plot(real(Y(1:min(200,N))), 'LineWidth', 1.5);
title('Beamformed Output (Real Part)');
xlabel('Samples');
ylabel('Amplitude');
grid on;

fprintf('Target is slightly %s of broadside (DOA = %.2f°)\n', ...
    ternary(doa_est < 0, 'RIGHT', ternary(doa_est > 0, 'LEFT', 'STRAIGHT AHEAD')), doa_est);