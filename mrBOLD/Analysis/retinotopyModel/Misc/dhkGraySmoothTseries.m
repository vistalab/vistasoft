function dhkGraySmoothTseries(v)
% dhkGraySmoothTseries - just that
%
% 2008/04 SOD: wrote it.

if ~exist('v','var') || isempty(v), error('Need view'); end
if ~strcmp(v.viewType,'Gray'), error('Need gray view'); end

ns = viewGet(v,'numscans');
weight = [];
iterlambda = [9 0.5]; % 3mm fwhm

for scan=1:ns,
    tSeries = loadtSeries(v,scan,1);
    [tSeries weight] = dhkGraySmooth(v,tSeries,iterlambda,weight);
    savetSeries(tSeries,v,scan,1);
end

