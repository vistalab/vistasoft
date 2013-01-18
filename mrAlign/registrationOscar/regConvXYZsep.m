function volf = regConvXYZsep(vol, Zb, xfilter, yfilter, zfilter);
% regConvXYZsep - separable convolution in (X,Y,Z), with border handling in Z
%      
% volf = regConvXYZsep(vol, Zb, xfilter, yfilter, zfilter);
%
% This function performs a separable convolution of a volume (vol)
% with three kernels (xfilter, yfilter, zfilter). The convolution
% slice by slice is performed by convXYsep, and in Z by convZ.
% The parameter Zb specifies the border handling in the Z direction.
% The number of slices of the output volume is the same that
% the input volume.
%
% INPUT:
% - vol: Input volume
% - Zb: Border handling in Z direction 
%   - 'repeat' -> extends the volume by replicating the first and last
%                 slice
%   - 'interpol' -> repeats first and previous to last slice (useful
%                   when the input has zero interleaved slices as the
%                   result of the first step of interpolation in Z)
%   - 'zeros'  -> fills with zeros
% - xfilter: filter in x direction
% - yfilter: filter in y direction
% - zfilter: filter in z direction
% If only 1 filter is specified, the same filter is applied to (x,y,z)
%
% OUTPUT:
% - volf: filtered volume
%
% Oscar Nestares - 5/99
%

% checking if only 1 filter has been passed
if nargin==3
   yfilter = xfilter;
   zfilter = xfilter;
end

% original volume size
[Ny Nx Nz] = size(vol);

% border length in x, y and z
Bx = (length(xfilter) - 1)/2;
By = (length(yfilter) - 1)/2;
Bz = (length(zfilter) - 1)/2;

% temporal volume with room for the border in z
tmp = zeros(Ny-2*By, Nx-2*Bx, Nz+2*Bz);

% initial filtering in X and Y
tmp(:,:,Bz+1:Nz+Bz) = convXYsep(vol, xfilter, yfilter);

% putting appropriate border in Z to tmp
if strcmp(Zb, 'repeat') == 1
   % repeating first and last slice in Z
   tmp(:,:,1:Bz) = repmat(tmp(:,:,Bz+1),[1 1 Bz]); 
   tmp(:,:,Nz+Bz+1:Nz+2*Bz) = repmat(tmp(:,:,Nz+Bz),[1 1 Bz]); 
elseif strcmp(Zb, 'interpol')==1
   % repeating first and previous to last slice in Z
   tmp(:,:,1:Bz) = repmat(tmp(:,:,Bz+1),[1 1 Bz]); 
   tmp(:,:,Nz+Bz+1:Nz+2*Bz) = repmat(tmp(:,:,Nz+Bz-1),[1 1 Bz]);
   for k=1:2:Bz
      if Nz+Bz+1+k<= size(tmp,3), tmp(:,:,Nz+Bz+1+k) = 0; end
      tmp(:,:,Bz+1-k) = 0;
   end
else
   tmp(:,:,1:Bz) = 0; 
   tmp(:,:,Nz+Bz+1:Nz+2*Bz) = 0;
end

% final filtering in Z
volf = convZ(tmp, zfilter);

return
