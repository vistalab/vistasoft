function [vol, ext, endian] = er_ldtvolume(stem,ext)
% [vol ext endian] = er_ldtvolume(stem,<ext>)
%
% Loads a volume in tSeries format and returns a 4D structure
% of dimension Nslices X Nrows X Ncols X Ndepth (where Ndepth = # of
% temporal frames).
%
% stem should be the path where a bunch of tSeries are stored. E.g.:
% stem = 'X:\mri\mySession\Inplane\Original\tSeries\Scan1'. Within this
% directory the code looks for files named 'tSeries[#].mat', the default
% format for mrLoadRet. 
%
% 'ext' is currently a dummy param, but since some older tSeries are saved
% as .dat files, maybe I'll make it work.
%
% '$Id: er_ldtvolume.m,v 1.1 2004/03/11 01:29:55 sayres Exp $'
%
% 06/18/03 ras: created from fmri_ldbvolume in an attempt to integrate
% fsfast into mrLoadRet.

vol = [];
ext = 'tSeries';
endian = 0;

if(nargin ~= 1 & nargin ~= 2)  
  fprintf(2,'USAGE: er_ldtvolume(stem,<ext>)\n');
  qoe; error; return;
end

% First, check whether tSeries are in stem path %
test = filterdir('tSeries',stem);
if isempty(test)
    fprintf(2,'Couldn''t find any tSeries in specified path!!!');
    qoe; error; return;
end

% count slices
nslices = size(test);

% fprintf('er_ldtvolume: found %d slices\n',nslices);
  
% concatenate into volume
for slice = 1:nslices
  % fprintf('Loading Slice %3d\n',slice);
  fname = fullfile(stem,['tSeries' num2str(slice) '.mat']);

  if ~exist(fname,'file')
      warning(['Could not find file ', fname]);
  end
  
  z = er_ldtfile(fname);
  if(size(z,1) == 1 & size(z,3) == 1)
    vol(slice,:,:)  = z;
  else
    vol(slice,:,:,:) = z;
  end
end

return;
