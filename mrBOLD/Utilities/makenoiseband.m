function makenoiseband(mrSESSION, fdrift, fresp, fcard)
% makenoiseband(mrSESSION, fdrift, fresp, fcard)
% PURPOSE: Provides input for mrVista function AddNoiseBand
% Works in Hz rather than cycles per scan : converts between the two
% using the correct TR taken from mrSESSION.functionals(1).framePeriod
% and nFrames
%
% Thomas Ferree @ UCSF
% Created 1/23/2005

% extract necessary parameters from mrSESSION
TR = mrSESSION.functionals(1).framePeriod;
nFrames = mrSESSION.functionals(1).nFrames;
df = 1/(TR*nFrames);

% compute discrete frequency indices from input

if length(fdrift) > 0
    drift1 = round(fdrift(1)/df) + 1;
    drift2 = round(fdrift(2)/df) + 1;
    driftband = [drift1:drift2];
    if drift1 < 1 | drift2 < 1 | drift1 > (fix(nFrames/2)+1) | drift2 > (fix(nFrames/2)+1)
        error('Drift band is out of range.');
    end
else
    driftband = [];
end

if length(fresp) > 0
    resp1 = round(fresp(1)/df) + 1;
    resp2 = round(fresp(2)/df) + 1;
    respband = [resp1:resp2];
    if resp1 < 1 | resp2 < 1 | resp1 > (fix(nFrames/2)+1) | resp2 > (fix(nFrames/2)+1)
        error('Respiration band is out of range.');
    end
else
    respband = [];
end

if length(fcard) > 0
    card1 = round(fcard(1)/df) + 1;
    card2 = round(fcard(2)/df) + 1;
    cardband = [card1:card2];
    if card1 < 1 | card2 < 1 | card1 > (fix(nFrames/2)+1) | card2 > (fix(nFrames/2)+1)
        error('Cardiac band is out of range.');
    end
else
    cardband = [];
end

% out of sequence errors

if length(fdrift) > 0 & length(fresp) > 0 & drift2 > resp1
    error('Definition of drift and respiration bands is mixed up.');
end

if length(fresp) > 0 & length(fcard) > 0 & resp2 > card1
    error('Definition of respiration and cardiac bands is mixed up.');
end

% compute noise band (frequencies to be kept)
allband = 1:nFrames/2+1;
dropband = union(union(driftband,respband),cardband);
noiseband = setdiff(allband,dropband);

% call mrVista function AddNoiseBand
AddNoiseBand(noiseband);

