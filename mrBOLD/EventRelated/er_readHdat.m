function hdrData = er_readHdat(hdatpath);
% hdrData = er_readHdat(hdatpath);
% reads in an FS-FAST h.dat file.
%
% 10/02 ras
% 03/04 ras: now just accespts the direct path as a single input arg.
if exist(hdatpath,'file') ~= 2
    % check if just the directory entered
    hdatpath = fullfile(hdatpath,'h.dat');
end

if ~exist(hdatpath,'file')
    error([hdatpath ' not found.']);
end


if exist(hdatpath,'file')
  fidH = fopen(hdatpath,'r');
  % conditions count is on ninth line -- ignore first 8

  % scan through text 'TR'
  fscanf(fidH,'%s',1);  
  hdrData.TR = fscanf(fidH,'%i',1);
  fgetl(fidH);

  % scan through text 'TimeWindow'
  fscanf(fidH,'%s',1);  
  hdrData.timeWindow = fscanf(fidH,'%i',1);
  fgetl(fidH);

  % scan through text 'TPreStim'
  fscanf(fidH,'%s',1);  
  hdrData.tPreStim = fscanf(fidH,'%i',1);
  fgetl(fidH);

  % scan through text 'nCond'
  fscanf(fidH,'%s',1);
  hdrData.nConds = fscanf(fidH,'%i',1);
  fgetl(fidH);
  
  % next 4 lines are not very useful -- ignore
  for i = 1:4
    fgetl(fidH);
  end
  
  % scan through text 'Npercond'
  fscanf(fidH,'%s',1);
  for i = 1:hdrData.nConds
    hdrData.trialsPerCond(i) = fscanf(fidH,'%i ',1);
  end
  fclose(fidH);
else
    error(['ERROR: couldn''t find h.dat file ',hdatpath]);
end

return