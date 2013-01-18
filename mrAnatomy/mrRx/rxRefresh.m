function rx = rxRefresh(rx,refreshRef)
% rx = rxRefresh([rx],[refreshRef]):
% 
% refresh function for mrRx. Refreshes
% the display in all open figures, based
% on the settings in the UI controls.
%
% refreshRef: Since the reference window
% only needs to be updated for a few particular
% manipulations (changing the rx slice or
% changing its brightness/contrast), this
% flag can be set to 0 to avoid needlessly
% refreshing it.
%
% ras 02/05.
if ~exist('rx', 'var') || isempty(rx)
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ~exist('refreshRef', 'var') || isempty(refreshRef)
    refreshRef = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save the previous xform for undoing %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rx.prevXform = rx.xform;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get Rx info from UI controls %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get slices from ui
rxSlice = get(rx.ui.rxSlice.sliderHandle,'Value');
rxSlice = round(rxSlice);

% get rot vals
axiRot = get(rx.ui.axiRot.sliderHandle,'Value');
corRot = get(rx.ui.corRot.sliderHandle,'Value');
sagRot = get(rx.ui.sagRot.sliderHandle,'Value');
rot = [corRot axiRot sagRot];
rot = deg2rad(rot); % convert to radians for interp code

% get trans vals
axiTrans = get(rx.ui.axiTrans.sliderHandle,'Value');
corTrans = get(rx.ui.corTrans.sliderHandle,'Value');
sagTrans = get(rx.ui.sagTrans.sliderHandle,'Value');
trans = [corTrans axiTrans sagTrans];

% get flip vals
axiFlip = get(rx.ui.axiFlip,'Value');
corFlip = get(rx.ui.corFlip,'Value');
sagFlip = get(rx.ui.sagFlip,'Value');
flip = [corFlip axiFlip sagFlip]; 
flip(flip>0) = -1; % make binary 
flip(flip==0) = 1; 

% right now we're only doing rigid-
% body xforms, but down the line,
% who knows?
skew = [0 0 0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the transformation matrix %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% account for scale factors
scale = flip .* rx.rxVoxelSize ./ rx.volVoxelSize;

% build xform
rx.xform = affineBuild(trans, rot, scale, skew);

% we center the rx at 0,0,0 to rotate about the
% center -- this compensatory translation ensures
% that zero settings return an unchanged matrix.
% (see rxInterpSlice, rxAddPoints for more info):
shift = [eye(3) -rx.rxDims([2 1 3])'./2; 0 0 0 1];
rx.xform = shift \ rx.xform * shift;

%%%%%Initialize some variables which may or may not be updated
interpImg = []; refImg = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% refresh prescription figure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ishandle(rx.ui.rxAxes)
    axes(rx.ui.rxAxes);
    cla
    
    % get volume, account for view orientation
    vol = rx.vol;
    volSlice = get(rx.ui.volSlice.sliderHandle,'Value');
    volSlice = uint8(volSlice); 
    ori = findSelectedButton(rx.ui.volOri);
    if ori~=3   % do nothing for sagittal view
        % allow for radiological L/R
        hRadiological = findobj('Tag','rxRadiologicalMenu');
        if isequal(get(hRadiological, 'Checked'), 'on')
            vol = flipdim(vol, 3);
        end
        
        % permute volume as needed
        if ori==1, vol = permute(vol,[2 3 1]); end   % axial
        if ori==2, vol = permute(vol,[1 3 2]); end   % coronal
    end
    
    volImg = vol(:, :, volSlice);
    volImg = rxClip(volImg, [], rx.ui.volBright, rx.ui.volContrast);

    htmp = image(volImg); colormap gray; axis off; axis equal;
    set(htmp,'ButtonDownFcn','rxRecenterRx;');
    if get(rx.ui.rxDrawRx, 'Value')==1
        rxDrawRx(rx,volSlice,ori);
    end    
    
    rxLabelVolAxes(rx,ori);    
else
    
    rx.ui.rxFig = [];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% refresh reference slice figure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ishandle(rx.ui.refAxes) 
    if refreshRef==1
        axes(rx.ui.refAxes);
        cla
        
        refImg = rx.ref(:,:,rxSlice);
        refImg = rxClip(refImg, [], rx.ui.refBright, rx.ui.refContrast, ...
                        rx.ui.refHistoThresh);
        imshow(refImg);
        title(sprintf('Reference Slice %i',rxSlice));
    end
    
else
    rx.ui.refFig = [];
    
end


% JL note: please put prescribed slice refreshment after ref slice refreshment, so 
% that when all figures are full-size, I can see presc slice changing with sliders.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% refresh prescribed slice figure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ishandle(rx.ui.interpAxes)
    axes(rx.ui.interpAxes);
    cla
    
    [interpImg interpImg3D] = rxInterpSlice(rx, rxSlice);
    
    % display
    imshow(interpImg3D);
    title(sprintf('Interpolated Slice %i',rxSlice));
    
else
    rx.ui.interpFig = [];
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% refresh prescribed slice 3-view %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if checkfields(rx, 'ui', 'interp3ViewFig') & ishandle(rx.ui.interpLoc(1))
	rx = rxRefresh3View(rx);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% refresh reference / interp comparison %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ishandle(rx.ui.compareAxes)
    axes(rx.ui.compareAxes);
    zoom.x = get(gca, 'xlim');
    zoom.y = get(gca, 'ylim');
    cla
    
    [interpImg refImg] = rxGetComparisonImages(rx, interpImg, refImg);

    method = get(rx.ui.comparePopup, 'Value');
    [compareImg rng ttltxt] = rxCompare(interpImg, refImg, method);
    
    % display
    imagesc(compareImg, rng);

    axis image; axis off;
    
    if ~isequal(zoom.x,[0 1]) && ~isequal(zoom.y, [0 1])  
        xlim(zoom.x); ylim(zoom.y);
    end
    
    if method==2
        set(gca, 'Position', [.05 .15 .7 .85]);
        h = colorbar('vert');        
        set(h, 'Position', [.85 .2 .05 .7]);
        colormap jet
    else
        set(gca, 'Position', [0.05 .2 .9 .75]);
        colormap gray
    end
    title(ttltxt);
    
else
    rx.ui.compareFig = [];
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Display selected ROIs/points %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hshowpts = findobj('Tag','showPointsMenu');
if isequal(get(hshowpts,'Checked'),'on')
    rxShowPoints(rx);
end

hShowRois = findobj('Tag', 'rxShowROIsMenu');
if isequal(get(hShowRois, 'Checked'), 'on');
    rxShowROIs(rx, rxSlice);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set control fig's UserData w/ new Rx info %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(rx.ui.controlFig,'UserData',rx);
figure(rx.ui.controlFig); % return focus


return
