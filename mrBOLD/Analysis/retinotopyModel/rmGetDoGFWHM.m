function [fwhmax,surroundSize,fwhmin_first, fwhmin_second, diffwhmin] = rmGetDoGFWHM(model,ROIindex)
% rmGetDoGFWHM - get various summary statistics from DoG model
%
% [fwhmax, fwhmin, difwhmin, minima, positiveArea, totalArea] = rmGetDoGFWHM(model,ROIindex)
% ROIindex can contain either logicals or the indices indicating the values of the ROI (optional)
%
% Determines the value of full-width half max of the positive part of the
% difference of gaussian model, and other measures of negative gaussian:
% fwhmax        : full-width-half-max
% surroundSize  : full-width between full minima (if below zero)
% fwhmin_first  : full-width at 1st half-min (if below zero)
% fwhmin_first  : full-width at 2nd half-min (if below zero)
% difwhmin      : difference in widths between 1st and 2nd half-min crossings (if below zero)
%
%
% BMH  10/10: Wrote it, with help from WZ
% SOD & BK 02/12: Commenting
% WZ 02/12 updated

stepsize=0.01; %Fineness of modelled curve increments. Larger values give faster calculation, smaller values are more accurate.

sigma = model.sigma.major;
sigma2 = model.sigma2.major;
beta1 = model.beta(1,:,1);
beta2 = model.beta(1,:,2); 

if exist('ROIindex','var') && ~isempty(ROIindex)
    sigma = sigma(ROIindex{1});
    sigma2 = sigma2(ROIindex{1});
    beta1 = beta1(ROIindex{1});
    beta2 = beta2(ROIindex{1});
end

fwhmax=zeros(size(sigma2)); %Full-width half-max
surroundSize=zeros(size(sigma2)); %full-width between full minima (if below zero)
fwhmin_first=zeros(size(sigma2)); %full-width at 1st half-min (if below zero)
fwhmin_second=zeros(size(sigma2)); %full-width at 2nd half-min (if below zero)
diffwhmin=zeros(size(sigma2)); %difference in widths between 1st and 2nd half-min crossings (if below zero)


x=single([]);
y=single([]);

for k =1:numel(sigma2)
    if sigma(k)>0   
          x = 0:stepsize:3*max([sigma2(k) sigma(k)]);
          if sigma2(k)>0
              y = beta1(k).*exp((x.^2)./(-2*(sigma(k).^2)))+beta2(k).*exp((x.^2)./(-2*(sigma2(k).^2)));
          else
              y = beta1(k).*exp((x.^2)./(-2*(sigma(k).^2)));
          end
          
          isHalf = y < max(y)/2;
          ind = find(isHalf, 1, 'first');      % point where it is fwhmax
          pointZero = x(ind);
          if isempty(pointZero)
              pointZero=0;
          end
          fwhmax(k) = pointZero;
          
          [minval, minind]=min(y);

          if minval<0
              surroundSize(k)=x(minind);
              
              isNeg = y < minval/2;
              firstNeg=find(isNeg, 1, 'first');     % first point where it is fwhmin
              
              fwhminind = [firstNeg  find(isNeg, 1, 'last')];   % second point where it is fwhmin
              fwhmin_first(k)=x(fwhminind(1));
              fwhmin_second(k)=x(fwhminind(2));
              diffwhmin(k) = fwhmin_second(k)-fwhmin_first(k);
          
          else 
              surroundSize(k)=0; %or NaN           % there is no negative surround, so do not take these values into account 
              fwhmin_first(k) = 0;
              fwhmin_second(k) = 0;
              diffwhmin(k) = 0;
          end
              
            
    end
end

%Double all values to get results for whole gaussian. Calculations only for
%half gaussian
fwhmax=fwhmax.*2;
surroundSize=surroundSize.*2;
fwhmin_first = fwhmin_first.*2;
fwhmin_second = fwhmin_second.*2;
diffwhmin = diffwhmin.*2;
return

