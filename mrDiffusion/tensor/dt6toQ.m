function Q = dt6toQ(dt6Data,coords)
% Convert dt6 values at coords = (x,y,z) in coords to 3x3 tensor format
%
%   Q = dt6toQ(dt6Data,coords)
%
% The returned Q is a cell array of quadratic forms.  I believe that the
% predicted ADC value is obtained from the Q using 
%
%     ADC = bvec(:)'*Q*bvec(:)
%
% The eigenvalues and eigenvectors of Q are the lengths and directions of
% the principal diffusion directions of the ellipsoid.
%
% Example:
%  dt6Data = dt6.dt6;
%  coords = [40:42;40:42;40:42]';
%  Q = dt6toQ(dt6Data,coords);
%  M = reshape(Q(1,:),3,3);
%  eigs(M)
%
% See also: dti6to33, dti33to6, dt6VECtoMAT
%    These functions manage the large data volume. This version doesn't
%    apply to the large data set, with many subjects, but it is easier for
%    me to understand (BW). See also dt6VECtoMAT, which takes a single
%    vector format of the tensor and converts it to the proper 3x3
%    Quadratic form.
%
% (c) Stanford VISTA Team 2011

if notDefined('dt6Data'), error('No data'); end
if notDefined('coords'),      coords = 1;
elseif (size(coords,2) ~= 3), error('coords in wrong format');
end

nCoords = size(coords,1);
Q = zeros(nCoords,9);
for ii=1:nCoords
    t = dt6Data(coords(ii,1),coords(ii,2),coords(ii,3),:);
    M(1,1) = t(1);  M(1,2) = t(4); M(1,3) = t(5);
    M(2,1) = t(4);  M(2,2) = t(2); M(2,3) = t(6);
    M(3,1) = t(5);  M(3,2) = t(6); M(3,3) = t(3);
    Q(ii,:) = reshape(M,1,9);  % Inverse is reshape(M,3,3)
end

if coords == 1, Q = squeeze(Q); end

return;

% Inverse
% M = 1:9
% M = reshape(M,3,3)
% M = reshape(M,1,9)

