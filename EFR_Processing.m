%Take FFRs, process them, and calculate the cummulative sum of Harmonic
%Magnitudes. Should be generalized enough to run with any trial.
%Last Updated: Andrew Sivaprakasam, 6/2019

clear all;
close all;

%% Parameters:

chins = 5; %simulated number of "chins"
%trials = 50;
t_array = [10,30,50,100,150,200];%number of trials conducted/condition/chin

Fs0 = round(48828.125);%sampling rate in
Fs = 4e3; %resample to

iterations = 100;
window = [0.1,1.3];
gain = 20e3; %make this parametric at some point

K_MRS = 100;
K_NF = 10;
I_NF = 100;

harmonics = 6;
%% Load Files:
subject = "Q379";

folder = strcat("MH-2019_06_07-",subject,"_FFRpilot");
cd(folder);

SAM_data = load('p0002_FFR_SNRenvSAM_atn25.mat');
sq_25_data = load('p0003_FFR_SNRenvsq_25_atn25.mat');
sq_50_data =load('p0004_FFR_SNRenvsq_50_atn25.mat');

SAM_tot_full = SAM_data.data.AD_Data.AD_All_V;

sq25_tot_full = sq_25_data.data.AD_Data.AD_All_V;

sq50_tot_full = sq_50_data.data.AD_Data.AD_All_V;

cd ../

fprintf('Files Loaded \n')

%% Select random dataset of certain number

for ta = 1:length(t_array)
    trials = t_array(ta);
    for c = 1:chins
        
        x = 1:length(SAM_tot_full);
        odv = x(rem(x,2)==1);
        evv = x(rem(x,2)==0);
        SAM_r_odds = odv(randi(length(odv),1,trials))';
        SAM_r_evens = evv(randi(length(evv),1,trials))';
        
        %Account for different number of collected trials
        x = 1:length(sq25_tot_full);
        odv = x(rem(x,2)==1);
        evv = x(rem(x,2)==0);
        r_odds = odv(randi(length(odv),2,trials))';
        r_evens = evv(randi(length(evv),2,trials))';
        
        
        for t = 1:2:trials
            
            %pos
            SAM_tot{t} = SAM_tot_full{SAM_r_odds(t,1)};
            sq25_tot{t} = sq25_tot_full{r_odds(t,1)};
            sq50_tot{t} = sq50_tot_full{r_odds(t,2)};
            
            %neg
            SAM_tot{t+1} = SAM_tot_full{SAM_r_evens(t,1)};
            sq25_tot{t+1} = sq25_tot_full{r_evens(t,1)};
            sq50_tot{t+1} = sq50_tot_full{r_evens(t,2)};
            
        end
        
        %% Calculate the DFT for Responses
        
        [SAM_f,SAM_DFT] = getDFT(SAM_tot,trials,window,Fs,Fs0,gain,K_MRS,K_NF,I_NF);
        [sq25_f,sq25_DFT] = getDFT(sq25_tot,trials,window,Fs,Fs0,gain,K_MRS,K_NF,I_NF);
        [sq50_f,sq50_DFT] = getDFT(sq50_tot,trials,window,Fs,Fs0,gain,K_MRS,K_NF,I_NF);
        
        %% Plotting
        
        % figure;
        % subplot(2,1,1)
        % hold on;
        % plot(SAM_f,SAM_DFT)
        % plot(sq25_f,sq25_DFT)
        % plot(sq50_f,sq50_DFT,'g')
        % title('DFT with Noise Floor removed')
        % ylabel('SNR (dB)/Magnitude (dB, arbitrary)')
        % xlabel('Frequency')
        % xlim([0,2e3])
        % ylim([0,max(SAM_DFT)+5])
        
        %Get peaks and sum them, look at crossings
        
        [SAM_SUM,SAM_PKS,SAM_LOCS] = getSum(SAM_f,SAM_DFT,harmonics);
        [SQ25_SUM,SQ25_PKS,SQ25_LOCS] = getSum(sq25_f,sq25_DFT,harmonics);
        [SQ50_SUM,SQ50_PKS,SQ50_LOCS] = getSum(sq50_f,sq50_DFT,harmonics);
        
        SAM_MAG_SUM(c)= SAM_SUM(end);
        SQ25_MAG_SUM(c)= SQ25_SUM(end);
        SQ50_MAG_SUM(c)= SQ50_SUM(end);
        
    end
    
    SAM_MAG_MEAN(ta) = mean(SAM_MAG_SUM);
    SQ25_MAG_MEAN(ta) = mean(SQ25_MAG_SUM);
    SQ50_MAG_MEAN(ta) = mean(SQ50_MAG_SUM);
    
    SAM_MAG_std(ta) = std(SAM_MAG_SUM);
    SQ25_MAG_std(ta) = std(SQ25_MAG_SUM);
    SQ50_MAG_std(ta) = std(SQ50_MAG_SUM);
    
end

%SAM:

SAM_all_means = [t_array',SAM_MAG_MEAN',SAM_MAG_std'];
SQ25_all_means = [t_array',SQ25_MAG_MEAN',SQ25_MAG_std'];
SQ50_all_means = [t_array',SQ50_MAG_MEAN',SQ50_MAG_std'];


save('SAM_all_m.mat','SAM_all_means')
save('SQ25_all_m.mat','SQ25_all_means')
save('SQ50_all_m.mat','SQ50_all_means')

% plot(SAM_LOCS,SAM_PKS,'bo',SQ25_LOCS,SQ25_PKS,'ro',SQ50_LOCS,SQ50_PKS,'go')

% legend('SAM','SQ25','SQ50','SAM','SQ25','SQ50')
%
% hold off;
%
% subplot(2,1,2)
% plot(SAM_LOCS,SAM_SUM,SQ25_LOCS,SQ25_SUM,SQ50_LOCS,SQ50_SUM,'g')
% xlabel('Frequency')
% ylabel('Cummulative Sum of Harmonic Magnitudes')
% xlim([0,2000]);
%
%
