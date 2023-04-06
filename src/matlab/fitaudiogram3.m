function [cohc, cihc] = fitaudiogram3(freqs, losses, species, target_ohc_loss)

% FITAUIDOGRAM3 (freqs, losses, species[, target_ohc_loss) Gives values of 
% Cohc and Cihc model parameters that produce a desired threshold shift for
% the cat & human auditory-periphery model of Zilany et al. (J. Acoust. 
% Soc. Am. 2009, 2014) and Bruce, Erfani & Zilany (Hear. Res. 2018).
%
% This versions was updated by Daniel R. Guest on 08/04/2022 to use higher
% resolution data (linearly interpolated from the original data), to clean 
% up the original code and comments/documentation
%
% [cohc, cihc] = fitaudiogram3(FREQUENCIES,dBLoss,species,Dsd_OHC_Loss)
%
% # Arguments:
%
% - `freqs`: an array of frequencies (Hz)
% - `losses`: an array of absolute thresholds at corresponding frequencies (dB SPL)
% - `species: an integer indicating the model species, "1" for cat, "2" for 
%      human BM tuning from Shera et al. (PNAS 2002), or "3" for human BM 
%      tuning from Glasberg & Moore (Hear. Res. 1990)
% - `target_ohc_loss`: is an optional array giving the desired threshold 
%      shift in dB that is caused by the OHC impairment alone (for each 
%      frequency in freqs). If this array is not given, then the default desired
%      threshold shift due to OHC impairment is 2/3 of the entire threshold
%      shift at each frequency.  This default is consistent with the
%      effects of acoustic trauma in cats (see Bruce et al., JASA 2003, and
%      Zilany and Bruce, JASA 2007) and estimated OHC impairment in humans
%      (see Plack et al., JASA 2004).
%
% # Returns:
%
% - `cohc`: an array of cohc values (see below for details), of
%      length(freqs)
% - `cihc: an array of cihc values (see below for details), of
%      length(freqs)
%
% # Data:
%
% Data that relates absolute thresholds to inner- and outer-hair-cell loss 
% is loaded from disk. These data are described below:
%
% - `file.cohc_out`: is the outer hair cell (OHC) impairment factor; a 
%      value of 1 corresponds to normal OHC function and a value of 0 
%      corresponds to total impairment of the OHCs. It is a vector of
%      length 150, ranging from 1.0 to 0.0.
%
% - `file.cihc_out`: is the inner hair cell (IHC) impairment factor; a 
%      value of 1 corresponds to normal IHC function and a value of 0 
%      corresponds to total impairment of the IHC. It is a vector of length
%      150, ranging from 1.0 to 0.0.
%
% - `file.cf_out`: is the vector of characteristic frequencies, of length
%      150, spanning logarithmically from 125 Hz to 10 kHz
%
% - `file.threshold_out`: is the array of absolute thresholds for a given
%      combination of CF, cohc, and cihc. It is an array of size
%      (150 CF vals, 150 CIHC vals, 150 COHC vals)

% Keep the contents of the mat-file in memory unless species changes.
persistent last_species file
if ~isequal(species,last_species)
	switch species
		case 1
			file = load('thresholds_interpolated_cat','cf_out','cihc_out','cohc_out','threshold_out');
		case 2
			file = load('thresholds_interpolated_human_shera','cf_out','cihc_out','cohc_out','threshold_out');
		case 3
			file = load('thresholds_interpolated_human_glasberg_moor','cf_out','cihc_out','cohc_out','threshold_out');
		otherwise
			error('Species #%d not known.',species)
	end
	last_species = species;
end

% Convert absolute thresholds to dB losses
try
	dBShift = file.threshold_out - file.threshold_out(:,1,1);
catch
	dBShift = bsxfun(@minus,file.threshold_out,file.threshold_out(:,1,1));
end

% Handle optional arguments
if nargin < 4
	target_ohc_loss = 2/3*losses;
end

% Pre-allocate storage
num_freq = length(freqs);
Cohc = zeros(1,num_freq);
OHC_Loss = zeros(1,num_freq);
Loss_IHC = zeros(1,num_freq);
Cihc = zeros(1,num_freq);

% Fit audiogram
% Loop through each requested frequency and save best-fitting OHC/IHC
% impariment values
for m = 1:length(freqs)
    % Check whether the requested frequency is out of bounds for the data,
    % raise warning
    if freqs(m) < file.cf_out(1) || freqs(m) > file.cf_out(end)
        warning("Requested CF is out of bounds!")
    end

    % Locate the frequency in the available cf range closest to requested
    % frequency, store its index
	[~,N] = min(abs(file.cf_out - freqs(m)));
	n = N(1);
	
    % If the requested OHC-induced dB loss is larger than possible, set
    % cohc to zero, otherwise set to best-fitting value
	if target_ohc_loss(m) > dBShift(n,1,end)
		Cohc(m) = 0;
	else
		[~,idx] = sort(abs(squeeze(dBShift(n,1,:)) - target_ohc_loss(m)));
		Cohc(m) = file.cohc_out(idx(1));
    end
	OHC_Loss(m) = interp1(file.cohc_out,squeeze(dBShift(n,1,:)),Cohc(m),'nearest');
	
    % Find the index for the closest cohc value
    [~,ind] = sort(abs(file.cohc_out - Cohc(m)));

    % Calculate how much dB loss we have to account for with IHC
    % dysfunction
	Loss_IHC(m) = losses(m) - OHC_Loss(m);
	
    % If the requested IHC-induced dB loss is larger than possible, set
    % cihc to zero, otherwise set to best-fitting value
	if losses(m) > dBShift(n,end,ind(1))
		Cihc(m) = 0;
	else
		[~,indx] = sort(abs(squeeze(dBShift(n,:,ind(1))) - losses(m)));
		Cihc(m) = file.cihc_out(indx(1));
    end
end

% Rename variables for output
cohc = Cohc;
cihc = Cihc;
