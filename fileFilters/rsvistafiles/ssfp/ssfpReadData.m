function [Raw_data Im_data] = ssfpReadData(fname, Frames, frac_ks)
% function [Raw_data Im_data] = ssfpReadData(fname, Frames, [frac_ks=5/8]);
%
%	Function reads selected data from a P-file
%
%
%	INPUT:
%		fname   = P file name.
%	    Frames  = Number of temporal frames collected
%       frac_ks = fraction of K-space traversed. [default 5/8]
%
%	EXAMPLE:
%	  [R I] = getrawdata('P00000.7', 101);	% Read full p-file
%
%	Thomas S. John -- Feb 2009.
if notDefined('frac_ks'),   frac_ks = 0.625;        end

verbose = prefsVerboseCheck;

%% load raw data from Pfile
if verbose >= 1
    fprintf('[%s]: Loading Raw Data from %s. \t(%s) \n', mfilename, fname, datestr(now));
end

A = rawloadX(fname);

%% organize/recon data into image space
if verbose >= 1
    fprintf('[%s]: Reconning %s. \t(%s) \n', mfilename, fname, datestr(now));
end

[Raw_data Im_data] = organize_data(A,Frames);


%% construct final images from partial K-space acquisitions
if verbose >= 1
    fprintf('[%s]: Homodyne recon for %s. \t(%s) \n', ...
            mfilename, fname, datestr(now));
end

[RO PE Slices_per_frame Frames] = size(Raw_data);

for f=1:Frames
    for s=1:Slices_per_frame
        Im_data(:,:,s,f) = partial_k(Raw_data(:,:,s,f),frac_ks,RO,PE);
    end
end

% up/down rows flip
Im_data = Im_data(RO:-1:1,:,:,:);


return
