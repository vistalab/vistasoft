function vec_new = dtiXformVectors(vec, xform, prePost)
% vec_new = dtiXformVectors(vec, xform, prePost)
% 
% Efficiently applies the 3x3 transform to a vector volume.
% Vec is a XxYxZx3x3 array.
%
% If prePost = 'pre', the xform is pre-multiplied (the default). 
% prePost = 'post' will post-multiply.
%
% HISTORY:
% 2003.12.15 RFD & ASH Wrote it.

if(~exist('prePost','var') | isempty(prePost))
    prePost = 'pre';
end
if(strcmp(lower(prePost), 'post'))
    % transpose vectors and xform to achieve post-multiply
    vec = permute(vec, [1 2 3 5 4]);
    xform = xform';
end
vec_new = zeros(size(vec));

vec_new(:,:,:,1,1) = xform(1,1).*vec(:,:,:,1,1) + xform(1,2).*vec(:,:,:,2,1) + xform(1,3).*vec(:,:,:,3,1);
vec_new(:,:,:,1,2) = xform(1,1).*vec(:,:,:,1,2) + xform(1,2).*vec(:,:,:,2,2) + xform(1,3).*vec(:,:,:,3,2);
vec_new(:,:,:,1,3) = xform(1,1).*vec(:,:,:,1,3) + xform(1,2).*vec(:,:,:,2,3) + xform(1,3).*vec(:,:,:,3,3);
vec_new(:,:,:,2,1) = xform(2,1).*vec(:,:,:,1,1) + xform(2,2).*vec(:,:,:,2,1) + xform(2,3).*vec(:,:,:,3,1);
vec_new(:,:,:,2,2) = xform(2,1).*vec(:,:,:,1,2) + xform(2,2).*vec(:,:,:,2,2) + xform(2,3).*vec(:,:,:,3,2);
vec_new(:,:,:,2,3) = xform(2,1).*vec(:,:,:,1,3) + xform(2,2).*vec(:,:,:,2,3) + xform(2,3).*vec(:,:,:,3,3);
vec_new(:,:,:,3,1) = xform(3,1).*vec(:,:,:,1,1) + xform(3,2).*vec(:,:,:,2,1) + xform(3,3).*vec(:,:,:,3,1);
vec_new(:,:,:,3,2) = xform(3,1).*vec(:,:,:,1,2) + xform(3,2).*vec(:,:,:,2,2) + xform(3,3).*vec(:,:,:,3,2);
vec_new(:,:,:,3,3) = xform(3,1).*vec(:,:,:,1,3) + xform(3,2).*vec(:,:,:,2,3) + xform(3,3).*vec(:,:,:,3,3);
if(strcmp(lower(prePost), 'post'))
    % transpose to achieve post-multiply
    vec_new = permute(vec_new, [1 2 3 5 4]);
end
return;

% this is equivalent to:
% vec_new = zeros(size(vec));
% for (x=1:size(vec,1)),
%     for (y=1:size(vec,2)),
%         for (z=1:size(vec,3)),
%             if(strcmp(lower(prePost), 'post'))
%                 vec_new(x,y,z,:,:) = squeeze(vec(x,y,z,:,:)) * xform;
%             else
%                 vec_new(x,y,z,:,:) = xform * squeeze(vec(x,y,z,:,:));
%             end
%         end
%     end
% end

