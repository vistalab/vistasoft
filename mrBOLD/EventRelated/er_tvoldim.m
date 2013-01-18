function [nslices, nrows, ncols, nt, endian, ext, hdrdat] = er_tvoldim(stem,slice)
% [nslices nrows ncols nt endian ext hdrdat] = er_tvoldim(stem,[slice])
% 
% stem is the path where tSeries for a given scan are located, e.g.
% 'X:\mri\mySession\Inplane\Original\tSeries\Scan1'.
%
% $Id: er_tvoldim.m,v 1.3 2004/10/13 22:45:56 sayres Exp $
%
% 06/18/03: created from fmri_bvoldim in an attempt to integrate fsfast
% functions into mrLoadRet. ras
% (assumes inplanes are square (e.g., 64 x 64). Can fix this using
% mrSESSION data but didn't want it to depend on external files, and think
% it's pretty unlikely there will be non-square inplanes. ras)
% 03/04 ras: I was wrong -- I forgot about cropping. Now needs a mrSESSION
% struct (used when running mrLoadRet). Will see if there's a better way to
% do this.
% 09/04 ras: updated: I'm trying to get this to work on gray and
% flat views now. I realize a better way to do this would be to
% rebuild with views passed from the ground up, but I'm going
% to continue the tradition of ugly hacks by inferring the 
% view type from the stem.
global mrSESSION dataTYPES;

if ieNotDefined('slice')
    slice = 1;
end

nslices = [];
nrows   = [];
ncols   = [];
nt      = [];
endian  = 0;
ext    = '.mat';
hdrdat  = [];

% count # of tSeries in stem directory
w = dir(fullfile(stem,'tSeries*.mat'));
if isempty(w)
    fprintf(2,'er_tvoldim: no tSeries files found in %s',stem);
    qoe;
    return
end
nslices = length(w);

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

fname = sprintf('%s.dat',stem);
fid = fopen(fname,'r');
if(fid ~= -1)
  fclose(fid);
  hdrdat = fmri_lddat3(fname);
end

return;
