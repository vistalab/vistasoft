function vw = importRetModelFit(vw, srcRmPath, outFileName)
% importRetModelFit - Import parameter map  from another session into the selected
% data type / scan for the current session. Only works for Volume / Gray
% views, and for sessions which share a common volume anatomy.
%
% vw = importRetModelFit(<vw>, <srcMapPath>, <outFileName>);
% 
% If any of the latter three arguments are omitted, pops up a dialog.
% srcMapFile: path to map file to import
% outFileName: filename for imported model (fname only, not full path)
%
% sod, 06/06 copied from ras' importMap

if notDefined('vw'),    vw = getSelectedGray;       end

if ~ismember(vw.viewType, {'Volume' 'Gray'})
    error('Sorry, only Volume/Gray Views for now.')
end

mrGlobals;


if notDefined('srcRmPath')
    startDir = fullfile(fileparts(pwd), vw.viewType);
    [f p] = myUiGetFile(startDir, '*.mat', 'Select a retModel to import');
    srcRmPath = fullfile(p,f);
    %srcSession = fileparts(fileparts(fileparts(p)));
end
srcSession = fileparts(fileparts(fileparts(srcRmPath)));

% load source mrSESSION file
src = load(fullfile(srcSession,'mrSESSION.mat'));

% check that an appropriate map file exists, and if so, load it
if ~exist(srcRmPath, 'file')
    error('%s not found.', srcRmPath);
else
    load(srcRmPath, 'model', 'params');
end
    
% load source coords, find indices of those
% coordinates contained within view's coords
% disp('Checking source and target coordinates...')
srcCoordsFile = fullfile(srcSession, vw.viewType, 'coords.mat');
load(srcCoordsFile, 'coords');
[commonCoords, Isrc, Itgt] = intersectCols(coords, vw.coords);
nVoxels = size(vw.coords, 2);


% loop over models
% now reshape important params
fnames = {'exponent',...
          'x', 'y', ...
          'sigmamajor', 'sigmaminor', 'sigmatheta',  ...
          'sigma2major', 'sigma2minor', 'sigma2theta', ...
          'b', ...
          'tf', 'trm', 'tall', 'trmf', ...
          'rss' 'rawrss'};
waitHandle = mrvWaitbar(0,'Interpolating model.  Please wait...');
for m = 1:length(model),
  % and reshape each one of them
  for f = 1:length(fnames),
    mrvWaitbar(((m-1).*length(model)+f) ./ (length(model).*length(fnames)));
    % get old
    paramOld = rmGet(model{m},fnames{f});
    if prod(size(paramOld)) > 1 & isnumeric(paramOld),
      % swap coords
      if size(paramOld,3) == 1,
        % initiate new and fill
        paramNew = zeros(size(paramOld,1),nVoxels);
        paramNew(Itgt) = paramOld(Isrc);
      else
        % initiate new and fill
        paramNew = zeros(size(paramOld,1),nVoxels,size(paramOld,3));
        paramNew(1,Itgt,:) = paramOld(1,Isrc,:);
      end;
      % reset
      model{m} = rmSet(model{m},fnames{f},paramNew);
    end;
  end;
end;
close(waitHandle)


% save the results
if notDefined('outFileName')
    [p f] = fileparts(srcRmPath);
    outFileName = fullfile(dataDir(vw), sprintf('rmImported_%s.mat', f));
    [f,p] = uiputfile(outFileName,'Please select filename');
else
    p = dataDir(vw); f = outFileName;
end
pathStr = fullfile(p,f);
save(pathStr,'model','params');
fprintf(1,'[%s]:Saved %s.\n',mfilename,pathStr);  
return;
