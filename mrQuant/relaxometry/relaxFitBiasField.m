function [b1fit, b] = relaxFitBiasField(b1map, k)
%
% [b1fit, b] = relaxFitBiasField(b1map, [k=[2 2 2]])
% 
% Fits a set of cosine basis functions to the non-NaN 
% values in b1map. Returns the reconstructed map (b1fit)
% and the basis function coefficients in b. The basis 
% functions are the first k components of the DCT.
%
% For a simple b1 field map, it seems that k=2
% is ideal. More than that and you begin to fit anatomical
% detail that is unlikely to be true b1 variability.
%
% Note that any NaNs in b1map are ignored in the fitting,
% but these voxels will be filled with extrapolated values 
% in the returned b1fit.
%
% HISTORY:
% 2008.03.23 RFD wrote it.

if(~exist('k','var')||isempty(k))
   k = [2 2 2];
end
if(numel(k)<3)
   k = repmat(k(1), 1, 3);
end

sz = size(b1map);

inds = find(isfinite(b1map));
[x,y,z] = ind2sub(size(b1map), inds);

% scale coords to -pi,pi
x = ((x-1)/((sz(1)-1)/2)-1)*pi;
y = ((y-1)/((sz(2)-1)/2)-1)*pi;
z = ((z-1)/((sz(3)-1)/2)-1)*pi;

% Build the seprarable basis functions. The bScale factor is simply to
% keep the basis functions in a good range (try single precision?).
bScale = 8;
s = bScale*sqrt(2./sz);
%s = [1 1 1];
Bx = ones(numel(x),k(1))/sqrt(sz(1));
for(kk=2:k(1)), Bx(:,kk) = s(1)*cos(x*(kk-1)); end
By = ones(numel(y),k(2))/sqrt(sz(2));
for(kk=2:k(2)), By(:,kk) = s(2)*cos(y*(kk-1)); end
Bz = ones(numel(z),k(3))/sqrt(sz(3));
for(kk=2:k(3)), Bz(:,kk) = s(3)*cos(z*(kk-1)); end

% Find the least-squares fit 
B = ones(numel(x),prod(k),'double');
for i3=1:k(3),
	for i2=1:k(2),
		B2 = Bz(:,i3).*By(:,i2);
		for i1=1:k(1),
            curInd = (i3-1)*k(2)*k(1) + (i2-1)*k(1) + (i1-1) + 1;
			B(:,curInd) = B2.*Bx(:,i1);
        end
    end
end
clear x y z Bx By Bz B2;
% WARNING: the following uses quite a bit of memory. Using 'single' allows
% us to comfortably do up to k=[7 7 7] on an 8GB machine. However, the
% 'single' pinv is broken- I can't get the SVD to converge.
%b = pinv(B)*b1map(inds);
% The mldivide (\) operator is similar to pinv(B)*b1map(inds), but works
% better for single-precision matrices and doesn't use as much extra memory
% to do its job. With double-precision, it can do [7 7 7] and squeak by in
% just under 8GB RAM. Single precision seems broken in r2006a.
b = B\b1map(inds);
clear B;

% Reconstruct the modelled b1map
bb = [-(sz-1)/2; (sz-1)/2];
[x,y,z] = meshgrid([bb(1,2):bb(2,2)], [bb(1,1):bb(2,1)], [bb(1,3):bb(2,3)]);
x = x(:)./bb(2,1)*pi;
y = y(:)./bb(2,2)*pi;
z = z(:)./bb(2,3)*pi;

s = bScale*sqrt(2./sz);
Bx = ones(numel(x),k(1))/sqrt(sz(1));
for(kk=2:k(1)), Bx(:,kk) = s(1)*cos(x*(kk-1)); end
By = ones([size(y) k(2)])/sqrt(sz(2));
for(kk=2:k(2)), By(:,kk) = s(2)*cos(y*(kk-1)); end
Bz = ones([size(z) k(3)])/sqrt(sz(3));
for(kk=2:k(3)), Bz(:,kk) = s(3)*cos(z*(kk-1)); end
b1fit = zeros(size(x));
for i3=1:k(3),
	for i2=1:k(2),
		B2 = Bz(:,i3).*By(:,i2);
		for i1=1:k(1),
            curInd = (i3-1)*k(2)*k(1) + (i2-1)*k(1) + (i1-1) + 1;
			b1fit = b1fit + b(curInd)*B2.*Bx(:,i1);
        end
    end
end

b1fit = reshape(b1fit,size(b1map));

return;
