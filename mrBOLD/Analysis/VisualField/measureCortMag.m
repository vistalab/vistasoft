function view = measureCortMag(view, roiList, paramsFile)
% 
% USAGE: view = measureCortMag(view, [roiList], [paramsFile])
%
%   view: can be either flat or gray. 
%
%   roiList: a list of ROI indices specifying which ROIs to
%            use for the cortMag. Defaults to all ROIs.
%
%   paramsFile: a .mat file into which the parms will be saved.
%               If the file exists, it will be read in and those 
%               params used as a starting point.
%   
% PURPOSE:
%   Compute cortical magnification measurements.
%
% NOTE:
%   This code assumes that the ROI coords have been sorted such that the fovea
%   is at the beginning of the list! If you generate your ROIs with mrFindAreas,
%   you will be fine (it sorts the coords for you). If you draw them with the 
%   'create line ROI' tool, you should be OK as long as you start all your lines
%   in the fovea. Otherwise, you are on your own.
%
% FIX THESE ISSUES:
%   * The inter-bin distance should be computed via paths only through layer 1.
%   * The inter-bin distance is currently computed from the bin edge, not the bin center.
%     This won't affect the distance measures, but it does bias the mean phase estimate
%     for each bin. It is tricky to adjust for this- the bins are not regularly spaced.
%
% HISTORY:
%   2002.01.22 RFD (bob@white.stanford.edu): wrote it, porting some
%   code from mrLoadRet-2.5. However, I've taken a fresh start and attempted
%   to streamline things and make them more modular.
%
% 7/16/02 djh, replaced mrSESSION.vAnatomyPath with global vANATOMYPATH


% We need vANATOMYPATH and mrSESSION.subject
global vANATOMYPATH;
global mrSESSION;
global dataTYPES;

if(~exist('roiList','var') | isempty(roiList))
    % default to all
    roiList = [1:length(view.ROIs)];
end

% We currently only support Flat view. All analyses are performed on
% flat view ROIs that _should_ be created by an atlas fit.
%
switch(view.viewType)
case {'Inplane','Volume','Gray'}
    error([mfilename,' doesn''t work for ',view.viewType,'.']);
case 'Flat'
    % Get a gray structure because we need the gray nodes.
    grayView = getSelectedGray;
    if isempty(grayView)
        grayView = initHiddenGray;
    end
    cortMag.ROIs = view.ROIs(roiList);
otherwise
    error([view.viewType,' is unknown!']);
end

if(~exist('paramsFile','var') | ~exist(paramsFile,'file'))
    cortMag.paramsFileName = [];
    nowNum = now;
    cortMag.subject = mrSESSION.subject;
    cortMag.timestamp = datestr(nowNum);
    cortMag.mmPerPix = readVolAnatHeader(vANATOMYPATH);
    cortMag.coThresh = getCothresh(view);
    cortMag.expNumber = getCurScan(view);
    cortMag.nodeIndices = {};
    cortMag.bins = {};
    cortMag.dataType = getDataTypeName(view);
    cortMag.subdir = view.subdir;
    % This is a crude method for determining the hemisphere- but it usually works.
    if(cortMag.ROIs(1).coords(3,1)==1) 
        cortMag.hemisphere = 'left';
        cortMag.slice = 1;
    else
        cortMag.hemisphere = 'right';
        cortMag.slice = 2;
    end
    
else
    % this file _should_ contain a cortmag struct.
    % Note that this file, if it exists, will form the starting point.
    % We will overwrite many of it's fields below.
    tmp = load(paramsFile);
    if(isfield(tmp,'cortMag'))
        cortMag = tmp.cortMag;
    else
        warning(['Params file "',paramsFile,'" exists, but it does '...
                'not contain a cortMag struct! It will be ignored.']);
    end
    % Just in case the paramsFileName is not correct:
    cortMag.paramsFileName = paramsFile;
    % If we were really cool, we'd check the validity of the loaded cortmag struct.
end


% Make sure that the correct data is loaded in the grayView
grayView.curDataType = existDataType(cortMag.dataType);
grayView = loadCorAnal(grayView);

if(isempty(cortMag.paramsFileName))
    cortMag.paramsFileName = ['CortMag_',cortMag.subdir,'_',cortMag.dataType,'_',cortMag.hemisphere,'_',...
            datestr(nowNum,11),datestr(nowNum,5),datestr(nowNum,7),'.mat'];
end

% At this point, we have a gray struct and we have a set of ROIs in flat coordinates.
% Note that the ROI coords are assumed to be sorted already (with the fovea at the  
% beginning of the list).

% Now, we should call a function that computes cortmag. But, I'd like to keep all UI code
% here, so we'll do it like this:

satisfied = 0;
while(~satisfied)
    resp = getCortMagParams(cortMag);
    if(~isstruct(resp) & resp==0)
        % a 0 means the user cancelled- they are aborting or are satisfied
        satisfied = 1;
    else
        % if it's not 0, then it's an updated cortMag struct
        oldCortMag = cortMag;
        cortMag = resp;
     
        % Finding the nodes for each coordinate in all the ROIs is slow. Once we do it, we
        % needn't do it again unless we get a new ROI added to the list. That is, none of the
        % cortMag parameters will affect the nodes that are found. So, we don't need to redo it
        % if a parameter changes.
        if(isempty(cortMag.nodeIndices))
            cortMag = buildCortMagNodes(cortMag, view, grayView);
            cortMag.bins = [];
        end
        % Finding the bins is somewhat slow. We only really need to redo it if the binSize changes.
        if( isempty(cortMag.bins) | cortMag.binDist ~= oldCortMag.binDist ...
            | cortMag.expNumber ~= oldCortMag.expNumber | cortMag.flatDataFlag ~= oldCortMag.flatDataFlag)
            cortMag = buildCortMagBins(cortMag, view, grayView);
            if(strmatch('Atlases', dataTYPES(view.curDataType).name))
                phaseScale = dataTYPES(view.curDataType).atlasParams(cortMag.expNumber).phaseScale(cortMag.slice);
                phaseShift = dataTYPES(view.curDataType).atlasParams(cortMag.expNumber).phaseShift(cortMag.slice);
                fprintf('Fixing atlas phases with shift (%.2f) and scale (%.2f)...', phaseShift, phaseScale);
                for(ii=1:length(cortMag.data))
                    cortMag.data{ii}.ph = mod((cortMag.data{ii}.ph - phaseShift) / phaseScale, 2*pi);
                end
            end
        end
        cortMag = computeCortMagFunction(cortMag, view, grayView);
        plotCortmagResults(cortMag);
    end
end

view.cortMag = cortMag;
if(~isempty(cortMag.paramsFileName))
    %if(~exist(cortMag.paramsFileName,'file') | strcmp(questdlg('Overwrite existing cortMag file?', 'Overwrite?', 'Yes', 'No', 'Yes'),'Yes'))
    if(exist(cortMag.paramsFileName,'file'))
        disp([cortMag.paramsFileName,' exists- launching gui to save it somewhere else.']);
        uisave({'cortMag'}, cortMag.paramsFileName);
    else
        save(cortMag.paramsFileName, 'cortMag');
        disp([cortMag.paramsFileName,' saved.']);
    end
end
return;


