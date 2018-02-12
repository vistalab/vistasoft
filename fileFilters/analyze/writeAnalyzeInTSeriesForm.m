function view = writeAnalyzeInTSeriesForm(view,scanList);
%
% view = writeAnalyzeInTSeriesForm(view,[scanList])
% 
% Could be for either INPLANE or VOLUME
% Transform the analyze format images into time series format.
% By definition, each analyze image corresponds to one time
% frame and is a 3D matrix.
% 
% scanList: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
%
% The user will identify, by GUI, where the source img files are, and where
% the tseries will be saved to.
%
% saveDir: if not given, then
%   ask a user to select a DataType or create a new DataType
%   save to 'Inplane/DataTypeName/TSeries_fromImgFiles/Scan*/TSeries*.mat'
% 
% SPM Matlab toolbox required.
%
% MA, 10/18/2004. Based on ana2ts.m
% JL, 11/8/2004. Reorganize a little bit

mrGlobals;

% Choose the img file source
sourceChoice = questdlg('Where are the Analyze format Files in ?','choose source file','Current DataType','Other DataType','I Choose!','Current DataType');
switch sourceChoice;
    case 'Current DataType';
        curDataDir = dataDir(view);
    case 'Other DataType';
        %%%% Pop out menu to let user choose datatype.
        dtCount = size(dataTYPES,2);
        for i=1:dtCount; dtList{i} = dataTYPES(i).name; end;
        [selDataType,ok] = listdlg('ListString',dtList, 'SelectionMode','single', ...
            'InitialValue',curDataType, 'Name','Please, select a DataType:','ListSize', [300,200]);
        if ok;
            curDataDir = fullfile(viewGet(view,'subdir'),dtList{selDataType});
        end
    otherwise
        curDataDir = pwd;
end
% If no dir found, ask user to identify.
sourceDir = fullfile(curDataDir,'TSeries_imgFiles');
if ~exist(sourceDir,'dir') | strcmp(curDataDir,pwd);
    if ~strcmp(curDataDir,pwd); % which means the user did not choose 'I Choose!'
        disp('Warning: cannot find TSeries_imgFiles/ in the dataType.');
    end
    sourceDir = 0;
    while sourceDir == 0;     % Must choose one
        sourceDir = uigetdir(curDataDir,'Please choose the folder containing Scan* subfolders that have Analyze format files');
    end
end

% In the sourceDir, there must be folders Scan1, Scan2, ... Scan*
% (Re-)set scanList
if ~exist('scanList','var'); % User choose #scans
    scanList = selectScans(view,'Choose scans with IMG-files to Xform',sourceDir);
elseif scanList == 0 % all scans available
    [nScans, fileNames] = countDirs('Scan*',sourceDir);
    scanList = 1:nScans;
elseif ~isnumeric(scanList) | isempty(scanList)
    myErrorDlg('Xform aborted');
end

% Now, choose target save location
targetChoice = questdlg('Where to save the Xform tSeries?','choose save location','Current DataType','I Choose!','I Choose!');
switch targetChoice;
    case 'Current DataType';
        targetDir = tSeriesDir(view);
        disp('Warning: The old tSeries of this datatype will be overwritten.');
    otherwise
        targetDir = 0;
        while targetDir == 0;     % Must choose one
            targetDir = uigetdir(pwd,'Please choose the folder where Xform-ed time series is saved to');
        end
        disp('Warning: The Xform-ed time series may not match the scan params of current dataType.');
end

% current DataType params:
curDataType = viewGet(view,'currentDataType');
dtName = dataTYPES(curDataType).name;
scanParams = dataTYPES(curDataType).scanParams;

%select analyze files:
nScans = length(scanList);
for scanIndex=1:nScans
    scanNum = scanList(scanIndex);
    scanDir = ['Scan',int2str(scanNum)];
	sourcePath = fullfile(sourceDir,scanDir);
	targetPath = fullfile(targetDir,scanDir);

    %get files:
    files = dir(fullfile(sourcePath,'*.img'));
    for iList = 1:size(files);
        fName = files(iList).name;
        pat = '^\d+.img'; % must start with number and end with .img
        [s f tag] = regexp(lower(fName),pat);
        if ~isempty(s);
            seqNo = str2num(fName(1:end-4));
            F(seqNo+1,:) = fullfile(sourcePath,files(iList).name);
        end
    end
%    dpos=findstr(F(1,:),FILESEP);
%	sourcePath=F(1,1:dpos(end));

    if ~exist('F','var');
        myErrorDlg(['writeAnalyzeInTSeriesForm did not find any ', sourcePath, ' *.img files']);
    end;
    
    if scanIndex == 1
        msg = ['Saving TSeries Files for ',scanDir,' in ',targetPath];
        disp(msg);
        waitHandle = mrvWaitbar(0,[msg, '. Please wait...']);
    end

	%load volumes
	V = spm_vol(F);

    %check sizes. If mismatch, if user chose current datatype to save to, then error
    %and quit, but if user chose any location to save to, then just warning.
    errorString = {[]};
    if scanNum > length(scanParams);
        errorString{1} = ['Scan # exceeds the total number of scans in current dataType.']
    end
    params = scanParams(scanNum);
    if size(V) ~= params.nFrames;
        errorString{2} = ['Number of img-files does not match to Number of Frames for current dataType.'];
    end
    if V(1).dim(1:2) ~= params.cropSize;
        errorString{3} = ['cropSize in img-files does not match for current dataType.'];
    end
    if V(1).dim(3) ~= size(params.slices,2)
        errorString{4} = ['Number of Slices in img-files does not match for current dataType.'];
    end
    for ierror = 1:length(errorString);
        if ~isempty(errorString{ierror});
            if strcmp(targetChoice, 'Current DataType');
                myErrorDlg(errorString{ierror});
            else
                disp(['Warning!: ',errorString{ierror}]);
            end
        end
    end
    
    if ~exist(targetPath,'dir'); mkdir(targetDir,scanDir); end;

    %go through slices
    nSlices = V(1).dim(3);
	for slice=1:nSlices
        %get slice signal
        tSeries = [];
        C=[1 0 0 0;0 1 0 0;0 0 1 -slice;0 0 0 1];
        for it=1:size(V,1)
            temp = squeeze( spm_slice_vol(V(it),inv(C),V(it).dim(1:2),0) );
            tSeries(it,:) = temp(:)';
        end
        fileName = ['tSeries',num2str(slice),'.mat'];
        fprintf('Save slice %d in %s\n', slice, fullfile(targetPath,fileName));
        save(fullfile(targetPath,fileName),'tSeries');
        msg = [scanDir, ': saved slice in ', targetPath];
        mrvWaitbar((scanIndex-1+slice/nSlices)/nScans, waitHandle, msg);
	end
end

disp(['TSeries Files saved to ',targetDir]);
close(waitHandle);

return
