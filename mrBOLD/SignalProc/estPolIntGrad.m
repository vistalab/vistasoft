function [Int, p, mask, w3] = estPolIntGrad(inp, N, logFlag);
% ESTPOLINTGRAD - Estimates and corrects the intensity gradient, using a polynomial model
%
% [Int pol] = estPolIntGrad(inp, N, logFlag);
%
% Inputs:
%  inp - input inplanes affected by the intensity gradient
%  N - order of the polynomial [Nx Ny Nz]
%  logFlag - operates in the logarithm of the intensity
%

if ~exist('N')
   N = [3,3,3];
end
if ~exist('logFlag')
   logFlag = 1;
end

[Ny, Nx, Nz] = size(inp);
inp(find(inp==0)) = NaN;

% chosing appropriate thresholds
II = find(~isnan(inp));
% fitting a GMM
inpMu = mean(inp(II));
inpStd = std(inp(II));
outlim = [min(inp(II)) max(inp(II))];
initCov(1,1,1) = inpStd^2/4;
size(initCov)
[Mu Cov W] = fitGMM(inp(II)', 1, inpMu+2.5*inpStd, initCov, [0.9 0.1], outlim);
%initmu = [inpMu-2*inpStd inpMu+2.5*inpStd];
%initCov(:,:,1:2) = 2*inpStd^2;
%initW = [0.45 0.45 0.1];
%outlim = [min(inp(II)) max(inp(II))];
%[Mu Cov W] = fitGMM(inp(II)', 2, initmu, initCov, initW, outlim);

[hh xx] = hist(inp(II),256);
hh = hh/sum(hh)/(xx(2)-xx(1));
p1 = W(1)*pgauss1d(xx,Mu(1),Cov(:,:,1));
%p2 = W(2)*pgauss1d(xx,Mu(2),Cov(:,:,2));
p3 = W(2)/(max(inp(II))-min(inp(II))) * ones(size(p1));
figure(20); clf
plot(xx,hh,xx,p1+p3)

% chosing as thresholds mu2+-2std2
LoT = Mu(1) - 3*sqrt(Cov(:,:,1))
UpT = Mu(1) + 3*sqrt(Cov(:,:,1))
inp(find( (inp<LoT) | (inp>UpT) )) = NaN;

figure(20)
hold on
stem([LoT UpT], [max(hh),max(hh)]);
hold off

% Change polynomial order to be 2 less than number of non-NaN slices
NzEff = 0;
for k=1:Nz
    tmp = inp(:,:,k);
    if ~all(isnan(tmp(:)))
        NzEff = NzEff + 1;
    end
end
N(3) = min(max(1,NzEff-2), N(3));

% taking logarithm
if logFlag
   inp = log(inp);
end

% selecting valid set of indices
II = find(~isnan(inp));

% building A matrix for the appropriate polynomial order
[x y z] = meshgrid(1:Nx,1:Ny,1:Nz);
A = [];
for m=0:N(1)
  for n=0:max(0,(N(2)-m))
    for o=0:max(0,(N(3)-m-n))
         A = [A x(II).^m .* y(II).^n .* z(II).^o];
      end
   end
end
clear x y z
   
% robust estimation of the polynomial coefficients
% NOTE - The values of the last two parameters in this function can affect the
% performance of the solution. In general, the recommended value for CB = 4.685
% is very conservative with outliers (almost nothing is considered outlier). 
% For this reason I choose a value of 2.5. I also set a bit lower the value of SC
% (1.2 instead of 1.4), so that more outliers are rejected.
[p w]= robustMest(A, inp(II), 3, 1.2);
w3 = zeros(size(inp));
w3(II) = w;

% computation of the intensity correction
il = zeros(Ny,Nx,Nz); k=1;
[x y z] = meshgrid(1:Nx, 1:Ny, 1:Nz);
for m=0:N(1)
  for n=0:max(0,(N(2)-m))
    for o=0:max(0,(N(3)-m-n))
         il = il + p(k)*x.^m.*y.^n.*z.^o;
         k = k+1;
      end
   end
end

if logFlag
   Int = exp(il);
else
   Int = il;
end

mask = zeros(size(inp));
mask(II) = 1;

return

clear
load testdata
[Int, p, mask, w3] = estPolIntGrad(inp, [3 3 1], 1);
inpc = inp./Int;
sinpc = reshape(inpc, [size(inp,1) size(inp,2)*size(inp,3)]);
figure(1)
subplot(4,1,1)
vis(inp)
subplot(4,1,2)
imshow(sinpc, [0.5 1.5], 'notruesize')
subplot(4,1,3)
vis(Int.*mask)
subplot(4,1,4)
vis(w3)
figure(2)
II = find((inpc~=0)&(~isnan(inpc)));
hist(inpc(II),256)
