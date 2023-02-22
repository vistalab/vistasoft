function [Timg, tThreshFDR, n_signif,index_signif, pvals] = dtiTTestImage(Tvalues, DISTR, df, mask)
%
% Basic interpretations of the dtiTTest results to produce images and other
% values related to false discovery rate
%
%  [Timg, tThreshFDR, n_signif,index_signif, pvals] = ...
%         dtiTTestImage(Tvalues, DISTR, df, mask)
%


% Create an image of the results
Timg = dtiIndToImg(Tvalues, mask, NaN);

% When you view the montage, this sets how many slices we use.
% showSlices = [20:60];
% showSlices = [10:50];
% All the brain containing slices
% showSlices = [25:50];  % Small number for debugging
% showSlices = [15:62]; 
% figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap cool; colorbar;
% set(gcf,'Name','FA test'); title(sprintf('tthresh, no FDR (p<10^-^4) = %0.1f',tThresh));


% Figure out the statistical significance now.
tThresh = tinv(1-10^-4, df(1));
tMax = tinv(1-10^-12, df(1));
Timg(abs(Timg)>tMax) = tMax;
tMax = max(Timg(:));
        
% Perform an FDR analysis for the FA test
%
fdrVal = 0.05;   % This is the p-value we are using.
fdrType = 'general';
Tvalues(isnan(Tvalues)) = 0;
pvals = 1-tcdf(Tvalues, df(1));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');

% Convert back to an fThreshold.  Needs more comments.  We think that this
% function returns the t-value needed to achieve a significance fdrVal, say
% 0.05 or 0.01.  It is possible that tThreshFDR/tMax is the fThreshold,
% though the comment in the printf doesn't say that.  It just puts the
% value in a parenthesis.
if n_signif > 0
    tThreshFDR = tinv(1-max(pvals(index_signif)), df(1));
    fprintf('t-threshold for FDR (%s) when p < %0.3f: %0.2f (%0.3f).\n',...
        fdrType,fdrVal,tThreshFDR,tThreshFDR/tMax);
else
    tThreshFDR = [];
    fprintf('Nothing returned as significant');
end

return;