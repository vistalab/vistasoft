function [vw, ROI] = makeROIsphere(vw, radius, centerCoord, name, select, color, addFlag)
%
%  [vw,ROI] = makeROIsphere(vw, [radius], [centerCoord], [name], [select], [color], [addFlag])
%
% Create a spherical ROI in the specified view (gray or volume). The ROI
% points are within 'radius' distance (in mm) from a selected point
% (centerCoord). If centerCoord is empty the user is prompted to select the
% point in the current view window.
%
% If requested, the ROI is returned.  This ROI can be used in other
% routines, such as vol2ipROI. 
%
% If you do not wish to add the ROI to the gray matter volume, set addFlag
% to 0.
%
% HISTORY:
% 2007.02.06 RFD wrote it, based on makeROIdiskGray and code from
% mrDiffusion.
%
% Examples:
%
%  VOLUME{1} = makeROIsphere(VOLUME{1},5,[],'test')
%  [ignoreMe, ROI] = makeROIsphere(VOLUME{1},5,[70,168,67],'test')
%

% get the resolution
mm = viewGet(vw, 'vol voxel size');

% Fill radius variable
if notDefined('radius')
   prompt={'Radius (mm)'}; def={'5'};lineNo=1;dlgTitle = 'add disk ROI';
   answer=inputdlg(prompt,dlgTitle,lineNo,def);
   if isempty(answer),  myErrorDlg('Canceling addROIdisk');
   else                 radius = str2num(answer{1});
   end
end
% fprintf('radius = %.0f\n',radius);

if notDefined('name'),     name=sprintf('sphere%.0f',radius); end
if notDefined('select'),   select=1; end
if notDefined('color'),    color='b'; end
if notDefined('addFlag'),  addFlag = 1; end

% if inplane view, create a temp volume view and transform
if isequal(vw.viewType, 'Inplane')
    if ~isequal(centerCoord, 'roi')
        error('Sorry, can only use an inplane view if you''re using the ROI option.');
    else
        hv = initHiddenVolume(vw.curDataType, vw.curScan);
        hv = ip2volCurROI(vw, hv);
        [hv,ROI] = makeROIsphere(hv, radius, centerCoord, name, 1, ...
                color, addFlag);
        vw = vol2ipCurROI(hv, vw);
        if select==1, vw.selectedROI = length(vw.ROIs); end
        return
    end
end


if notDefined('centerCoord')
    % Select figure and get a single point from the user
    figure(vw.ui.figNum)
    
    % Get mouse input
    % cannot do [x,y] = round(ginput(1)); Must round separately. Otherwise
    % matlab error. -- Junjie
    [x,y] = ginput(1);
    x = round(x); y = round(y);
    
    
    % Interpret mouse click according to current slice orientation
    curSlice = viewGet(vw, 'Current Slice');
    sliceOri = getCurSliceOri(vw);
    switch sliceOri
        case 1				% axi (y=cor pos, x=sag pos)
            centerCoord=[curSlice y x];
        case 2 				% cor (y=axi pos, x=sag pos)
            centerCoord=[y curSlice x];
        case 3 				% sag (y=axi pos, x=cor pos)
            centerCoord=[y x curSlice];
    end
    
elseif isequal(centerCoord, 'roi')
    % get start coord from center of current ROI
    coords = vw.ROIs(vw.selectedROI).coords;
    if(size(coords,2)==1)
        centerCoord = coords;
    else
        centerCoord = round(mean(coords'))';
    end
elseif isequal(centerCoord, 'curloc')
    % get start coord from current location
    centerCoord = vw.loc;
end

% Build the sphere ROI
if(radius>0)
    % * * * CHECK ME: is mm spcified in [X,Y,Z]?
    [X,Y,Z] = meshgrid([-radius./mm(1):+radius./mm(1)],...
                       [-radius./mm(2):+radius./mm(2)],...
                       [-radius./mm(3):+radius./mm(3)]);
    dSq = (X./mm(1)).^2+(Y./mm(2)).^2+(Z./mm(3)).^2;
    keep = dSq(:) < radius.^2;
    % add 'round' to get integers as ROI coodinates
    coords = [round(X(keep)+centerCoord(1)), ...
              round(Y(keep)+centerCoord(2)), ...
              round(Z(keep)+centerCoord(3))];
else
    coords = centerCoord;
end


% Make ROI
ROI.coords = coords';
ROI.name = name;
ROI.color = color;
ROI.viewType = vw.viewType;

% Usually, the ROI is added.  But in some cases, we only want the ROI data.
if addFlag, [vw,pos] = addROI(vw,ROI,select); end

return;
