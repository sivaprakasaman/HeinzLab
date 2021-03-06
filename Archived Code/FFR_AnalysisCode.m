%Analysis code for FFR chinchilla recordings
%Last Updated: 6/2019, Andrew Sivaprakasam

close all;
clear all;

%% Load Data
subject = "Q379";
folder = strcat("MH-2019_06_07-",subject,"_FFRpilot");
cd(folder);

run('a0002_FFR_SNRenvSAM_atn25.m');
SAM_data = ans;
clear ans;
run('a0003_FFR_SNRenvsq_25_atn25.m');
sq_25_data = ans;
clear ans;
run('a0004_FFR_SNRenvsq_50_atn25.m');
sq_50_data = ans;
clear ans;

%% Convert Data

%SAM 
SAM_NP = cell2mat(SAM_data.AD_Data.AD_Avg_NP_V);
SAM_NP = SAM_NP-mean(SAM_NP);
SAM_PO = cell2mat(SAM_data.AD_Data.AD_Avg_PO_V);
SAM_PO = SAM_PO-mean(SAM_PO);
SAM_envresponse = (SAM_NP+SAM_PO)/SAM_data.AD_Data.Gain;

%Sq50
sq50_NP = cell2mat(sq_50_data.AD_Data.AD_Avg_NP_V);
sq50_NP = sq50_NP-mean(sq50_NP);
sq50_PO = cell2mat(sq_50_data.AD_Data.AD_Avg_PO_V);
sq50_PO = sq50_PO-mean(sq50_PO);
sq50_envresponse = (sq50_NP+sq50_PO)/sq_50_data.AD_Data.Gain;

%Sq25
sq25_NP = cell2mat(sq_25_data.AD_Data.AD_Avg_NP_V);
sq25_NP = sq25_NP-mean(sq25_NP);
sq25_PO = cell2mat(sq_25_data.AD_Data.AD_Avg_PO_V);
sq25_PO = sq25_PO-mean(sq25_PO);
sq25_envresponse = (sq25_NP+sq25_PO)/sq_25_data.AD_Data.Gain;

%% Begin Analysis
Fs = 48828;
toUV = 1e6; %needed to get amplitude in right units

%SAM:
mag_SAM_envresponse = fft(SAM_envresponse*toUV);
T = 1/Fs; %Sampling Period
L = length(SAM_envresponse);
P2 = abs(mag_SAM_envresponse/L);
P1_SAM = P2(1:L/2+1); 

f = Fs*(0:(L/2))/L;

%sq_50
mag_sq50_envresponse = fft(sq50_envresponse*toUV);
T = 1/Fs; %Sampling Period
L = length(sq50_envresponse);
P2 = abs(mag_sq50_envresponse/L);
P1_sq50 = P2(1:L/2+1); 

%sq_25
mag_sq25_envresponse = fft(sq25_envresponse*toUV);
T = 1/Fs; %Sampling Period
L = length(sq25_envresponse);
P2 = abs(mag_sq25_envresponse/L);
P1_sq25 = P2(1:L/2+1); 

fig1 = figure;
plot(f,P1_SAM,f,P1_sq50,f,P1_sq25);
ylim([0,1]);
ylabel("Amplitude (uV?)");
xlim([0,2000]);
xlabel("Frequency (Hz)");
legend("SAM","sq50","sq25");
title("EFR Magnitudes")

%% Same analysis but truncating first 0.1s and last 0.5s
window = [0.1,1.3];

SAM_trunc = SAM_envresponse(window(1)*Fs:window(2)*Fs);
sq50_trunc = sq50_envresponse(window(1)*Fs:window(2)*Fs);
sq25_trunc = sq25_envresponse(window(1)*Fs:window(2)*Fs);

mag_SAM_envresponse = fft(SAM_trunc*toUV);
T = 1/Fs; %Sampling Period
L = length(SAM_trunc);
P2 = abs(mag_SAM_envresponse/L);
P1_SAM = P2(1:L/2+1); 

f = Fs*(0:(L/2))/L;

mag_sq50_envresponse = fft(sq50_trunc*toUV);
T = 1/Fs; %Sampling Period
L = length(sq50_trunc);
P2 = abs(mag_sq50_envresponse/L);
P1_sq50 = P2(1:L/2+1); 


mag_sq25_envresponse = fft(sq25_trunc*toUV);
T = 1/Fs; %Sampling Period
L = length(sq25_trunc);
P2 = abs(mag_sq25_envresponse/L);
P1_sq25 = P2(1:L/2+1); 

fig2 = figure;
plot(f,P1_SAM,f,P1_sq50,f,P1_sq25)
xlim([0,2000]);
ylim([0,1]);

ylabel("Amplitude (uV?)");

xlabel("Frequency (Hz)");
legend("SAM","sq50","sq25");
title("EFR Magnitudes with truncated window")

%% Noise Floor Removal
%SAM trials
% w_n = rand([length(SAM)
% w_m = 

%% Peak detection
figure;

subplot(2,1,1);
hold on;
findpeaks(P1_SAM,f,'MinPeakHeight',0.015,'MinPeakDistance',80)
findpeaks(P1_sq50,f,'MinPeakHeight',0.015,'MinPeakDistance',80)
findpeaks(P1_sq25,f,'MinPeakHeight',0.015,'MinPeakDistance',80)
xlim([0,2000]);
ylim([0,1]);
xlim([0,2000]);
ylim([0,1]);

ylabel("Amplitude (uV)");
xlabel("Frequency (Hz)");
legend("SAM","SAM Pks","sq50","sq50 pks","sq25","sq25 pks");
title("EFR Magnitudes with truncated window")

hold off;
%% EFR Summation
[SAM_PKS, SAM_LOCS] = findpeaks(P1_SAM,f,'MinPeakHeight',0.015,'MinPeakDistance',80);
[sq50_PKS, sq50_LOCS] = findpeaks(P1_sq50,f,'MinPeakHeight',0.015,'MinPeakDistance',80);
[sq25_PKS, sq25_LOCS] = findpeaks(P1_sq25,f,'MinPeakHeight',0.015,'MinPeakDistance',80);

SAM_PKS = SAM_PKS.*(SAM_LOCS>99);
sq50_PKS = sq50_PKS.*(sq50_LOCS>99);
sq25_PKS = sq25_PKS.*(sq25_LOCS>99);

SAM_SUM = cumsum(SAM_PKS);
sq50_SUM = cumsum(sq50_PKS);
sq25_SUM = cumsum(sq25_PKS);

subplot(2,1,2)
plot(SAM_LOCS,SAM_SUM,sq50_LOCS,sq50_SUM,sq25_LOCS,sq25_SUM);
legend('SAM','SQ50','SQ25');
xlabel('Frequency')
ylabel('Cummulative Sum of Harmonic Magnitudes')
xlim([0,2000]);

%% for fun
player = audioplayer([SAM_NP,SAM_NP],Fs);
player.play();
