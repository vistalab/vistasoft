function [Raw_data Im_data] = getrawdata(fname, Frames)
% function [Raw_data Im_data] = getrawdata(fname, Frames);
%
%	Function reads selected data from a P-file
%
%
%	INPUT:
%		fname   = P file name.
%	    Frames  = Number of temporal frames collected
%
%	EXAMPLE:
%	  [R I] = getrawdata('P00000.7', 101);	% Read full p-file
%
%	Thomas S. John -- Feb 2009.

frac_ks = 0.625;
A = rawloadX(fname);

[Raw_data Im_data] = organize_data(A,Frames);

[RO PE Slices_per_frame Frames] = size(Raw_data);

for f=1:Frames
    for s=1:Slices_per_frame
        Im_data(:,:,s,f) = partial_k(Raw_data(:,:,s,f),frac_ks,RO,PE);
    end
end

Im_data = Im_data(RO:-1:1,:,:,:);
