function dt6 = dtiLoadTensorElements(teBasename)
% dt6 = dtiLoadTensorElements(teBasename)
% 
%
% HISTORY:
% 2004.03.26 RFD (bobd@stanford.edu) Wrote it.
%
% TODO:
%
% 

if(~exist('teBasename', 'var') | isempty(teBasename))
    [f,p] = uigetfile({'*.001';'*.*'},'Select a slice from the Tensor Elements file...');
    teBasename = fullfile(p,f(1:end-3));
end

if(teBasename(end) ~= '.')
    teBasename = [teBasename '.'];
end

nSlices = length(dir([teBasename,'*']));
d = dir([teBasename,'001']);
% OK- there are 6*4=24 bytes per voxel -> d.bytes/24 voxels. We assume that
% the bits are divided equally between X and Y.
xySize = sqrt(d.bytes./24);
imdim = [xySize,xySize,nSlices];
disp([mfilename ': I''m guessing that the image dimension is [',num2str(imdim),'] (based on file size).']);

npix = imdim(1)*imdim(2);
dt6 = zeros([imdim,6]);
disp(['Reading ',num2str(nSlices),' slices...']);
for(ii=1:imdim(3))
    fname = sprintf('%s%03d', teBasename, ii);
    fid = fopen(fname, 'rb', 'ieee-le');
    dt6(:,:,ii,:) = reshape(fread(fid, inf, 'float32'),[imdim(1),imdim(2),1,6]);
    fclose(fid);
end
return;