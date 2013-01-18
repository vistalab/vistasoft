function vw = makeAreaROI(vw, atlasValue, phaseRange, roiColors)
%
%   vw = makeAreaRoi(vw, [atlasValue], [phaseRange], [roiColors])
%
% Creates a ROI from an Atlas area mask.
%
% The user will be prompted for params if the maskImg is not passed in.
% 
% HISTORY:
%   2002.04.01 RFD (bob@white.stanford.edu): wrote it.

if ieNotDefined('roiColors'), roiColors = 'cmbmc'; end
    
ringWedgeScans = readRingWedgeScans; 
ringScanNum = ringWedgeScans(1);

slice = viewGet(vw, 'Current Slice');

hemisphere = slice;
if(hemisphere==1)
    hemiString = 'left';
else
    hemiString = 'right';
end

[atlasView,atlasTypeNum] = getAtlasView;
if(isempty(atlasView))
    myErrorDlg('Sorry- there are no Atlas FLAT windows open.');
else
    maskImg = atlasView.co{1}(:,:,slice);
end

if(~exist('atlasValue') | isempty(atlasValue))
    options = unique(round(maskImg(~isnan(maskImg))));
    if(length(options)>20) myErrorDlg('Too many unique values in mask image!'); end
    if(length(options)<=0) myErrorDlg('There are no unique values in mask image!'); end
    if(length(options)==1 )
        % If there is only one option, then there are no options. ;)
        atlasValue = options;
    else
        for(ii=1:length(options)) optionsText{ii} = num2str(options(ii)); end
        resp = buttondlg('Select atlas value for ROI', optionsText);
        if(isempty(resp)) 
            myErrorDlg('No values selected- aborting.');
        else
            atlasValue = options(find(resp));
        end
    end
end

if(~exist('phaseRange') | isempty(phaseRange))
    prompt = {'Lower Phase Limit (fovea is 0):', 'Upper Phase Limit (furthest extent is 2*pi):'};
    default = {'0', '2*pi'};
    answer = inputdlg(prompt, 'Phase Limit', 1, default, 'on');
    if ~isempty(answer)
        phaseRange(1) = str2num(answer{1});
        phaseRange(2) = str2num(answer{2});
    else
        phaseRange = [0,2*pi];
    end
end

global dataTYPES;

% atlasTypeNum = dtGetCurNum(atlasView);
% phaseShift = dataTYPES(atlasTypeNum).atlasParams(ringScanNum).phaseShift(hemisphere);
% ringImg = atlasView.ph{ringScanNum}(:,:,slice);
% ringImg = mod(ringImg - phaseShift, 2*pi);
% lower = phaseRange(1);
% upper = phaseRange(2);
% maskImg(~(ringImg>=lower & ringImg<=upper)) = NaN;
%
maskImg = round(maskImg);

for(ii=1:length(atlasValue))
    % The following line does all the hard work.
    [x,y] = ind2sub(size(maskImg), find(abs(maskImg-atlasValue(ii))<0.5));

    %select = 1;
    %vw = newROI(vw, roiName, select, roiColor);

    ROI.name = [hemiString,'_area ',num2str(atlasValue(ii))];
    ROI.color = roiColors(mod(ii-1,length(roiColors))+1);
    ROI.coords = [x,y,repmat(slice,size(x))]';
    ROI.viewType = vw.viewType;

    vw = addROI(vw, ROI);
end
refreshView(vw);

return;

% debug
vw = FLAT{2};
atlasValue = 1;
maskImg = vw.co{1}(:,:,1);