function hdr = readHeaderMag(EfileName)
% Read E-file header associated with a P*.mag file.
%
% header = readHeaderMag(EfileName) 
%
% Returns header info from Efile produced by G. Glover's auto-recon program.
% Output is structure having field names corresponding to Glover's parameters.
%
% Ress 9/01
% ras, 10/05: imported into mrVista 2.0
if nargin==0
    if exist('Raw/Pfiles','dir')
        startDir = 'Raw/Pfiles';
    else
        startDir = pwd;
    end
    [f p] = myUiGetfile(startDir,'*.7','Choose an E-file');
    EfileName = fullfile(p,f);
end

hdr = [];

fid = fopen(EfileName);
if fid == -1
    Alert(['Could not open file: ' EfileName])
    return
end

nLine = 0;
while 1
    line = fgetl(fid);
    if ~ischar(line), break, end
    ieq = findstr(line, '=');
    lhs = line(1:ieq-2);
    rhs = line(ieq+2:end);
    switch lhs
    case 'rev'
        % Revision
        hdr.rev = rhs;
    case 'date of scan'
        % Date
        hdr.date = rhs;
        % Make this more reasonable
        hdr.date=[hdr.date(1:6),hdr.date(8:end)];
    case 'time of scan'
        % Time
        hdr.time = rhs;
    case 'patient name'
        % Name
        hdr.name = rhs;
        
    case 'psd'
        % PSD
        hdr.psd = rhs;
    case 'coil'
        % Coil
        hdr.coil = rhs;
    case 'slquant'
        % Number of slices
        hdr.slquant = getNumberFromString(rhs);
    case 'num time frames'
        % Number of frames
        hdr.nframes = getNumberFromString(rhs);
    case 'numextra discards'
        % Number of discarded shots
        hdr.nextra = getNumberFromString(rhs);
    case 'nshot'
        % Number of interleaves
        hdr.nshots = getNumberFromString(rhs);
    case 'FOV'
        % Field of view (mm)
        hdr.FOV = getNumberFromString(rhs);
    case 'slice thick'
        % Slice thickness (mm)
        hdr.sliceThickness = getNumberFromString(rhs);
    case 'skip'
        % Slice spacing (skip)
        hdr.skip = getNumberFromString(rhs);
    case 'TR'
        % Echo time, TR (ms)
        hdr.TR = getNumberFromString(rhs);
    case 'TE'
        % Repetition time, TE (ms)
        hdr.TE = getNumberFromString(rhs);
    case 'time/frame'
        % Acquisition time (ms)
        hdr.tAcq = getNumberFromString(rhs);
    case 'equiv matrix size'
        % Equivalent matrix size
        hdr.equivMatSize = getNumberFromString(rhs);
    case 'imgsize'
        % Image size
        hdr.imgsize = getNumberFromString(rhs);
    case 'pixel size'
        % Pixel size (mm)
        hdr.pixel = getNumberFromString(rhs);
    case 'freq'
        % Frequency (MHz)
        hdr.freq = getNumberFromString(rhs)/1.e6;
    case 'R1, R2, TG (mps)'
        % Gains [R1, R2, TG]
        hdr.R1 = getNumberFromString(rhs, 1);
        hdr.R2 = getNumberFromString(rhs, 2);
        hdr.TG = getNumberFromString(rhs, 3);
    otherwise
    end
end
