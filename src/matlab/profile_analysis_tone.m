function signal_out = profile_analysis_tone(freqs, target_component, kw)
% PROFILE_ANALYSIS_TONE Synthesizes a profile analysis tone composed of a 
% deterministic set of components
% 
% # Arguments
% - `freqs::Vector`: vector of frequenices to include in stimulus (Hz)
% - `target_comp`: which component should contain the increment
% - `fs=100e3`: sampling rate (Hz)
% - `dur=0.10`: duration (s), total duration *includes* ramp
% - `dur_ramp=0.01`: duration of raised-cosine ramp (s)
% - `increment=0.0`: increment in signal re: standard (dB)
% 
% # Returns
% - `::Vector`: vector containing profile analysis tone
arguments
    freqs (1, :)
    target_component (1, 1)
    kw.fs (1, 1) = 100e3
    kw.level_pedestal (1, 1) = 50.0
    kw.dur (1, 1) = 1.0
    kw.dur_ramp (1, 1) = 0.01
    kw.increment (1, 1) = 0.0
end
    % Configure levels
    levels = repmat([kw.level_pedestal], 1, length(freqs));
    levels(target_component) = levels(target_component) + 20 * log10(1 + 10^(kw.increment/20));

    % Synthesize
    signal_out = complex_tone( ...
        freqs, ...
        levels, ...
        zeros(1, length(freqs)), ...
        kw.dur, ...
        kw.dur_ramp, ...
        kw.fs ...
    );
end

