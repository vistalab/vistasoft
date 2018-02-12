function volume = rmIp2Vol(inplane,volume,method,forceSave);
% rmIp2Vol - tranform retinotopic model data Inplane -> Gray/Volume
%
%  volume = rmIp2Vol(inplane,volume);
%

% After ip2volParMap and ip2volCorAnal
% 2006/02 SOD : wrote it.

% input checks and defaults
if ieNotDefined('inplane'),    error('Need inplane structure.'); end;
if ieNotDefined('volume'),     error('Need volume structure.');  end;
if ieNotDefined('method'),     method = 'linear';                end;
if ieNotDefined('forceSave'),  forceSave = 0;                    end;
disp(sprintf('[%s]: using %s interpolation.',mfilename,method));
global mrSESSION;

% Don't do this unless inplane is really an inplane and volume is really a volume
if ~strcmp(inplane.viewType,'Inplane')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end
if ~strcmp(volume.viewType,'Volume') &~strcmp(volume.viewType,'Gray')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end
% Check that both inplane & volume are properly initialized
if isempty(inplane)
    myErrorDlg('Inplane view must be open.  Use "Open Inplane Window" from the Window menu.');
end
if isempty(volume)
    myErrorDlg('Gray/volume view must be open.  Use "Open Gray/Volume Window" from the Window menu.');
end

% wait bar
waitHandle = mrvWaitbar(0,'Interpolating model.  Please wait...');


% Compute the transformed coordinates (i.e., where does each gray node fall in the inplanes).
nVoxels          = size(volume.coords,2);
coords           = double([volume.coords; ones(1,nVoxels)]);
vol2InplaneXform = inv(mrSESSION.alignment);
vol2InplaneXform = vol2InplaneXform(1:3,:);
coordsXformedTmp = vol2InplaneXform*coords;
coordsXformed    = coordsXformedTmp;

rsFactor = upSampleFactor(inplane,1);
if length(rsFactor)==1
  coordsXformed(1:2,:)=coordsXformedTmp(1:2,:)/rsFactor;
else
  coordsXformed(1,:)=coordsXformedTmp(1,:)/rsFactor(1);
  coordsXformed(2,:)=coordsXformedTmp(2,:)/rsFactor(2);
end


% get/load selected file
try,
  rmFile = viewGet(inplane,'rmFile');
catch,
  disp(sprintf('[%s]:Please select file',mfilename));
  inplane = rmSelect(inplane);
  rmFile  = viewGet(inplane,'rmFile');
end;
load(rmFile,'model','params');

% now reshape important params
fnames = {'x','y',...
          'sigmamajor','sigmaminor','sigmatheta',...
          'sigma2major','sigma2minor','sigma2theta',...
          'b',...
          'tf','trm','tall','trmf',...
          'rss' 'rawrss'};
dimSize = prod(viewGet(inplane,'datasize'));
for m = 1:length(model),
  for f = 1:length(fnames),
    mrvWaitbar(((m-1).*length(model)+f) ./ (length(model).*length(fnames)))
    paramInplane = rmGet(model{m},fnames{f});
    if prod(size(paramInplane)) > 1 & isnumeric(paramInplane),
      switch lower(fnames{f})
       case 'b', 
        % could do in one step but I'm concerned about the
        % ordering
        for ii = 1:size(paramInplane,4),
          newparam(1,:,ii) = interp3(paramInplane(:,:,:,ii),...
                                     coordsXformed(2,:),...
                                     coordsXformed(1,:),...
                                     coordsXformed(3,:),...
                                     method);
        end;
        paramVolume = newparam;
        
       otherwise,  
        paramVolume = interp3(paramInplane,...
                              coordsXformed(2,:),...
                              coordsXformed(1,:),...
                              coordsXformed(3,:),...
                              method);
      end;
      model{m} = rmSet(model{m},fnames{f},paramVolume);
    end;
  end;
end;
close(waitHandle)

% now save output 
[p outputname] = fileparts(rmFile);
pathStr        = fullfile(dataDir(volume),outputname);

% overwrite?
if exist(pathStr,'file') & forceSave == 0,
    saveFlag = questdlg([pathStr,' already exists. Overwrite?'],...
        'Save model file?','Yes','No','No');
else
    saveFlag = 'Yes';
end

% save
if strcmp(saveFlag,'Yes')
    save(pathStr,'model','params');
    volume = viewSet(volume,'rmFile',pathStr);
    fprintf(1,'[%s]:Saved %s.\n',mfilename,pathStr);
else
    fprintf(1,'[%s]:Model not saved.\n',mfilename);
end
return;


