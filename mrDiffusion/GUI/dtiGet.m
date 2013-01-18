function val = dtiGet(dtiH,param,varargin)
% Obtain data from the mrDiffusion (dtiFiberUI) window handles
%
%   val = dtiGet(dtiH,param,varargin);
%
% The dtiGet routine works on the data stored in the handles of the
% mrDiffusion window. To initiate the mrDiffusion code in a way that
% returns the figure number and handles, use
%
%  [dtiF,dtiH] = mrDiffusion;
% 
% If the window already exists and you would like to retrieve the figure
% number and handle, you can use
%  
%  dtiF = dtiGet; 
%  dtiH = guidata(f)
%
% dtiH data are accessed using this routine, as in
%  
%   v = dtiGet(dtiH,'param');
%
% There is a parallel group of functions around the general diffusion
% weighted data, dwiGet/Set/Create. These work with the raw diffusion data.
%
% There are many gets here, but more are needed.  For example, we need a
% way to get the quadratic forms (tensors) at each voxel.
%
% The list of dtiGet parameters (needs checking):
%
%  Main Figure
%      {'main figure'} - Handle to mrdMain figure
%      {'handles'}     - Find main figure and then handles
%      {'curposimg'} - Current cursor position in image space
%      {'curposacpc'} - Current cursor position in acpc space
%      {'current background image name'}
%      {'current background image number'}
%      {'cur overlay num'}
%      {'cur overlay thresh'}
%      {'cur overlay alpha'}
%      {'cur overlay range'}
%      {'cur overlay cmap'}
%      {'mm per voxel current bg'}
%      {'dt6 mm per voxel'} - Resolution of the diffusion data (mm)
%
%   Anatomy and related slices
%      {'currentanatomydata'}
%       % This is a weird one.  In general, this one returns zillions of
%       % things.  Break this out 
%      {'current image slices'}  
%      {'current image slice number'}
%      {'current anatomy range'}
%
%  Image transforms - Each image's xform now goes to ac-pc space. 
%      {'img2acpc xform'}  - Image space to ACPC transform
%      {'acpc2img xform'}  - ACPC to image space transform
%      {'acpctot1 xform'}  - ACPC to T1 space transform
%      {'t1toacpc xform'}  - T1 to ACPC transform
%      {'current acpc2img xform'}
%      {'current acpc xform'}
%      {'curmeshtoacpcxform','meshxform'}
%         % OK-the following needs some explaining. mrMesh vertices are essentially
%         % mrVista vAnat coords scaled to isotropic voxels, with X and Y swapped
%         % (why not?). Reading from right-to-left (since it a pre-multiply xform),
%         % inv(xformVAnatToAcpc) converts mrDiffusion ac-pc coords
%         % to mrVista vAnat coords. The diag([msh.mmPerVox([2,1,3]) 1]) thing
%         % removes the vAnat scale factor. And finally, we need to do an x-y swap.
%      {'glassbrain','glassbraincheckbox'}
%      {'dtitoanatxform','dti2anatxform','dtianatxform'} 
%
%   % Fiber group
%      {'current fiber group number'}
%      {'current fiber group'}
%      {'allfibergroups'}
%      {'fg Names'}
%      {'current fiber group name'}
%      {'current fiber group lengths'}
%         % Maybe this should be
%         %   dtiGet(dtiH,fiberlengths,groupNum) 
%         % and when groupNum is not
%         % passed we use the current fiber group.  And this might be applied
%         % to all of these s.
%         % dtiGet(dtiH,'fiberlengths');
%      {'number of fibers current group'}
%      {'number of fiber groups'}
%      {'fibergroupvisibility','fgvisibility','visiblefgvector'}
%         % This returns a vector of 0s and 1s indicating visibility
%      {'visiblefgs','listofvisiblefgs','listofvisiblefibergroups'}
%         % This returns a vector of numbers indicating the visible FGs
%      {'current fg coords image space'}
%      {'current fg coords acpc space'}
%
%   ROI information
%      {'currentroi'}        - Not sure
%      {'currentroinum'}     - Which one in the list
%      {'roi','specificroi'} - disp('Not yet implemented');
%      {'currentroiname'}
%      {'currentroicoords'}
%      {'curroicolor','currentroicolor'}
%      {'nrois'}         - Number of ROIs
%      {'roivisibility'} - Binary vector indicating visibility of each ROI
%         % of ROIs
%      {'visiblerois'} - A vector of numbers indicating the visible 
%
%      {'defaultboundingbox'}
%      {'defaultmmpervox'}
%      {'t1boundingbox'}
%      {'currentboundingbox'}- The bounding box dimensions in millimeters.
%      {'currentacpcgrid','curacpcgrid','curimggrid'}  - The overlay grid
%      {'acpcgrid','acpcgrid','imggrid'}
%      
%   Associated data in background images
%      {'backgroundimage'} -  img = dtiGet(h,'backgroundImage',n);
%      {'curbgnum'}      - current background number (integer)
%      {'bg size'}       - (row,col) of current background image
%      {'namedbgnum'}      - dtiGet(h,'namedimagenum','fiber density(6)')
%      {'fadata'}        - Fractional anisotropy
%      {'t1data'}        - T1-weighted image data
%      {'vectorrgb'}     - Color map showing principal diffusion direction
%      {'b0'}            - Always first image, apparently
%      {'display range'} - Used by dtiGetCurSlice for rendering
%
%    % MESH Related
%      {'mrmesh','mesh'}
%      {'mrmeshcheckbox','meshcheckbox','mrmeshcb','meshcb'}
%      {'origin'}
%
%    % GUI window parameters
% useMrMesh    = get(handles.cbUseMrMesh, 'Value');
% show2dFibers = get(handles.cbShowFibers,'Value');
% showMatlab3d = get(handles.cbShowMatlab3d,'Value');
% showCurPosMarker  = get(handles.cbShowCurPosMarker, 'Value');
% curBgNum      = dtiGet(handles,'bg num'); 
% % get(handles.popupBackground,'Value');
% overlayThresh = get(handles.slider_overlayThresh, 'Value');
% overlayAlpha  = str2double(get(handles.editOverlayAlpha, 'String'));
% curOvNum      = get(handles.popupOverlay,'Value');
% 
% Examples:
%
%  vistaDataPath;
%  chdir(fullfile(mrvDataRootPath,'diffusion','sampleData'));
%  [dtiF,dtiH] = mrDiffusion('on',fullfile('dti40','dt6.mat')); 
%  curAnat = dtiGet(dtiH,'current anatomy data');
%  mrvNewGraphWin; showMontage(curAnat)
%
% Add
%   interpType for interpolating in space.
%   We should have a way to get a specific background image type by name.
%   (e.g., T1 or vector RGB).
%
% (c) Stanford VISTA Team, 2008

% Enables the case hdl = dtiGet;
if ~exist('dtiH','var'), dtiH = []; end   % Permitted for dtiF, dtiH, and allmrdfigs; 
if notDefined('param'), error('Undefined parameter'); end
val = [];

% Squeeze spaces and set to lower case
param = mrvParamFormat(param);

% Switch on get parameter
switch lower(param)
           
    case {'dtif','figure','mainfigure'}
        % dtiF = dtiGet([],'dtif');
        % Returns the first figure with mrMain in the name
        if ~isempty(dtiH), val = dtiH.figure1;
        else
            t = get(0,'children');
            for ii=1:length(t)
                if strncmp(get(t(ii),'name'),'mrdMain',7)
                    fprintf('Found mrDiffusion %d\n',ii);
                    val = t(ii);
                    break;
                end
            end
        end
        
    case {'handles','dtih'}
        % dtiGet([],'handles');
        dtiF = dtiGet([],'main figure');
        val = guihandles(dtiF);
        
        %     case 'allmrdfigs'
        %         % fList = dtiGet;
        %         % Gets all of the mrDiffusion related figures in the root window
        %         % that are of Type 'figure' and that are named 'mrd1'.
        %         % This function is used to get all the figures that were created by
        %         % mrDiffusion (get(f(ii),'CreateFcn')) but that seemed to stop
        %         % working.
        %         f = get(0,'children');
        %         val = [];
        %         for ii=1:length(f)
        %             t = get(f(ii),'Type');
        %             if(~isempty(t) && strcmp(t,'figure'))
        %                 n = get(f(ii),'Name');
        %                 if strncmpi(n,'mrdmain',7), val(end+1) = f(ii); end
        %             end
        %         end
        %
        %         % If we get a valid dtiH struct or a numeric value
        %         % in then we'll exclude that figNum (presumably that is the
        %         % 'self'). -
        %         % I have no idea what the usage case here is (BW).
        %         if(~isempty(dtiH))
        %             if(isstruct(dtiH)), myFigNum = dtiH.figure1;
        %             elseif(isnumeric(dtiH)), myFigNum = dtiH;
        %             else myFigNum = -999;
        %             end
        %             val(val==myFigNum) = [];
        %         end
        
        % Display image properties
    case {'curposimg','curpositionimg','currentpositionimg','imgposition','imgpos'}
        curPosAcpc = dtiGet(dtiH, 'acpcpos');
        xform = dtiGet(dtiH, 'cur acpc2img xform');
        val = mrAnatXformCoords(xform, curPosAcpc);
    case {'curposacpc','curpos','curposition','currentposition','acpcposition','acpcpos'}
        val = str2num(get(dtiH.editPosition, 'String'));
    case {'curoverlaynum'}
        val = get(dtiH.popupOverlay,'Value');
    case {'curoverlaythresh'}
        val = get(dtiH.slider_overlayThresh, 'Value');
    case {'curoverlayalpha'}
        val = str2num(get(dtiH.editOverlayAlpha, 'String'));
    case {'curoverlayrange'}
        val = [dtiH.bg(get(dtiH.popupOverlay,'Value')).minVal ...
            dtiH.bg(get(dtiH.popupOverlay,'Value')).maxVal];
   
    case {'bgmmpervox','mmpervoxelcurrent','mmpervoxelcurrentbackground','mmpervoxelcurrentbg','mpvcurbg','curmm'}
        % dtiGet(dtiH,'bg mmpervox',n);
        if isempty(varargin), bgNum = dtiGet(dtiH,'bg num');
        else bgNum = varargin{1};
        end
        val = dtiH.bg(bgNum).mmPerVoxel;
    
    case {'dt6mmpervoxel','mmpervoxel'}
        % The resolution of the diffusion (dt6) data
        val = dtiH.mmPerVoxel;
        
    case {'unitstring','unitstr'}
       % Get the units on the current anatomy       
        if isempty(varargin), bgNum = dtiGet(dtiH,'bg num');
        else bgNum = varargin{1};
        end
        val = dtiH.bg(bgNum).unitStr;   
    
    % Anatomy and related slizes
    case {'currentanatomydata','curanatdata'}
       % anat = dtiGet(dtiH,'curanat data');       
       n   = dtiGet(dtiH,'bg num');
       val = dtiH.bg(n).img;
    case {'currentimageslices'}
        % This is a weird one.  In general, this one returns zillions of things.  Break this out
        % val = dtiGetCurSlices(dtiH);
        error('call dtiGetCurSlices');
    case {'currentimageslicenumber','curslicenum','currentslicenum'}
        % dtiGet(dtiH,'curslicenum',1)
        % dtiGet(dtiH,'curSlicenum')
        % curSlice = dtiGet(dtiH,'currentSliceNum',sliceThisDim);
        if isempty(varargin), return;
        else
            curPos = dtiGet(dtiH,'currentPosition');
            val = curPos(varargin{1});
        end
    case {'currentanatomyrange','currentanatomyminmax','curanatminmax','curanatrange'}
        % dtiGet(dtiH,'curanat range')
        if strmatch(dtiGet(dtiH,'currentanatomyname'),'vectorRGB')
            val = [0,1];
        else
            n = dtiGet(dtiH,'currentanatomyvalue');
            if(isfield(dtiH.bg(n), 'minVal'))
                val = [dtiH.bg(n).minVal,dtiH.bg(n).maxVal];
            else
                % Or shouldn't we compute the range here?
                val = [0,1];
            end
        end
    case {'bgrange'}
        % dtiGet(dtiH,'bg range',n)
        if isempty(varargin)
            val = dtiGet(dtiH,'currentanatomyrange');
        else
            if strmatch(dtiGet(dtiH,'current anatomy name'),'vectorRGB')
                val = [0,1];
            else
                n = varargin{1};
                if(isfield(dtiH.bg(n), 'minVal'))
                    val = [dtiH.bg(n).minVal,dtiH.bg(n).maxVal];
                else
                    % Or shouldn't we compute the range here?
                    val = [0,1];
                end
            end
        end
        
    case {'rendermm'}
        % Used in dtiGetCurSlices as a rendering parameter.
        if(isfield(dtiH,'renderMm') && ~isempty(dtiH.renderMm))
            val = dtiH.renderMm;
        else
            val = [1 1 1];
        end
        
        % Image transforms
    case {'dt6toacpcxform','dt6xform','img2acpcxform'}
        % Transform from  diffusion data to ACPC space
        val = dtiH.xformToAcpc;
    case {'acpc2dt6xform','invdt6xform'}
        % Transform from ACPC to diffusion data image space 
        val = inv(dtiH.xformToAcpc);
    case {'acpctot1xform'}
        t1Num = strmatch('t1',{dtiH.bg.name});
        if(length(t1Num)~=1), error('No match for "t1"!'); end
        val = inv(dtiH.bg(t1Num).mat);
    case {'t1toacpcxform'}
        t1Num = strmatch('t1',{dtiH.bg.name});
        if(length(t1Num)~=1), error('No match for "t1"!'); end
        val = dtiH.bg(t1Num).mat;
    case {'currentacpc2imgxform','curacpc2imgtransform','curacpc2imgxform','curacpctoimgxform','acpc2imgxform'}
        % Current acpc to raw image data transform.
        val = inv(dtiH.bg(dtiGet(dtiH,'bg num')).mat);
    case {'currentimage2acpcxform','currentacpcxform','curacpctransform','curacpcxform','curimg2acpcxform','curimgtoacpcxform'}
        % Current background image to acpc transform.
        val = dtiH.bg(dtiGet(dtiH,'bg num')).mat;
    case {'bgimg2acpcxform'}
        % dtiGet(dtiH,'bg img2acpc xform',n);
        if isempty(varargin)
            val = dtiGet(dtiH,'current image2acpc xform');
        else
            n = varargin{1};
            val = dtiH.bg(n).mat;
        end
    case {'bgacpc2imgxform'}
        % dtiGet(dtiH,'bg acpc2img xform',n)
        if isempty(varargin)
            val = inv(dtiGet(dtiH,'bg img2acpc xform'));
        else
            n = varargin{1};
            val = inv(dtiGet(dtiH,'bg img2acpc xform',n));
        end
    case {'curmeshtoacpcxform','meshxform'}
        % OK-the following needs some explaining. mrMesh vertices are essentially
        % mrVista vAnat coords scaled to isotropic voxels, with X and Y swapped
        % (why not?). Reading from right-to-left (since it a pre-multiply xform),
        % inv(xformVAnatToAcpc) converts mrDiffusion ac-pc coords
        % to mrVista vAnat coords. The diag([msh.mmPerVox([2,1,3]) 1]) thing
        % removes the vAnat scale factor. And finally, we need to do an x-y swap.
        if(~isfield(dtiH, 'mrVistaMesh') || isempty(dtiH.mrVistaMesh.meshes))
            error('No meshes!');
        end
        msh = dtiH.mrVistaMesh.meshes(dtiH.mrVistaMesh.curMesh);
        swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
        %val = swapXY*diag([msh.mmPerVox([2,1,3]) 1])*inv(dtiH.vanatXform)*inv(dtiGet(dtiH,'acpctot1xform'));
        val = swapXY*diag([msh.mmPerVox([2,1,3]) 1])*inv(dtiH.xformVAnatToAcpc);
    case {'interptype'}
        % Specifies type of spatial interpolation in SPM call (usually)
        % Default is nearest neighbor ('n')
        % Other options are:
        
        if isfield(dtiH,'interpType'), val = dtiH.interpType;
        else val = 'n'; 
        end
        
        % Glass brain ... not much used any more
    case {'glassbrain','glassbraincheckbox'}
        if isfield(dtiH,'cbGlassBrain')
            val   = get(dtiH.cbGlassBrain,'Value'); 
        end
        
        % Fiber group
    case {'currentfibergroupnumber','curfibergroupnum','curfgnum','fgcurnum'}
        val = dtiH.curFiberGroup;
    case {'currentfibergroup','fgacpc','fgcurrent','fgcur','currentfg','curfibergroup'}
        % Returns the current fiber group with coordinates in acpc space
        % coords = dtiGet(dtiH,'fg acpc');
        gn = dtiGet(dtiH,'curFiberGroupNum');
        if(gn<=0 || isempty(dtiH.fiberGroups)), error('No fibers!'); end
        val = dtiH.fiberGroups(gn);
    case {'currentfibergroupimage','fgimage'}
        % Returns the current fiber group with coordinates in diffusion
        % image space 
        %    coords = dtiGet(dtiH,'fg image');
        %
        val = dtiGet(dtiH,'fg acpc');
        acpcToImage = dtiGet(dtiH,'acpc2imgxform');
        val = dtiXformFiberCoords(val,acpcToImage);
        
    case {'allfibergroups'}
        % Array of all the fiber groups
        val = dtiH.fiberGroups;
    case {'fibergroups'}
        % Array of the selected fibergroups
        %   dtiGet(dtiH,'fiber groups',list)
        % If the list is empty, this is the same as asking for all fiber
        % groups 
        if isempty(varargin), val = dtiH.fiberGroups;
        else 
            list = varargin{1};
            val = dtiH.fiberGroups(list);
        end
            
    case {'fibergroupnames','fgnames'}
        n = dtiGet(dtiH,'nfgs');
        val = cell(n,1);
        for ii=1:n, val{ii} = dtiH.fiberGroups(ii).name; end
    case {'currentfibergroupname','curfgname'}
        val = dtiH.fiberGroups(dtiGet(dtiH,'curfgnum')).name;
    case {'currentfibergrouplengths','fiberlengths'}
        % Maybe this should be
        % dtiGet(dtiH,fiberlengths,groupNum) and when groupNum is not
        % passed we use the current fiber group.  And this might be applied
        % to all of these cases.
        % dtiGet(dtiH,'fiberlengths');
        curFG = dtiGet(dtiH,'currentfibergroup');
        nFibers = length(curFG.fibers);
        val = zeros(1,nFibers);
        for ii=1:nFibers, val(ii) = length(curFG.fibers{ii}); end
        
    case {'numberoffiberscurrentgroup','numberoffibers'}
        % dtiGet(dtiH,'numberoffibers')
        curFG = dtiGet(dtiH,'currentfibergroup');
        val = length(curFG.fibers);
        
    case {'numberoffibergroups','nfibergroups','nfgs'}
        % Number of fiber groups
        %  n = dtiGet(dtiH,'n fiber groups');
        %
        val = length(dtiH.fiberGroups);
        
    case {'fibergroupvisibility','fgvisibility','visiblefgvector'}
        % This returns a vector of 0s and 1s indicating visibility
        n = length(dtiH.fiberGroups);
        if n > 0
            val = zeros(n,1);
            for ii=1:n, val(ii) = dtiH.fiberGroups(ii).visible; end
        end
    case {'visiblefgs','listofvisiblefgs','listofvisiblefibergroups'}
        % This returns a vector of numbers indicating the visible FGs
        n =dtiGet(dtiH,'numberoffibergroups');
        val = [];
        for ii=1:n
            if dtiH.fiberGroups(ii).visible, val = [val,ii]; end
        end
        
    case {'fgimgcoordsunique','currentfgcoordsimagespace','fgcoordsimage'}
        % Image indices (unique) of the fibers in diffusion image space
        %   coords = dtiGet(dtiH,'fg coords image');
        % These are rounded to the resolution of the diffusion data
        % The rounded unique coordinates are returned.
        
        fg = dtiGet(dtiH,'currentfibergroup');
        % fgImg = dtiGet(dtiH,'fg image space');
        acpcToImage = dtiGet(dtiH,'acpc2imgxform');
        fgImg = dtiXformFiberCoords(fg,acpcToImage);
        
        % This needs to be w.r.t. the diffusion data!
        val = horzcat(fgImg.fibers{:})';

        %  Get the resolution of the diffusion data
        val = unique(round(val),'rows');
        
    case {'currentfgcoordsacpcspace','fgcoordsacpc'}
        % Coords of the fibers in acpc space
        % coords = dtiGet(dtiH,'fg coords acpc');
        % These are not rounded and not unique
        fg = dtiGet(dtiH,'currentfibergroup');
        val = horzcat(fg.fibers{:})';
        
    case {'fgcoordsacpcunique'}
        % Coords of the fibers in acpc space
        % coords = dtiGet(dtiH,'fg coords acpc unique');
        % The rounded (1 mm) unique coordinates are returned
        fg = dtiGet(dtiH,'currentfibergroup');
        val = horzcat(fg.fibers{:})';
        val = unique(round(val),'rows');
    
        % ROI information
    case {'currentroi'}
        if(isempty(dtiH.rois)), val = [];
        else val = dtiH.rois(dtiH.curRoi);
        end
    case {'currentroinum','curroinum'}
        val = dtiH.curRoi;
    case {'roi','specificroi'}
        disp('Not yet implemented');
    case {'currentroiname','curroiname'}
        val = dtiH.rois(dtiH.curRoi).name;
    case {'currentroicoordsacpc','currentroicoords','curroicoords'}
        % Coordinates of the currently selected ROI
        % These are in acpc space (we think).
        %  val = dtiGet(dtiH,'current roi coords acpc',2);
        if isempty(varargin), whichROI = dtiH.curRoi;
        else whichROI = varargin{1};
        end
        val = dtiH.rois(whichROI).coords;
    case {'currentroicoordsimage','currentroicoordimage'}
        % Coordinates of the currently selected ROI
        % These are in image (not acpc) space (we think).
        %   val = dtiGet(dtiH,'current roi coords image',2);
        if isempty(varargin), whichROI = dtiH.curRoi;
        else whichROI = varargin{1};
        end
        val = dtiH.rois(whichROI).coords;   
        acpcToImg = inv(dtiH.xformToAcpc);
        val = mrAnatXformCoords(acpcToImg, val);
    case {'currentroicoordsimageunique','currentroicoordimageunique'}
        %  Get the unique coordinates in this space. There can be duplicates
        %  becase the acpc is usually at 1mm and then image is often at 2mm.
        %  So we have about 8 points in acpc space to each point in image
        %  space.  Rounding means we oversampled.
        val = dtiGet(dtiH,'current roi coords image');
        val = unique(round(val),'rows');
    case {'curroicolor','currentroicolor'}
        val = dtiH.rois(dtiH.curRoi).color;
    case {'numberofrois','nrois','numrois'}
        val = length(dtiH.rois);
    case {'roivisibility','roivisibilityvector','visibleroivector'}
        % This returns a vector of 0s and 1s indicating visibility
        % of ROIs
        n = length(dtiH.rois);
        if n > 0
            val = zeros(n,1);
            for ii=1:n, val(ii) = dtiH.rois(ii).visible; end
        end
    case {'visiblerois','listofvisiblerois'}
        % This returns a vector of numbers indicating the visible ROIs
        n = dtiGet(dtiH,'numberofrois');
        val = [];
        for ii=1:n
            if dtiH.rois(ii).visible, val = [val,ii]; end %#ok<AGROW>
        end
        
    case {'defaultboundingbox','boundingbox','defaultbb'}
        if(~isempty(dtiH)&&isstruct(dtiH)&&isfield(dtiH,'bb')&&~isempty(dtiH.bb))
            val = dtiH.bb;
        else
            val = [-80,80; -120,90; -60,90]';
        end
        
    case {'defaultmmpervox','defaultmm'}
        val = [1 1 1];
        
    case {'t1boundingbox','t1bb'}
        % Not sure
        [img, mmPerVoxel, mat] = dtiGetNamedImage(dtiH.bg, 't1');
        val = dtiH.acpcXform*mat*[1,1,1,1;[size(img),1]]';
        val = val(1:3,:)';
        
    case {'currentboundingbox','curboundingbox','curbb'}
        % dtiGet(dtiH,'cur bb');
        % Get bounding box dimensions in millimeters. Changed Aug. 6 2011
        % because it was clearly broken.  Not sure whether the change
        % (replacing mmPerVoxel by mm) was correct.  But it seemed correct.
        % and matched nearby code (below)- BW

        %[img, mm, mat] = dtiGetCurAnat(dtiH);
        n      = dtiGet(dtiH,'bg num');
        img    = dtiGet(dtiH,'bg image',n);
        mm     = dtiGet(dtiH,'bg mmpervox',n);
        mat    = dtiGet(dtiH,'bg img2acpc xform',n);
        orig   = mat\[0 0 0 1]'; orig  = orig(1:3)';
        
        % This is probably a bug.
        val = [-mm .* (orig-1) ; mm.*(size(img)-orig)];
        
    case {'currentacpcgrid','curacpcgrid','curimggrid'}
        % Not sure
        if(~isempty(varargin)&&islogical(varargin{1})&&varargin{1})
            % get the overlay grid
            n  = dtiGet(dtiH,'onum');
            % [img, mm, mat] = dtiGetCurAnat(dtiH,true);
        else
            % get the overlay background grid
            n = dtiGet(dtiH,'bg num');        
            % [img, mm, mat] = dtiGetCurAnat(dtiH);
        end
        
        img    = dtiGet(dtiH,'bg image',n);
        mm     = dtiGet(dtiH,'bg mmpervox',n);
        mat    = dtiGet(dtiH,'bg img2acpc xform',n);
        orig  = mat\[0 0 0 1]'; orig  = orig(1:3)';
        bb = [-mm .* (orig-1) ; mm.*(size(img)-orig)];
        x   = (bb(1,1):mm(1):bb(2,1));
        y   = (bb(1,2):mm(2):bb(2,2));
        z   = (bb(1,3):mm(3):bb(2,3));
        [val.X,val.Y,val.Z] = ndgrid(x, y, z);
        
    case {'acpcgrid','imggrid'}
        % dtiGet(dtiH,'acpc grid',n);
        % Was crazy and wrong.  I don't even understand the arguments
        % in varargin.  Old code is left below.
        if isempty(varargin), val = dtiGet(dtiH, 'cur acpc grid');
        else
            warning('testing acpc grid')
            n = varargin{1};
            img    = dtiGet(dtiH,'bg image',n);
            mm     = dtiGet(dtiH,'bg mmpervox',n);
            mat    = dtiGet(dtiH,'bg img2acpc xform',n);
            orig  = mat\[0 0 0 1]'; orig  = orig(1:3)';
            bb = [-mm .* (orig-1) ; mm.*(size(img)-orig)];
            x   = (bb(1,1):mm(1):bb(2,1));
            y   = (bb(1,2):mm(2):bb(2,2));
            z   = (bb(1,3):mm(3):bb(2,3));
            [val.X,val.Y,val.Z] = ndgrid(x, y, z);
            % Old code
            %             mat = varargin{1};
            %             mm = varargin{2};
            %             sz = varargin{3};
            %             orig  = mat\[0 0 0 1]'; orig  = orig(1:3)';
            %             bb = [-mm .* (orig-1) ; mm.*(sz-orig)];
            %             x   = (bb(1,1):mm(1):bb(2,1));
            %             y   = (bb(1,2):mm(2):bb(2,2));
            %             z   = (bb(1,3):mm(3):bb(2,3));
            %             [val.X,val.Y,val.Z] = ndgrid(x, y, z);
        end
        
    case {'mrmesh','mesh'}
        if checkfields(dtiH,'mrMesh'), val =  dtiH.mrMesh; end
        
    case {'mrmeshcheckbox','meshcheckbox','mrmeshcb','meshcb'}
        if checkfields(dtiH,'cbUseMrMesh'), val   = get(dtiH.cbUseMrMesh,'Value'); end
        
    case {'origin'}
        % dtiGet(dtiH,'origin');
        % Not yet sure what this computs.  Ask Bob.
        val = dtiMrMeshOrigin(dtiH);
        
    case {'namedimagenum','namedimgnum','namedbgnum'}
        % imgNum = dtiGet(h,'namedimagenum','fiber density(6)')
        val = strmatch(lower(varargin{1}), lower({dtiH.bg.name}));
        if(~isempty(val)), val = val(1);
        else val = []; end
        
        % The current background image information
    case {'backgroundname','currentbackgroundimagename','currentbackgroundname','currentbgname','curbackname','currentanatomyname','curanatname'}
        contents = get(dtiH.popupBackground,'String');
        val = contents{get(dtiH.popupBackground,'Value')};        
    case {'bgnum','backgroundnumber','currentbackgroundimagenumber'}
        % Used to alias:
        % 'curbgnum','curbacknumber','curbacknum','curanatvalue'
        % 'currentanatomyvalue','bg num'
        val = get(dtiH.popupBackground,'Value');
    case {'bgimage','backgrounddata','backgroundimage'}
        % img = dtiGet(h,'background image',n);
        % Not necessarily the current background image.  
        if isempty(varargin), n = dtiGet(dtiH,'background number');
        else n = varargin{1}; end
        val = dtiH.bg(n).img;
    case {'bgsize','backgroundsize'}
        % img = dtiGet(h,'background image',n);
        % Not necessarily the current background image.  
        if isempty(varargin), n = dtiGet(dtiH,'background number');
        else n = varargin{1}; end
        val = size(dtiH.bg(n).img);
    case {'bgnames','backgroundnames'}
        % List of background data names
        % names = dtiGet(dtiH,'background names');
        n = length(dtiH.bg);
        val = cell(1,n);
        for ii=1:n, val{ii} = dtiH.bg(ii).name; end
    case {'bgname'}
        % dtiGet(dtiH,'bg name',n);
        % Name of background
        if isempty(varargin), n = dtiGet(dtiH,'bg num');
        else n = varargin{1};
        end
        val= dtiH.bg(n).name;
    case {'bgunitstring'}
        if isempty(varargin), n = dtiGet(dtiH,'bg num');
        else n = varargin{1};
        end
        val = dtiH.bg(n).unitStr;
        
    case {'bgdisplayrange','displayrange'}
        % Used by dtiRefreshFigure and dtiGetCurSlices to display the
        % background data properly.
        if isempty(varargin), n = dtiGet(dtiH,'bg num');
        else                  n = varargin{1};
        end
        dtiH.bg(n).displayValueRange;
        
        % Overlay image information
    case {'overlayname'}
        % Currently chosen overlay name
        contents = get(dtiH.popupOverlay,'String');
        val = contents{get(dtiH.popupOverlay,'Value')};
    case {'overlaynumber','onum'}
        % Currently chosen overlay number
        val = get(dtiH.popupOverlay,'Value');
    case {'curoverlaycmap','ocmap'}
        % dtiGet(dtiH,'o cmap',n)
        % Cmap of current or any specified
        if isempty(varargin), n = dtiGet(dtiH,'overlay number');
        else                  n = varargin{1}; end
        val  = dtiH.cmaps(n).rgb;
    case {'overlaydata','overlayimage'}
        % dtiGet(dtiH,'overlay data',n)
        % Image data for overlay
        if isempty(varargin), n = dtiGet(dtiH,'overlay number');
        else                  n = varargin{1}; end
        val = dtiH.bg(n).img;
    case {'overlayxform'}
        if isempty(varargin), n = dtiGet(dtiH,'overlay number');
        else                  n = varargin{1}; end
        val = dtiH.bg(n).mat;
    case {'overlaydisplayrange'}
        if isempty(varargin), n = dtiGet(dtiH,'overlay number');
        else                  n = varargin{1}; end
        dtiH.bg(n).displayValueRange;
        
        % Specific data types used as backgrounds.  Some of these are found
        % by searching the name field.
    case {'b0'}
        % A B0 volume.  Eeek. Is B0 always the first one?
        val = dtiH.bg(1).img;
    case {'fa','fadata','fractionalanisotropy'}
        % faData = dtiGet(dtiH,'fa data');
        names = dtiGet(dtiH,'background names');
        n   = find(strcmpi(names,'fa'));
        val = dtiGet(dtiH,'background image',n);
    case {'t1','t1data','t1anatomical'}
        % faData = dtiGet(dtiH,'t1 data');
        names = dtiGet(dtiH,'background names');
        n   = find(strcmpi(names,'t1'));
        val = dtiGet(dtiH,'background image',n);
        
    case {'dtitoanatxform','dti2anatxform','dtianatxform'}
        % What is this?
        val = dtiH.vec.mat;
            
        % GUI Window parameters
    case {'showmrmesh'}
        % Shows mrMesh window
        val = get(dtiH.cbUseMrMesh, 'Value');
    case {'show2dfibers'}
        % Puts fibers into the three image windows
        val = get(dtiH.cbShowFibers,'Value');
    case {'show3dfibersmatlab'}
        % Matlab 3D checkbox status
        % Shows a Matlab window with fibers rendered.  Little used.
        val = get(dtiH.cbShowMatlab3d,'Value');
    case {'showcurposmarker'}
        % Put the X in the image windows, or not
        val = get(dtiH.cbShowCurPosMarker, 'Value');
    case {'overlaythreshold','othresh'}
        % Overlay threshold controlled by slider
        val = get(dtiH.slider_overlayThresh, 'Value');
    case {'overlayalpha','oalpha'}
        % Overlay alpha value controlled by edit box
        val = str2double(get(dtiH.editOverlayAlpha, 'String'));

    otherwise
        error('[%s] Unknown parameter [%s]',mfilename, param);
end
return;




