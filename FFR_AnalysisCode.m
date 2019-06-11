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
SAM_PO = cell2mat(SAM_data.AD_Data.AD_Avg_PO_V);
SAM_envresponse = SAM_NP+SAM_PO;

%Sq50
sq50_NP = cell2mat(sq_50_data.AD_Data.AD_Avg_NP_V);
sq50_PO = cell2mat(sq_50_data.AD_Data.AD_Avg_PO_V);
sq50_envresponse = sq50_NP+sq50_PO;

%Sq25
sq25_NP = cell2mat(sq_25_data.AD_Data.AD_Avg_NP_V);
sq25_PO = cell2mat(sq_25_data.AD_Data.AD_Avg_PO_V);
sq25_envresponse = sq25_NP+sq25_PO;

%% Begin Analysis
Fs = 48828;

%SAM:
mag_SAM_envresponse = fft(SAM_envresponse);
T = 1/Fs; %Sampling Period
L = length(SAM_envresponse);
P2 = abs(mag_SAM_NP/L);
P1 = P2(1:L/2+1); 

f = Fs*(0:(L/2))/L;

plot(f,P1);
ylim([0,0.01]);






%% for fun
player = audioplayer([SAM_NP,SAM_NP],Fs);
player.play();
