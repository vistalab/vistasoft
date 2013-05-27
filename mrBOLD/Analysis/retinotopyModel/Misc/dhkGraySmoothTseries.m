function dhkGraySmoothTseries(vw)
% dhkGraySmoothTseries - just that
%
% 2008/04 SOD: wrote it.

if ~exist('vw','var') || isempty(vw), error('Need view'); end
if ~strcmp(viewGet(vw,'View Type'),'Gray'), error('Need gray view'); end

ns = viewGet(vw,'numscans');
weight = [];
iterlambda = [9 0.5]; % 3mm fwhm

for scan=1:ns,
    tSeries = loadtSeries(vw,scan,1);
    [tSeries, weight] = dhkGraySmooth(vw,tSeries,iterlambda,weight);
    %This should not need any change since this can only work for a Gray
    %view
    savetSeries(tSeries,vw,scan,1);
end

