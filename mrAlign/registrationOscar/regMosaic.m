function im = regMosaic(im1, im2, N)
% regMosaic - generates a checkerboard mosaic from the two input images
%             with blocks of size NxN (default 10)
%
%       im = regMosaic(im1, im2, <N>)
%
% Oscar Nestares - 5/99
%

[Ny Nx] = size(im1);
if nargin<3
   N=round(max(Ny,Nx)/15);
end

im1(find(isnan(im1))) = 0;
im2(find(isnan(im2))) = 0;

basic = [ones(N) zeros(N); zeros(N) ones(N)];
check = repmat(basic, ceil(Ny/N), ceil(Nx/N));
check = check(1:Ny,1:Nx);

% puts a slightly different contrast in one image than in the other
im = check.*im1*0.9 + (~check).*im2;
