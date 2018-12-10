function mr = mrReadSSFP(pth, phaseCyclePath, nFrames, varargin);
%
%  mr = mrReadSSFP([non-phase-cycle directory], [phase-cycle directory], [nFrames], [options]);
%
% Read in a series of SSFP files, combining phase-cycle and non-phase cycle
% scans using the maximum intensity projection described in (Lee et al,
% Neuroimage, 2008).
%
% Note that this function reconstructs the P-files from K-space. To get the
% raw K-space data, use the function mrReadSSFPRaw.
%
%
% ras, 02/2009.
if notDefined('pth')
    pth = mrvSelectFile('r', '7', 'Select SSFP Raw (P*.7) file');
end

if notDefined('phaseCyclePath'), phaseCyclePath = '';   end

if notDefined('nFrames'),       nFrames = [];           end


%% params
combineMethod = 'sumofsquares';  % 'maxintensity' or 'sumofsquares'
kspaceFraction = 5/8;

% GUM: defaults are from SSFP pilot data
voxelSize = [1.5 1.5 2.5 2.16];

%% parse options
for ii = 1:2:length(varargin)
    eval( sprintf('%s = %s', varargin{ii}, num2str(varargin{ii+1})) );
end

%% get full path, and fileparts of the path:
pth = fullpath(pth);
[p f ext] = fileparts(pth);

%% initalize an empty mr struct:
mr = mrCreateEmpty;
mr.format = 'ssfp';
mr.name = [f ext];
mr.path = pth;

% set other fields
mr.voxelSize = voxelSize;
mr.dataUnits = 'Arbitrary';
mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};

%% read the data
[R I] = ssfpReadData(pth, nFrames);

mr.data = I;
mr.dims = size(mr.data);  
if length(mr.dims) < 4, mr.dims(4) = 1; end
mr.extent = mr.dims .* mr.voxelSize;
mr.dataRange = mrvMinmax(mr.data);

%% set other fields: coordinat spaces, etc.
mr.spaces = mrStandardSpaces(mr);

%% combine with phase-cycled data if needed
if ~isempty(phaseCyclePath)
    mr_cycle = mrReadSSFP(phaseCyclePath, '', nFrames);

    % note what data we're combining, and how:
    msg = sprintf('Combination of %s and %s using %s method.', mr.path, ...
                  mr_cycle.path, combineMethod);
    mr.comments = strvcat(mr.comments, msg);

    
    switch lower(combineMethod)
        case {'maxintensity' 'max' 'mip' 'maxintensityprojection'}
            mr = maxIntensityProjection(mr, mr_cycle);
        case {'sumofsquares' 'sos' 'sumsquared'}
            mr = sumOfSquares(mr, mr_cycle);
        otherwise
            error('Invalid combination method: %s.', combineMethod)
    end
    return
end

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function mr = maxIntensityProjection(mr, mr2);
% Combine two mr data volumes using the maximum-intensity projection method
% described in Lee et al, NeuroImage, 2008). This puts the data in the
% first mr struct provided.
% 
% ras 02/2009.

verbose = prefsVerboseCheck;
if verbose >= 1
    h = mrvWaitbar(0, 'Computing Max Intensity Projection');
end

% first, compute the mean images over time for each MR data set.
mu1 = nanmean(abs(mr.data), 4);
mu2 = nanmean(abs(mr2.data), 4);

% create a binary mask indicating which MR data set from which draw data
% for each voxel.
mask = zeros( size(mu1) );
for ii = 1:numel(mask)
    if mu1(ii) > mu2(ii)
        mask(ii) = 1;
    else
        mask(ii) = 2;
    end
end

% now, for those points for which the mask indicates to use mr2, copy over
% those data points into the mr1 data. (For the other points, where the
% mask indicates mr data 1, we already have the appropriate data loaded.
for t = 1:size(mr.data, 4)
    subvol = mr.data(:,:,:,t);
    subvol2 = mr2.data(:,:,:,t);
    
    subvol(mask==2) = subvol2(mask==2);
    
    mr.data(:,:,:,t) = subvol;
    
    if verbose >= 1, mrvWaitbar( t / size(mr.data, 4), h ); end
end

if verbose >= 1
    close(h);
end

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function mr = sumOfSquares(mr, mr2);
% Combine two mr data volumes using the sum-of-squares method
% described in Lee et al, NeuroImage, 2008). This puts the data in the
% first mr struct provided.
% 
% ras 02/2009.
mr.data = sqrt( (mr.data .^ 2) + (mr2.data .^ 2) );
return
