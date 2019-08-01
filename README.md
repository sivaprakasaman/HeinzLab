# EFR Processing - Andrew Sivaprakasam, Summer 2019

Contact: [Email](asivapr@purdue.edu)

The following scripts/methods were designed to calculate and analyze Phase Locking Values (PLVs) and spectral magnitudes of _**both**_ human and chinchilla Envelope Following Responses (EFRs). 

The math equations that were used can be found in the appendix of a [paper](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3724813/#c29) by Li Zhu, [Hari Bharadwaj](https://github.com/haribharadwaj), Jing Xia, and Barbara Shinn-Cunningham.

Human data pre-processing was done in [MNE](https://martinos.org/mne/stable/index.html) and also made use of functions found in the [ANLffr](https://github.com/SNAPsoftware/ANLffr) package.

## Pre-Processing

The data that can be loaded into the main script, `EFR_Processing.m`, must be in a *.mat* format. Chinchilla data from NEL should be directly compatible, so long as it is a *.mat*. 

However, data collected in a *.bdf* format must be passed through the python `bdf2mat.py` script found in the **MNE_code** subfolder, in order to be processed properly. 

`bdf2mat(froot,fs,Fs_new,hpf,t_stim,topchans,trial_name)` simply converts the *.bdf* into a *.mat* format that can be read by the main script, `EFR_Processing.m`. It also prints out multi-tapered PLV and Spectral Magnitudes of the averages of all trials (not truncated, but epoch'd). 


**Example:**
```
trial_name = 'SQ25'    
froot = "C:\\Users\\racqu\\Documents\\Research\\Purdue\\HumanData\\AS\\"+trial_name+'\\'
fs = 16384
Fs_new = 4e3
hpf = 70
t_stim = [0.0,1.5] 
topchans = [31] 


bdf2mat(froot,fs,Fs_new,hpf,t_stim,topchans,trial_name)
```

`trial_name` - the name of the condition/stimulus you're testing

`froot` - root directory of all conditions

`fs` - sampling frequency (Hz) of your data

`hpf` - cutoff frequency for high pass filtering of the data

`t_stim` - the window you're interested in pulling the data for the *.mat* file from

`topchans` -  channel of interest (don't believe my code works with multiple channels yet)

### Using `EFR_Processing.m`

`EFR_Processing.m` is an implementation of multiple methods, detailed later. It allows the user to bootstrap data using a single subject, and also calculate means and standard deviations of summation of harmonic magnitudes and PLVs related to a particular fundamental frequency, F0.

**Parameters**:

```
isHuman = 0; %MAKE SURE THIS IS 1 for Human or 0 for Chin

subject = "Q379";

bstraps = 1; %simulated number of "chins"
%t_array = [20,40,80,100,120,140];%number of trials conducted/polarity/subject. Make this an array if you want to test multiple N
t_array = 100;

%Sampling
Fs0_Human = 4e3; %if subject is Human
Fs0_Chin = round(48828.125); %if subject is a Chin

Fs = 4e3; %What you want to downsample to
F0 = 100; %Fundamental freq of interest in Hz

iterations = 100;
window = [0.1,1.3]; %Window of interest, truncated onset and break in stimulus
gain = 20e3; %Gain (doesn't really matter since looking at SNR & PLV, used for magnitude accuracy)
%gain = 1;

K_MRS = 100; %number of distributions to average spectra and PLVs over
K_NF = 10; %number of iterations to average noise floor distributions over (outer average)
I_NF = 100; %number of distributions to average noise floor over (inner average)

harmonics = 6; %How many harmonics to sum
```
**Parameters of note:**
The appendix of the paper helps understand these parameters.

`bstraps` - how many times to run each element in `t_array` used to simulate multiple subjects and determine a minimum number of trials

`t_array` - how many trials you want to sample from your total dataset (randomly selected). 

**NOTE: for a given element in t_array, 1/5th of the trials are selected at a time for analysis. An average of `K_MRS` distributions of 1/5th of `t_array[i]` is calculated.**

`K_MRS`- how many distributions of a dataset with `t_array[i]` trials (400 in the paper)

`K_NF` and `I_NF`- how many iterations and distributions, respectively of the spectral noise floor estimate to compute (1000 and 100 in paper, but 10 and 100 seemed to also be sufficient). **Significantly increases computational expense.** 


**Figures:**
The following two figures may be generated in `EFR_Processing.m` if these lines are uncommented:

```
    MAG = figure;
    subplot(2,1,1)
    hold on;
    plot(SAM_f,SAM_DFT_uv)
    plot(sq25_f,sq25_DFT_uv)
    plot(sq50_f,sq50_DFT_uv,'g')
    title('DFT with Noise Floor removed')
    %ylabel('SNR (dB)/Magnitude (dB, arbitrary)')
    ylabel('SNR (Linear Scale)')
    xlabel('Frequency')
    xlim([0,2e3])
    ylim([0,max(SAM_DFT_uv)+5])
    
    
    %PLV Figure:
    PLV = figure;
    subplot(2,1,1)
    hold on;
    plot(SAM_f,SAM_PLV)
    plot(sq25_f,sq25_PLV)
    plot(sq50_f,sq50_PLV,'g')
    title('PLV of Multiple Conditions')
    %ylabel('SNR (dB)/Magnitude (dB, arbitrary)')
    ylabel('PLV')
    xlabel('Frequency')
    xlim([0,2e3])
    ylim([0,1])

```

...


```
figure(MAG)
subplot(2,1,1);
hold on;
plot(SAM_LOCS,SAM_PKS,'bo',SQ25_LOCS,SQ25_PKS,'ro',SQ50_LOCS,SQ50_PKS,'go')
legend('SAM','SQ25','SQ50','SAM','SQ25','SQ50')

subplot(2,1,2)
plot(SAM_LOCS,SAM_SUM,SQ25_LOCS,SQ25_SUM,SQ50_LOCS,SQ50_SUM,'g')
xlabel('Frequency') 
ylabel('Cummulative Sum of Harmonic Magnitudes')
xlim([0,2000]);



figure(PLV)
subplot(2,1,1);
hold on;
plot(SAMP_LOCS,SAMP_PKS,'bo',SQ25P_LOCS,SQ25P_PKS,'ro',SQ50P_LOCS,SQ50P_PKS,'go')
legend('SAM','SQ25','SQ50','SAM','SQ25','SQ50')

subplot(2,1,2)
plot(SAMP_LOCS,SAMP_SUM,SQ25P_LOCS,SQ25P_SUM,SQ50P_LOCS,SQ50P_SUM,'g')
xlabel('Frequency') 
ylabel('Cummulative Sum of PLV Peaks')
xlim([0,2000]);

```

**WARNING: Uncommenting these and running with `bstraps`>1 & `t_array` with length>1 will result in an abomination of figures**



### Using `getDFT.m`

A step by step series of examples that tell you how to get a development env running

Say what the step will be

```
Give the example
```

And repeat

```
until finished
```

End with an example of getting some data out of the system or using it for a little demo

## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc
