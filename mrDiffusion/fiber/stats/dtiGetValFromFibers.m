function val = dtiGetValFromFibers(dt6, fg, xform, valName, interpMethod, uniqueVox)
%
% val = dtiGetValFromFibers(dt6_OR_scalarImage, fiberGroup, xform, [valName='fa'], [interpMethod='trilin'], [uniqueVox=0])
%
% Returns an interpolated image value for each fiber coordinate. If the
% image is a dt6 structure, then you can specify what type of value you'd
% like from the tensors by specifying 'valName' (see dtiGetValFromTensors
% for options).
% 
% Input parameters:
%   xform        - the transform that converts fiber coords to dt6 indices.
%   interpMethod - 'nearest','trilin', 'spline' method for interpolation.
%   [uniqueVox]  - 0 returns values for each fiber node, 1 returns values for
%                  each unique voxel touched by the fg

% HISTORY:
% 2005.03.18 RFD (bob@white.stanford.edu) wrote it.
% 2009.03.23 DY: in creating the FIBERLEN variable, replaced call to length
% with a call to size and picking out the column dimension, which is the
% number of nodes. Length would just take the largest dimension, which
% would be 3 (number of rows), if the number of nodes in that path is 1 or 2.
% 2010.11.08 JMT: Added option to get one value for each unique voxel.

if(~exist('valName','var') || isempty(valName))
    valName = 'fa';
end
if(~exist('interpMethod','var') || isempty(interpMethod))
    interpMethod = 'trilin';
end
if(~exist('uniqueVox','var') || isempty(uniqueVox))
    uniqueVox = 0;
end

if(iscell(fg))
    coords = horzcat(fg{:})';
else
    coords = horzcat(fg.fibers{:})';
end

coords = mrAnatXformCoords(xform, coords);

if uniqueVox==1
    coords = unique(round(coords),'rows');
end

if(size(dt6,4)==6)
  [tmp1,tmp2,tmp3,tmp4,tmp5,tmp6] = dtiGetValFromTensors(dt6,coords,eye(4),valName,interpMethod);
  tmp = [tmp1(:) tmp2(:) tmp3(:) tmp4(:) tmp5(:) tmp6(:)];
  clear tmp1 tmp2 tmp3 tmp4;
else
  % assume it's a scalar
  switch lower(interpMethod)
    case 'nearest'
        interpParams = [0 0 0 0 0 0];  
    case 'trilin'
        interpParams = [1 1 1 0 0 0];
    case 'spline'
        interpParams = [7 7 7 0 0 0];
    otherwise
        error(['Unknown interpMethod "' interpMethod '".']);
  end
  spCoefs = spm_bsplinc(dt6, interpParams);
  tmp = spm_bsplins(spCoefs, coords(:,1), coords(:,2), coords(:,3), interpParams);
end

if uniqueVox == 1
    val=tmp;
    disp(['Num unique voxels: ' num2str(size(coords,1))]);
else
    fiberLen=cellfun('size', fg.fibers, 2);
    start = 1;
    val = cell(1,length(fg.fibers));
    for ii=1:length(fg.fibers)
        val{ii} = tmp(start:start+fiberLen(ii)-1,:);
        start = start+fiberLen(ii);
    end
end

return;
