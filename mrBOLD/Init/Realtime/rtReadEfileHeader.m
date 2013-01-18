function functionals = rtReadEfileHeader(magFile)
% function functionals = rtReadEfileHeader(magFile);
%
% Reads Efile headers for pseudo-realtime. Based on
% LoadScanParams, but loads a single E-file at a time.
%
% Takes as input argument a path to the mag file
% associated w/ the header, and looks for a corresponding
% E-file.
%
% ras 04/05

functionals = [];
[magDir fname] = fileparts(magFile);

% Find associated E-file
magNum = str2num(fname(2:6));
pattern = sprintf('E*%s',fname(1:8));
w = dir(fullfile(magDir,pattern));
if isempty(w)
    error('Couldn''t find an associated E-file header!');
else
    eFile = w(1).name;
end

name = fullfile(magDir, eFile);
hdr = ReadEfileHeader(name);

functionals.PfileName = fname;
functionals.totalFrames = hdr.nframes;
fullname=hdr.name;
% Split this into first and last
spaceLocation=findstr(fullname,' ');
if(spaceLocation)
  functionals.firstName=[fullname(1:(spaceLocation-1))];
  functionals.lastName=[fullname((spaceLocation+1):end)];
else
  functionals.firstName='';
  functionals.lastName=fullname;
end

functionals.date=hdr.date;
functionals.time=hdr.time;

functionals.junkFirstFrames = 0;
functionals.nFrames = hdr.nframes;
functionals.slices = [1:hdr.slquant];
functionals.fullSize = [hdr.imgsize, hdr.imgsize];
functionals.cropSize = [];
functionals.crop = [];
dxy = hdr.FOV / hdr.imgsize;
functionals.voxelSize = [dxy, dxy, hdr.sliceThickness];
effRes = hdr.FOV/hdr.equivMatSize;
functionals.effectiveResolution = [effRes, effRes, hdr.sliceThickness];
functionals.framePeriod = hdr.tAcq/1000;
functionals.reconParams = hdr;

return