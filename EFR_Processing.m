%Take FFRs, process them, and calculate the cummulative sum of Harmonic
%Magnitudes. Should be generalized enough to run with any trial.
%Last Updated: Andrew Sivaprakasam, 7/2019
tic
clear all;
close all;

%% Parameters:

isHuman = 1; %MAKE SURE THIS IS 1 for Human or 0 for Chin

subject = "AS";

bstraps = 10; %simulated number of "chins"
t_array = [20,40,80,100,120,140];%number of trials conducted/polarity/subject. Make this an array if you want to test multiple N
%t_array = 280;

%Sampling
Fs0_Human = 4e3; %if subject is Human
Fs0_Chin = round(48828.125); %if subject is a Chin

Fs = 4e3; %What you want to downsample to
F0 = 100; %Fundamental freq of interest in Hz

iterations = 100;
window = [0.1,1.3];
gain = 20e3; %Gain (doesn't really matter since looking at SNR & PLV, used for magnitude accuracy)
%gain = 1;

K_MRS = 100; %number of distributions to average spectra and PLVs over
NF_iters = 100; %number of distributions to average noise floor over (inner average)

harmonics = 5;
%% Load Files:

if(isHuman)
    Fs0 = 4e3; %sampling rate in Hz
    folder = subject;
    cd(folder);
    
    SAM_data = load('SAM_Data_full.mat');
    sq25_data = load('SQ25_Data_full.mat');
    sq50_data = load('SQ50_Data_full.mat');
    
    SAM_tot_full = SAM_data.SAM_tot_arr;
    sq25_tot_full = sq25_data.SQ25_tot_arr;
    sq50_tot_full = sq50_data.SQ50_tot_arr;
    
    cd ../
else

    Fs0 = round(48828.125); %sampling rate in hz

    folder = strcat("MH-2019_06_07-",subject,"_FFRpilot");
    cd(folder);

    SAM_data = load('p0002_FFR_SNRenvSAM_atn25.mat');
    sq_25_data = load('p0003_FFR_SNRenvsq_25_atn25.mat');
    sq_50_data =load('p0004_FFR_SNRenvsq_50_atn25.mat');

    SAM_tot_full = SAM_data.data.AD_Data.AD_All_V;

    sq25_tot_full = sq_25_data.data.AD_Data.AD_All_V;

    sq50_tot_full = sq_50_data.data.AD_Data.AD_All_V;

    cd ../
end
    
fprintf('Files Loaded \n')

%% Select random dataset of certain number

for ta = 1:length(t_array)
    trials = t_array(ta);
    fprintf("*********************************\n\n\n Starting N = %d trials set\n\n\n *********************************",trials);
    
    for c = 1:bstraps
        fprintf("*********************************\n\n\n Trial Set = %d, Chin# = %d\n\n\n*********************************",trials,c);

        x = 1:length(SAM_tot_full);
        odv = x(rem(x,2)==1);
        evv = x(rem(x,2)==0);
        SAM_r_odds = odv(randi(length(odv),1,trials))';
        SAM_r_evens = evv(randi(length(evv),1,trials))';
        
        %Account for different number of collected trials, this may be
        %redundant, since taking same number of trials now...
        
        x = 1:length(sq25_tot_full);
        odv = x(rem(x,2)==1);
        evv = x(rem(x,2)==0);
        r_odds = odv(randi(length(odv),2,trials))';
        r_evens = evv(randi(length(evv),2,trials))';
        
        SAM_tot = cell(1,trials);
        sq25_tot = cell(1,trials);
        sq50_tot = cell(1,trials);

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
        
        [SAM_f,SAM_DFT,SAM_PLV] = getDFT(SAM_tot,trials,window,Fs,Fs0,gain,K_MRS,NF_iters);
        [sq25_f,sq25_DFT,sq25_PLV] = getDFT(sq25_tot,trials,window,Fs,Fs0,gain,K_MRS,NF_iters);
        [sq50_f,sq50_DFT,sq50_PLV] = getDFT(sq50_tot,trials,window,Fs,Fs0,gain,K_MRS,NF_iters);
        
        %% Converting back to linear
        
        SAM_DFT_uv = 10.^(SAM_DFT/20);
        sq25_DFT_uv = 10.^(sq25_DFT/20);
        sq50_DFT_uv = 10.^(sq50_DFT/20);
        
        %% Plotting & Summation
%         
%         MAG = figure;
%         subplot(2,1,1)
%         hold on;
%         plot(SAM_f,SAM_DFT_uv)
%         plot(sq25_f,sq25_DFT_uv)
%         plot(sq50_f,sq50_DFT_uv,'g')
%         title('DFT with Noise Floor removed')
%         %ylabel('SNR (dB)/Magnitude (dB, arbitrary)')
%         ylabel('SNR (Linear Scale)')
%         xlabel('Frequency')
%         xlim([0,2e3])
%         ylim([0,max(SAM_DFT_uv)+5])
%         
%         
%         %PLV Figure:
%         PLV = figure;
%         subplot(2,1,1)
%         hold on;
%         plot(SAM_f,SAM_PLV)
%         plot(sq25_f,sq25_PLV)
%         plot(sq50_f,sq50_PLV,'g')
%         title('PLV of Multiple Conditions')
%         %ylabel('SNR (dB)/Magnitude (dB, arbitrary)')
%         ylabel('PLV')
%         xlabel('Frequency')
%         xlim([0,2e3])
%         ylim([0,1])
        
%         
        %Get peaks and sum them, look at crossings
        
        [SAM_SUM,SAM_PKS,SAM_LOCS] = getSum(SAM_f,SAM_DFT_uv,F0,harmonics);
        [SQ25_SUM,SQ25_PKS,SQ25_LOCS] = getSum(sq25_f,sq25_DFT_uv,F0,harmonics);
        [SQ50_SUM,SQ50_PKS,SQ50_LOCS] = getSum(sq50_f,sq50_DFT_uv,F0,harmonics);
        
        [SAMP_SUM,SAMP_PKS,SAMP_LOCS] = getSum(SAM_f,SAM_PLV,F0,harmonics);
        [SQ25P_SUM,SQ25P_PKS,SQ25P_LOCS] = getSum(sq25_f,sq25_PLV,F0,harmonics);
        [SQ50P_SUM,SQ50P_PKS,SQ50P_LOCS] = getSum(sq50_f,sq50_PLV,F0,harmonics);
        
        
        SAM_MAG_SUM(c)= SAM_SUM(end);
        SQ25_MAG_SUM(c)= SQ25_SUM(end);
        SQ50_MAG_SUM(c)= SQ50_SUM(end);
        
        
        SAM_PLV_SUM(c)= SAMP_SUM(end);
        SQ25_PLV_SUM(c)= SQ25P_SUM(end);
        SQ50_PLV_SUM(c)= SQ50P_SUM(end);
        
    end
    
    SAM_MAG_MEAN(ta) = mean(SAM_MAG_SUM);
    SQ25_MAG_MEAN(ta) = mean(SQ25_MAG_SUM);
    SQ50_MAG_MEAN(ta) = mean(SQ50_MAG_SUM);
    
    SAM_MAG_std(ta) = std(SAM_MAG_SUM);
    SQ25_MAG_std(ta) = std(SQ25_MAG_SUM);
    SQ50_MAG_std(ta) = std(SQ50_MAG_SUM);
    
    
    SAM_PLV_MEAN(ta) = mean(SAM_PLV_SUM);
    SQ25_PLV_MEAN(ta) = mean(SQ25_PLV_SUM);
    SQ50_PLV_MEAN(ta) = mean(SQ50_PLV_SUM);
    
    SAM_PLV_std(ta) = std(SAM_PLV_SUM);
    SQ25_PLV_std(ta) = std(SQ25_PLV_SUM);
    SQ50_PLV_std(ta) = std(SQ50_PLV_SUM);
    
end

%% Saving Data

SAM_MAG_all_means = [t_array',SAM_MAG_MEAN',SAM_MAG_std'];
SQ25_MAG_all_means = [t_array',SQ25_MAG_MEAN',SQ25_MAG_std'];
SQ50_MAG_all_means = [t_array',SQ50_MAG_MEAN',SQ50_MAG_std'];

save('SAM_MAG_all_m.mat','SAM_MAG_all_means')
save('SQ25_MAG_all_m.mat','SQ25_MAG_all_means')
save('SQ50_MAG_all_m.mat','SQ50_MAG_all_means')

SAM_PLV_all_means = [t_array',SAM_PLV_MEAN',SAM_PLV_std'];
SQ25_PLV_all_means = [t_array',SQ25_PLV_MEAN',SQ25_PLV_std'];
SQ50_PLV_all_means = [t_array',SQ50_PLV_MEAN',SQ50_PLV_std'];

save('SAM_PLV_all_m.mat','SAM_PLV_all_means')
save('SQ25_PLV_all_m.mat','SQ25_PLV_all_means')
save('SQ50_PLV_all_m.mat','SQ50_PLV_all_means')

% figure(MAG)
% subplot(2,1,1);
% hold on;
% plot(SAM_LOCS,SAM_PKS,'bo',SQ25_LOCS,SQ25_PKS,'ro',SQ50_LOCS,SQ50_PKS,'go')
% legend('SAM','SQ25','SQ50','SAM','SQ25','SQ50')
% 
% subplot(2,1,2)
% plot(SAM_LOCS,SAM_SUM,SQ25_LOCS,SQ25_SUM,SQ50_LOCS,SQ50_SUM,'g')
% xlabel('Frequency') 
% ylabel('Cummulative Sum of Harmonic Magnitudes')
% xlim([0,2000]);
% 
% 
% 
% figure(PLV)
% subplot(2,1,1);
% hold on;
% plot(SAMP_LOCS,SAMP_PKS,'bo',SQ25P_LOCS,SQ25P_PKS,'ro',SQ50P_LOCS,SQ50P_PKS,'go')
% legend('SAM','SQ25','SQ50','SAM','SQ25','SQ50')
% 
% subplot(2,1,2)
% plot(SAMP_LOCS,SAMP_SUM,SQ25P_LOCS,SQ25P_SUM,SQ50P_LOCS,SQ50P_SUM,'g')
% xlabel('Frequency') 
% ylabel('Cummulative Sum of PLV Peaks')
% xlim([0,2000]);


toc
