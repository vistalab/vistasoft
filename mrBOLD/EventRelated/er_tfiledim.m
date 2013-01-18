function [nrows, ncols, ntp, fs, ns, endian, bext] = er_tfiledim(stem,slice)
% [nrows ncols ntp fs ns endian bext] = er_tfiledim(stem,slice)
%
% $Id: er_tfiledim.m,v 1.3 2004/10/13 22:45:55 sayres Exp $
%
% 06/18/03 ras: created from fmri_bfiledim in an attempt to integrate
% fsfast into mrLoadRet
% (assumes inplanes are square (e.g., 64 x 64). Can fix this using
% mrSESSION data but didn't want it to depend on external files, and think
% it's pretty unlikely there will be non-square inplanes. ras)
% 09/04 ras: updated: I'm trying to get this to work on gray and
% flat views now. I realize a better way to do this would be to
% rebuild with views passed from the ground up, but I'm going
% to continue the tradition of ugly hacks by inferring the 
% view type from the stem.
% 10/04 ras: now has optional slice arg; for flat views, the
% # voxels varies with the 'slice' (which refers to flat levels
% and hemispheres, so this makes sense)
global mrSESSION

if ieNotDefined('slice')
    slice = 1;
end

nrows   = [];
ncols   = [];
ntp     = [];
fs      = 1;
ns      = [];
endian  = 0;
bext    = '.mat';

stem = deblank(stem);

w = filterdir('tSeries',stem);
if isempty(w)
    fprintf(2,'er_tvoldim: no tSeries files found in %s',stem);
    qoe;
    return
end
ns = length(w);

% load a test tSeries to figure out the # time points
testpath = fullfile(stem,sprintf('tSeries%i.mat',slice));
load(testpath,'tSeries');
nt = size(tSeries,1);
nvox = size(tSeries,2);

% figure out the view type from
% the stem -- do a recursive fileparts
viewType = stem;
for i = 1:3
    viewType = fileparts(viewType);
end
[ignore viewType] = fileparts(viewType);

if isequal(viewType,'Inplane') 
    nrows = mrSESSION.functionals(1).cropSize(1);
    ncols = mrSESSION.functionals(1).cropSize(2);
else
    nrows = 1;
    ncols = nvox;
end

return;