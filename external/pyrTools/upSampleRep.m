function out = upSampleRep(im,resSize)
% out = upSampleRep(im,resSize)
%
% Upsamples the image im by pixel replication.
%
% djh, 2/19/2001
% ras, 04/02/2005 -- deals with 3D as well as 2D matrices.
if ~isnumeric(im) | ndims(im) > 3
    error('upSampleRep only works on 1D, 2D, or 3D numeric matrices.')
end

if ndims(im) ~= length(resSize)
    error('upSampleRep: The rescale size should have the same # of dimensions as the image.')
end

if ndims(im) <= 2
	upSampleFactor = resSize./size(im);
	y = [0:resSize(1)-1];
	x = [0:resSize(2)-1];
	ysub = floor(y/upSampleFactor(1));
	xsub = floor(x/upSampleFactor(2));
	out = im(ysub+1,xsub+1);
elseif ndims(im)==3
    upSampleFactor = resSize./size(im);  
    y = [0:resSize(1)-1]; % x/y flipped b/c dims are rows,cols,slices
    x = [0:resSize(2)-1];
    z = [0:resSize(3)-1];
    ysub = floor(y/upSampleFactor(1));
    xsub = floor(x/upSampleFactor(2));
    zsub = floor(z/upSampleFactor(3));
    out = im(ysub+1,xsub+1,zsub+1);
end

    
    
return

%%% Debug/test

im = zeros(3,3);
im(2,2)=1;

upIm = upSampleRep(im,[6,6])
upIm = upSampleRep(im,[9,9])
upIm = upSampleRep(im,[6,7])

