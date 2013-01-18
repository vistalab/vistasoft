function varargout = computeTalairach(varargin)
% computeTalairach: Application M-file for GUIDE-generated computeTalairach.fig
%
% USAGE:
%
%    fig = computeTalairach : launch computeTalairach GUI.
%
%    fig = computeTalairach(vAnatomyPath) : lauch GUI with specified vAnatomy.
%
%    fig = computeTalairach(vAnatomyPath) : lauch GUI with specified vAnatomy.
%           Will load existing data from a talairach.mat file, if it exists.
%
%    computeTalairach('callback_name', ...) invoke the named callback.
%
% For more info, launch the GUI and press the 'Help' button, or go to:
%   http://white.stanford.edu/newlm/index.php/Anatomical_Methods#Computing_Talairach_coordinates
%
% SEE ALSO:
%
% volToTalairach, talairachToVol
%
% HISTORY:
%   2001.09.14 RFD (bob@white.stanford.edu) Wrote it.
%

% Talairach info from the MedX manual:
%
% The anatomic conventions of the Talairach Atlas are that anatomic right, 
% superior and anterior directions are positive, while left, inferior and 
% posterior directions are negative (Talairach Atlas Landmarks). Talairach 
% Atlas Lanmarks are used to define the registration are as follows: 
%
% 1. The Anterior Commissure (AC), defined as the origin of the Talairach 
%   Atlas coordinate system, is assumed to be at location (0, 0, 0). 
%
% 2. The Posterior Commissure (PC) is assumed to be at location ( 0, -24, 0 ). 
%
% 3. The point where the AC-PC line intersects the posterior extent of the 
%   brain at the AC-PC level. This point is designated as the landmark 
%   "Posterior to the Posterior Commissure" (PPC), and is assumed to be at 
%   location ( 0, -102, 0 ). 
%
% 4. The point where the AC-PC line intersects the anterior extent of the 
%   brain at the AC-PC level. This point is designated as the landmark 
%   "Anterior to the Anterior Commissure" (AAC), and is assumed to be at 
%   location ( 0, 68, 0 ). 
%
% 5. The point where a "horizontal" line passing through the AC intersects 
%   the left extent of the brain in the coronal plane containing the AC. 
%   This point is designated as the landmark "Left of the Anterior Commissure" 
%   (LAC), and is assumed to be at location ( -62, 0, 0 ). 
%
% 6. The point where a "horizontal" line passing through the AC intersects 
%   the right extent of the brain in the coronal plane containing the AC. 
%   This point is designated as the landmark "Right of the Anterior 
%   Commissure" (RAC), and is assumed to be at location ( 62, 0, 0 ). 
%
% 7. The point where a "vertical" line passing through the AC intersects the 
%   superior extent of the brain in the coronal plane containing the AC. This 
%   point is designated as the landmark "Superior to the Anterior Commissure" 
%   (SAC), and is assumed to be at location ( 0, 0, 72 ). 
%
% 8. The point where a "vertical" line passing through the AC intersects the 
%   inferior extent of the brain (i.e., the inferior extents of the temporal 
%   lobes) in the coronal plane containing the AC. This point is designated 
%   as the landmark "Inferior to the Anterior Commissure" (IAC), and is 
%   assumed to be at location ( 0, 0, -42 ). 
%
% In order to best place the landmarks according to the assumptions used to 
% determine their locations in Talairach Atlas space, it is recommended that 
% you locate and place landmark vertices in specific orthogonal views, as follows: 
%
%   AC, PC: Use sagittal and transverse views 
%
%   SAC, IAC, RAC, LAC: Use coronal view 
%
%   AAC, PPC: Use transverse view 
%
% [END MedX quote]

% Last Modified by GUIDE v2.5 05-Sep-2004 00:42:46

if nargin < 2  % LAUNCH GUI
    fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
    oldTal = [];
    % We store all our data in handles.data
    handles.data.controlFigNum = fig;
    if(nargin>0 && ischar(varargin{1}))
        % then we were given a filename- try to open it.
        eval('[vAnat, mmPerPix, vSize, fileName, formatStr] = loadVolumeDataAnyFormat(varargin{1});','vAnat=[];');
    else
        vAnat=[];
    end
    if(isempty(vAnat))
        [vAnat, mmPerPix, vSize, fileName, formatStr] = loadVolumeDataAnyFormat;
    end
    % note that readVolAnat throws an error if the file could not be opened
    % (even if the user cancels), so we don't really need to trap that condition,
    % but it's good practice.
    if(isempty(vAnat))
        % if it's _still_ empty, we refuse to go on...
        error('vAnatomy not loaded!');
    end
    
    if(strcmpi(formatStr,'analyze') || strcmpi(formatStr,'nifti'))
        %handles.data.mat = [0 0 -1 vSize(3); 0 -1 0 vSize(2); 1 0 0 0; 0 0 0 1];
        %handles.data.mat = [1 0 0 0; 0 0 -1 vSize(3); 0 -1 0 vSize(2); 0 0 0 1];
        handles.data.mat = [1 0 0 0; 0 0 -1 vSize(2); 0 -1 0 vSize(3); 0 0 0 1];
    else
        handles.data.mat = [0 0 1 0; 1 0 0 0; 0 1 0 0; 0 0 0 1];
    end
    
    [vAnat, mmPerPix, handles.data.axesCAS, handles.data.flipCAS] = applyCannonicalXform(vAnat, handles.data.mat, mmPerPix);
    vSize = size(vAnat);
    
    % Clip image values using the histogram
    upperClipLevel = 0.995;
    lowerClipLevel = 0.40;
    maxVal = max(vAnat(:));
    if(maxVal>255)
        %vAnat = mrAnatHistogramClipOptimal(vAnat);
        vAnat = mrAnatHistogramClip(vAnat, lowerClipLevel, upperClipLevel);
    else
        vAnat = vAnat./maxVal;
    end
    %minVal = min(vAnat(:));
    %vAnat = vAnat - minVal;
    %[count,value] = hist(vAnat(:),256);
    %upperClipVal = value(min(find(cumsum(count)./sum(count)>=upperClipLevel)));
    %vAnat(vAnat>upperClipVal) = upperClipVal;
    %lowerClipVal = value(max(find(cumsum(count)./sum(count)<=lowerClipLevel)));
    %if ~isempty(lowerClipVal)
    %    % Michael May's data had lowerCLipVal empty, which broke things
    %    % here.  So, I put in this test -- BW
    %    vAnat(vAnat<lowerClipVal) = lowerClipVal;
    %    vAnat = vAnat-lowerClipVal;
    %    scale = upperClipVal-lowerClipVal;
    %    vAnat = vAnat./scale;
    %end
   
    % set the default talairach file location, and load the old one if it exists.
    [p,f,e] = fileparts(fileName);
    if strcmp(e,'.gz')
        e = '.nii.gz';
        f = f(1:end-4);
    end
    newStyleName = fullfile(p,[f '_talairach.mat']);
    oldStyleName = fullfile(p,'talairach.mat');
    handles.data.defaultFile = newStyleName;
    if(exist(newStyleName, 'file'))
        oldTal = load(newStyleName);
    elseif(exist(oldStyleName, 'file'))
        oldTal = load(oldStyleName);
    end
    
    handles.data.vAnat = vAnat;
    %handles.data.vAnatSize = vSize([2,1,3]);
    handles.data.vAnatSize = vSize;
    handles.data.vAnatOriginalFile = fileName;
    handles.data.mmPerPixOriginal = mmPerPix;
    
    % Set the slice view values and edit texts
    handles.data.curSlice = round(handles.data.vAnatSize([3,2,1]) / 2);
    %handles.data.curSlice = round(handles.data.vAnatSize / 2);
    set(handles.coronalEdit,'String',num2str(handles.data.curSlice(1)));
    set(handles.axialEdit,'String',num2str(handles.data.curSlice(2)));
    set(handles.sagittalEdit,'String',num2str(handles.data.curSlice(3)));
    
    % set gamma default
    handles.data.displayGamma = 1.0;
    set(handles.gammaEdit, 'String', num2str(handles.data.displayGamma));
    handles.data.displayClip = [min(vAnat(:)) max(vAnat(:))];
    
    % For all the following coordinates, the following convention is used:
    % X = coronal slice num
    % Y = axial slice num
    % Z = sagittal slice num
    if(~isempty(oldTal))
        handles.data.acXYZ = oldTal.refPoints.acXYZ;
        handles.data.pcXYZ= oldTal.refPoints.pcXYZ;
        handles.data.aacXYZ = oldTal.refPoints.aacXYZ;
        handles.data.ppcXYZ= oldTal.refPoints.ppcXYZ;
        handles.data.lacXYZ = oldTal.refPoints.lacXYZ;
        handles.data.racXYZ= oldTal.refPoints.racXYZ;
        handles.data.sacXYZ = oldTal.refPoints.sacXYZ;
        handles.data.iacXYZ= oldTal.refPoints.iacXYZ;
        handles.data.midSagXYZ = oldTal.refPoints.midSagXYZ;
        handles.data.midSagPlaneNormalXYZ = oldTal.refPoints.midSagPlaneNormalXYZ;
    else
        handles.data.acXYZ = [];
        handles.data.pcXYZ= [];
        handles.data.aacXYZ = [];
        handles.data.ppcXYZ= [];
        handles.data.lacXYZ = [];
        handles.data.racXYZ= [];
        handles.data.sacXYZ = [];
        handles.data.iacXYZ= [];
        handles.data.midSagXYZ = [];
        handles.data.midSagPlaneNormalXYZ = [];
    end
    
    imageFigure = displayVAnat3Axis(vAnat, handles.data.curSlice, handles.data.displayGamma, handles.data.displayClip);
    handles.data.coronalFigNum = imageFigure(1);
    handles.data.axialFigNum = imageFigure(2);
    handles.data.sagittalFigNum = imageFigure(3);
    set(handles.data.coronalFigNum, 'KeyPressFcn', ['figure(',num2str(fig,100),');']);
    set(handles.data.axialFigNum, 'KeyPressFcn', ['figure(',num2str(fig,100),');']);
    set(handles.data.sagittalFigNum, 'KeyPressFcn', ['figure(',num2str(fig,100),');']);
    %    ['computeTalairach(''keypress_Callback'',',num2str(fig,100),',[],guidata(',num2str(fig,100),'));']);
    
    % Save the data to the figure structure for safe-keeping and easy access
	guidata(fig, handles);
    
    refreshImages(handles.data);
    updateControls(handles);

	if nargout > 0
		varargout{1} = fig;
	end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
	catch
		disp(lasterr);
	end

end


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.


% ***************************************************************************
%
% Pushbutton Callbacks
%
%****************************************************************************

% --------------------------------------------------------------------
function varargout = refreshButton_Callback(h, eventdata, handles, varargin)
refreshImages(handles.data);

% --------------------------------------------------------------------
function varargout = helpButton_Callback(h, eventdata, handles, varargin)
web('http://white.stanford.edu/labmanual/talairach.html');

% --------------------------------------------------------------------
function varargout = ACbutton_Callback(h, eventdata, handles, varargin)
% Specify anterior commisure point
if(~isempty(handles.data.ppcXYZ) | ~isempty(handles.data.aacXYZ) | ~isempty(handles.data.sacXYZ))
    ansButton = questdlg('Are you sure you want to change the AC point? This will reset other points.', ...
        'Reset points confirmation', 'Yes', 'No', 'Yes');
    if(strcmp(ansButton,'No'))
        return;
    end
    handles.data.ppcXYZ = [];
    handles.data.aacXYZ = [];
    handles.data.sacXYZ = [];
    handles.data.iacXYZ = [];
    handles.data.lacXYZ = [];
    handles.data.racXYZ = [];
    handles.data.midSagXYZ = [];
end
handles.data.acXYZ = getPoint([handles.data.coronalFigNum,handles.data.axialFigNum,handles.data.sagittalFigNum], handles.data.curSlice);
handles.data.curSlice = handles.data.acXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = PCbutton_Callback(h, eventdata, handles, varargin)
% Specify posterior commisure point
if(~isempty(handles.data.ppcXYZ) | ~isempty(handles.data.aacXYZ) | ~isempty(handles.data.sacXYZ))
    ansButton = questdlg('Are you sure you want to change the PC point? This will reset other points.', ...
        'Reset points confirmation', 'Yes', 'No', 'Yes');
    if(strcmp(ansButton,'No'))
        return;
    end
    handles.data.ppcXYZ = [];
    handles.data.aacXYZ = [];
    handles.data.sacXYZ = [];
    handles.data.iacXYZ = [];
    handles.data.lacXYZ = [];
    handles.data.racXYZ = [];
    handles.data.midSagXYZ = [];
end
handles.data.pcXYZ = getPoint([handles.data.coronalFigNum,handles.data.axialFigNum,handles.data.sagittalFigNum], handles.data.curSlice);
handles.data.curSlice = handles.data.pcXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = PPCbutton_Callback(h, eventdata, handles, varargin)
% Specify posterior to the PC point
xyz = getPoint([handles.data.coronalFigNum,handles.data.axialFigNum,handles.data.sagittalFigNum], handles.data.curSlice);
% We need to place the point on the ac-pc line (ie. project to the nearest point on that line)
handles.data.ppcXYZ = round(nearestPointLine(handles.data.acXYZ, handles.data.pcXYZ, xyz));
handles.data.curSlice = handles.data.ppcXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = AACbutton_Callback(h, eventdata, handles, varargin)
% Specify anterior to the AC point
xyz = getPoint([handles.data.coronalFigNum,handles.data.axialFigNum,handles.data.sagittalFigNum], handles.data.curSlice);
% We need to place the point on the ac-pc line (ie. project to the nearest point on that line)
handles.data.aacXYZ = round(nearestPointLine(handles.data.acXYZ, handles.data.pcXYZ, xyz));
handles.data.curSlice = handles.data.aacXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = midSagButton_Callback(h, eventdata, handles, varargin)
% Specify mid-sagittal point
if(~isempty(handles.data.sacXYZ) | ~isempty(handles.data.iacXYZ) ...
        | ~isempty(handles.data.lacXYZ) | ~isempty(handles.data.racXYZ))
    ansButton = questdlg('Are you sure you want to change the mid sagittal point? This will reset other points.', ...
        'Reset points confirmation', 'Yes', 'No', 'Yes');
    if(strcmp(ansButton,'No'))
        return;
    end
    handles.data.sacXYZ = [];
    handles.data.iacXYZ = [];
    handles.data.lacXYZ = [];
    handles.data.racXYZ = [];
end
handles.data.midSagXYZ = [];
handles.data.curSlice = [handles.data.acXYZ(1),handles.data.curSlice(2:3)];
refreshImages(handles.data);
updateControls(handles);
figure(handles.data.coronalFigNum);
[z,y] = ginput(1);
z = z(1);
y = y(1);
x = handles.data.curSlice(1);
% We need to place the point on a perpendicular to the ac-pc line 
handles.data.midSagXYZ = round(nearestLinePerpendicular(handles.data.acXYZ, handles.data.pcXYZ, [x,y,z]));
% compute the normal to the mid-sagittal plane (used to constrain LAC and RAC)
midSagNormal = cross((handles.data.pcXYZ - handles.data.acXYZ), ...
                     (handles.data.midSagXYZ - handles.data.pcXYZ));
% slide the mid-sagittal normal vector to be colinear with the ac:
handles.data.midSagPlaneNormalXYZ = handles.data.acXYZ - midSagNormal;
handles.data.curSlice = handles.data.midSagXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = SACbutton_Callback(h, eventdata, handles, varargin)
% Specify superior to the AC point
xyz = getPoint([handles.data.coronalFigNum,handles.data.axialFigNum,handles.data.sagittalFigNum], handles.data.curSlice);
% We need to place the point on the ac-midSag line (ie. project to the nearest point on that line)
handles.data.sacXYZ = round(nearestPointLine(handles.data.acXYZ, handles.data.midSagXYZ, xyz));
handles.data.curSlice = handles.data.sacXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = IACbutton_Callback(h, eventdata, handles, varargin)
% Specify inferior to the AC point
xyz = getPoint([handles.data.coronalFigNum,handles.data.axialFigNum,handles.data.sagittalFigNum], handles.data.curSlice);
% We need to place the point on the ac-midSag line (ie. project to the nearest point on that line)
handles.data.iacXYZ = round(nearestPointLine(handles.data.acXYZ, handles.data.midSagXYZ, xyz));
handles.data.curSlice = handles.data.iacXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = LACbutton_Callback(h, eventdata, handles, varargin)
% Specify left of the AC point
xyz = getPoint([handles.data.coronalFigNum,handles.data.axialFigNum,handles.data.sagittalFigNum], handles.data.curSlice);
% We need to project to nearest the point on the perpedicular to the ac-midSag line 
handles.data.lacXYZ = round(nearestPointLine(handles.data.acXYZ, handles.data.midSagPlaneNormalXYZ, xyz));
handles.data.curSlice = handles.data.lacXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = RACbutton_Callback(h, eventdata, handles, varargin)
% Specify right of the AC point
xyz = getPoint([handles.data.coronalFigNum,handles.data.axialFigNum,handles.data.sagittalFigNum], handles.data.curSlice);
% We need to project to nearest the point on the perpedicular to the ac-midSag line 
handles.data.racXYZ = round(nearestPointLine(handles.data.acXYZ, handles.data.midSagPlaneNormalXYZ, xyz));
handles.data.curSlice = handles.data.racXYZ;
% store updated data
guidata(h, handles);
% refresh the figure
refreshImages(handles.data);
updateControls(handles);

% --------------------------------------------------------------------
function varargout = saveButton_Callback(h, eventdata, handles, varargin)
refPoints.acXYZ = handles.data.acXYZ;
refPoints.pcXYZ = handles.data.pcXYZ;
refPoints.aacXYZ = handles.data.aacXYZ;
refPoints.ppcXYZ = handles.data.ppcXYZ;
refPoints.lacXYZ = handles.data.lacXYZ;
refPoints.racXYZ = handles.data.racXYZ;
refPoints.sacXYZ = handles.data.sacXYZ;
refPoints.iacXYZ = handles.data.iacXYZ;
refPoints.midSagXYZ = handles.data.midSagXYZ;
refPoints.midSagPlaneNormalXYZ = handles.data.midSagPlaneNormalXYZ;
refPoints.mat = handles.data.mat;
if(~isempty(refPoints.sacXYZ) && ~isempty(refPoints.iacXYZ) ...
        && ~isempty(refPoints.lacXYZ) && ~isempty(refPoints.racXYZ))
    % Find the transform that gets us from vAnatomy coordinates to
    % Talairach coordinates. First, we have an affine transform 
    % (rotation & translation, scale)
    %  talairachCoords = T * vAnatCoords
    % to find this, we can use matlab's backslash operator. As long as we
    % give it three orthogonal vectors, this will work.
    % But first we have to convert our coords to homogeneous coords
    % (ie. into a 4d space at x,y,z,1). 
    %
    vAnatH = [[refPoints.acXYZ,1]; [refPoints.ppcXYZ,1]; [refPoints.sacXYZ,1]; [refPoints.lacXYZ,1]];
    % Undo the initial coordinate transform.
    % We also have to do an axis-swap (Y->Z, X->Y, Z->X). Why? because it
    % works! I suspect there is a hidden permute somewhere along the line.
    % However, these permutes are typically X,Y swaps. I'm not sure how Z
    % got involved this time. Oh well...
    if(any(handles.data.axesCAS~=[3,1,2]))
        % The coords are in coronal, axial, sagittal order (for silly
        % historical reasons). So, we swap them around to put them in the
        % Talairach sagittal, coronal, axial order.
        % However, we only need to do this for the analyze-format data. 
        % The vAnatomies, which have axesCAS=[3,1,2], 
        % are messed up if we apply this transform. 
        % To be honest, I don't understand why there should be a 
        % difference. Something is screwed up, but the whole project
        % should probably be overhauled to fix it...
        vAnatH = vAnatH(:,[3,1,2,4]);
        % (this is eqivalent to adding another 1/0 xform to the mess below)
    end
    % 2004.07.01 RFD: the following breaks axial analyze data but
    % works with sagittals.
    vAnatH = ([0 0 1 0; 1 0 0 0; 0 1 0 0; 0 0 0 1]*inv(handles.data.mat)*vAnatH')';
    %vAnatH = (inv(handles.data.mat)*vAnatH')';
    talairachH = [0,0,0,1; 0,-102,0,1; 0,0,72,1; -62,0,0,1];
    v2tTransRot = vAnatH \ talairachH
%     p = spm_imatrix(v2tTransRot);
%     p(10:12) = 0;   % Force skews to zero
    
    
    % we have 7 separate scale factors. Note that in Talairach space, the axes are
    % (X,Y,Z) with:
    %   X = sagittal slice (right is +)
    %   Y = coronal slice (anterior is +)
    %   Z = axial slice (superior is +)
    t = [refPoints.sacXYZ,1]*v2tTransRot;
    vol2Tal.superiorAcScale = 72/t(3);
    t = [refPoints.iacXYZ,1]*v2tTransRot;
    vol2Tal.inferiorAcScale = -42/t(3);
    t = [refPoints.lacXYZ,1]*v2tTransRot;
    vol2Tal.leftAcScale = -62/t(1);
    t = [refPoints.racXYZ,1]*v2tTransRot;
    vol2Tal.rightAcScale = 62/t(1);
    t = [refPoints.aacXYZ,1]*v2tTransRot;
    vol2Tal.anteriorAcScale = 68/t(2);
    t = [refPoints.pcXYZ,1]*v2tTransRot;
    vol2Tal.betweenAcPcScale = -24/t(2);
    % unlike the other points, the PPC is referenced to the PC
    % It is at Talairach (0,-102,0) and the PC is at (0,-24,0),
    % so it is 78 mm beyond the PC.
    t = [refPoints.ppcXYZ,1]*v2tTransRot;
    vol2Tal.posteriorPcScale = -78/(t(2) + 24/vol2Tal.betweenAcPcScale);
    vol2Tal.transRot = v2tTransRot;
else
    uiwait(warndlg(['You haven''t specified all the points. No ',...
            'transform will be saved, just the currently specified points.'],...
            'No transform warning','modal'));
    vol2Tal = [];
end
handles.data.tal.refPoints = refPoints;
handles.data.tal.vol2Tal = vol2Tal;
guidata(h, handles);
[filename, pathname] = uiputfile(handles.data.defaultFile, 'Save Talairach data as');
if isequal(filename,0)|isequal(pathname,0)
    disp('File NOT saved.');
    global data;
    data = handles.data;
    disp(['data is available via: global data']);
else
    save([pathname,filename], 'refPoints', 'vol2Tal');
    disp(['File ', pathname, filename, ' has been saved.'])
end
return;

% --------------------------------------------------------------------
function varargout = coronalPrevButton_Callback(h, eventdata, handles, varargin)
updateSliceView(h, handles, [-1 0 0]);

% --------------------------------------------------------------------
function varargout = coronalNextButton_Callback(h, eventdata, handles, varargin)
updateSliceView(h, handles, [1 0 0]);

function varargout = coronalEdit_Callback(h, eventdata, handles, varargin)
newVal = str2num(get(h,'String'));
updateSliceView(h, handles, [newVal-handles.data.curSlice(1) 0 0]);

% --------------------------------------------------------------------
function varargout = axialPrevButton_Callback(h, eventdata, handles, varargin)
updateSliceView(h, handles, [0 -1 0]);

% --------------------------------------------------------------------
function varargout = axialNextButton_Callback(h, eventdata, handles, varargin)
updateSliceView(h, handles, [0 1 0]);

% --------------------------------------------------------------------
function varargout = axialEdit_Callback(h, eventdata, handles, varargin)
newVal = str2num(get(h,'String'));
updateSliceView(h, handles, [0 newVal-handles.data.curSlice(2) 0]);

% --------------------------------------------------------------------
function varargout = sagittalPrevButton_Callback(h, eventdata, handles, varargin)
updateSliceView(h, handles, [0 0 -1]);

% --------------------------------------------------------------------
function varargout = sagittalNextButton_Callback(h, eventdata, handles, varargin)
updateSliceView(h, handles, [0 0 1]);

% --------------------------------------------------------------------
function varargout = sagittalEdit_Callback(h, eventdata, handles, varargin)
newVal = str2num(get(h,'String'));
updateSliceView(h, handles, [0 0 newVal-handles.data.curSlice(3)]);

% --------------------------------------------------------------------
function varargout = gammaEdit_Callback(h, eventdata, handles, varargin)
newVal = str2num(get(h,'String'));
if(newVal>0 & newVal<10)
    handles.data.displayGamma = newVal;
else
    disp([mfilename,'gamma out of range (0>gamma>10)']);
end
% update view
refreshImages(handles.data);
updateControls(handles);
guidata(h, handles);


% --------------------------------------------------------------------
function varargout = keypress_Callback(h, eventdata, handles, varargin)
% Stub for Callback when a key is pressed in the figure.
% This doesn't seem to work very well
key = get(h,'CurrentCharacter');
switch key
case {',','<'}, updateSliceView(h, handles, [-1 0 0]);
case {'.','>'}, updateSliceView(h, handles, [1 0 0]);
case {'k','K'}, updateSliceView(h, handles, [0 -1 0]);
case {'l','L'}, updateSliceView(h, handles, [0 1 0]);
case {'o','O'}, updateSliceView(h, handles, [0 0 -1]);
case {'p','P'}, updateSliceView(h, handles, [0 0 1]);
end

% --------------------------------------------------------------------
function updateSliceView(h, handles, sliceNumAdjustment)
% adjust
handles.data.curSlice = handles.data.curSlice + sliceNumAdjustment;
% constrain to bounds
over = find(handles.data.curSlice > handles.data.vAnatSize);
handles.data.curSlice(over) = handles.data.vAnatSize(over);
under = find(handles.data.curSlice < 1);
handles.data.curSlice(under) = 1;
% update view
updateControls(handles);
sliceUpdate = handles.data.curSlice;
% The display routine will not bother refreshing views with a sliceNum of 0,
% so we zero out the views that didn't change.
sliceUpdate(find(sliceNumAdjustment==0)) = 0;
refreshImages(handles.data, sliceUpdate);
figure(handles.data.controlFigNum);
% store updated data
guidata(h, handles);


% ***************************************************************************
%
% refreshImages
%
%****************************************************************************
function refreshImages(data, sliceUpdate)
% We take the optional second argument to allow callers to specify which
% slice views to update.
if(~exist('sliceUpdate','var'))
    sliceUpdate = data.curSlice;
end
displayVAnat3Axis(data.vAnat, sliceUpdate, data.displayGamma, data.displayClip, ...
    [data.coronalFigNum,data.axialFigNum,data.sagittalFigNum]);

% Draw and label the points 
% X = coronal slice num, Y = axial slice num, Z = sagittal slice num
plotPointXYZ(data.acXYZ, sliceUpdate(1), 1, 'AC', data.coronalFigNum);
plotPointXYZ(data.pcXYZ, sliceUpdate(1), 1, 'PC', data.coronalFigNum);
plotPointXYZ(data.ppcXYZ, sliceUpdate(1), 1, 'PPC', data.coronalFigNum);
plotPointXYZ(data.aacXYZ, sliceUpdate(1), 1, 'AAC', data.coronalFigNum);
plotPointXYZ(data.sacXYZ, sliceUpdate(1), 1, 'SAC', data.coronalFigNum);
plotPointXYZ(data.iacXYZ, sliceUpdate(1), 1, 'IAC', data.coronalFigNum);
plotPointXYZ(data.lacXYZ, sliceUpdate(1), 1, 'LAC', data.coronalFigNum);
plotPointXYZ(data.racXYZ, sliceUpdate(1), 1, 'RAC', data.coronalFigNum);
if(~isempty(data.pcXYZ) & ~isempty(data.acXYZ) & sliceUpdate(1))
    % draw the ac-pc line
    plotLine(data.acXYZ, data.pcXYZ, [data.curSlice(1), 0, 0], data.coronalFigNum);
end
if(~isempty(data.midSagXYZ) & sliceUpdate(1))
    % draw the mid-sagittal and left-right perpendiculars
    plotLine(data.acXYZ, data.midSagXYZ, [data.curSlice(1), 0, 0], data.coronalFigNum);
    plotLine(data.acXYZ, data.midSagPlaneNormalXYZ, [data.curSlice(1), 0, 0], data.coronalFigNum);
end

plotPointXYZ(data.acXYZ, sliceUpdate(2), 2, 'AC', data.axialFigNum);
plotPointXYZ(data.pcXYZ, sliceUpdate(2), 2, 'PC', data.axialFigNum);
plotPointXYZ(data.ppcXYZ, sliceUpdate(2), 2, 'PPC', data.axialFigNum);
plotPointXYZ(data.aacXYZ, sliceUpdate(2), 2, 'AAC', data.axialFigNum);
plotPointXYZ(data.sacXYZ, sliceUpdate(2), 2, 'SAC', data.axialFigNum);
plotPointXYZ(data.iacXYZ, sliceUpdate(2), 2, 'IAC', data.axialFigNum);
plotPointXYZ(data.lacXYZ, sliceUpdate(2), 2, 'LAC', data.axialFigNum);
plotPointXYZ(data.racXYZ, sliceUpdate(2), 2, 'RAC', data.axialFigNum);
if(~isempty(data.pcXYZ) & ~isempty(data.acXYZ) & sliceUpdate(2))
    % draw the ac-pc line
    plotLine(data.acXYZ, data.pcXYZ, [0, data.curSlice(2), 0], data.axialFigNum);
end
if(~isempty(data.midSagXYZ) & sliceUpdate(2))
    % draw the mid-sagital and left-right perpendiculars
    plotLine(data.acXYZ, data.midSagXYZ, [0, data.curSlice(2), 0], data.axialFigNum);
    plotLine(data.acXYZ, data.midSagPlaneNormalXYZ, [0, data.curSlice(2), 0], data.axialFigNum);
end

plotPointXYZ(data.acXYZ, sliceUpdate(3), 3, 'AC', data.sagittalFigNum);
plotPointXYZ(data.pcXYZ, sliceUpdate(3), 3, 'PC', data.sagittalFigNum);
plotPointXYZ(data.ppcXYZ, sliceUpdate(3), 3, 'PPC', data.sagittalFigNum);
plotPointXYZ(data.aacXYZ, sliceUpdate(3), 3, 'AAC', data.sagittalFigNum);
plotPointXYZ(data.sacXYZ, sliceUpdate(3), 3, 'SAC', data.sagittalFigNum);
plotPointXYZ(data.iacXYZ, sliceUpdate(3), 3, 'IAC', data.sagittalFigNum);
plotPointXYZ(data.lacXYZ, sliceUpdate(3), 3, 'LAC', data.sagittalFigNum);
plotPointXYZ(data.racXYZ, sliceUpdate(3), 3, 'RAC', data.sagittalFigNum);
if(~isempty(data.pcXYZ) & ~isempty(data.acXYZ) & sliceUpdate(3))
    % draw the ac-pc line
    plotLine(data.acXYZ, data.pcXYZ, [0, 0, data.curSlice(3)], data.sagittalFigNum);
end
if(~isempty(data.midSagXYZ) & sliceUpdate(3))
    % draw the mid-sagital and left-right perpendiculars
    plotLine(data.acXYZ, data.midSagXYZ, [0, 0, data.curSlice(3)], data.sagittalFigNum);
    plotLine(data.acXYZ, data.midSagPlaneNormalXYZ, [0, 0, data.curSlice(3)], data.sagittalFigNum);
end

figure(data.controlFigNum);
return;

% ***************************************************************************
%
% updateControls
%
%****************************************************************************
function updateControls(handles);
if(~isempty(handles.data.acXYZ))
    set(handles.ACXedit, 'String', num2str(handles.data.acXYZ(1)));
    set(handles.ACYedit, 'String', num2str(handles.data.acXYZ(2)));
    set(handles.ACZedit, 'String', num2str(handles.data.acXYZ(3)));
else
    set(handles.ACXedit, 'String', '');
    set(handles.ACYedit, 'String', '');
    set(handles.ACZedit, 'String', '');
end
if(~isempty(handles.data.pcXYZ))
    set(handles.PCXedit, 'String', num2str(handles.data.pcXYZ(1)));
    set(handles.PCYedit, 'String', num2str(handles.data.pcXYZ(2)));
    set(handles.PCZedit, 'String', num2str(handles.data.pcXYZ(3)));
else
    set(handles.PCXedit, 'String', '');
    set(handles.PCYedit, 'String', '');
    set(handles.PCZedit, 'String', '');
end
if(~isempty(handles.data.ppcXYZ))
    set(handles.PPCXedit, 'String', num2str(handles.data.ppcXYZ(1)));
    set(handles.PPCYedit, 'String', num2str(handles.data.ppcXYZ(2)));
    set(handles.PPCZedit, 'String', num2str(handles.data.ppcXYZ(3)));
else
    set(handles.PPCXedit, 'String', '');
    set(handles.PPCYedit, 'String', '');
    set(handles.PPCZedit, 'String', '');
end
if(~isempty(handles.data.aacXYZ))
    set(handles.AACXedit, 'String', num2str(handles.data.aacXYZ(1)));
    set(handles.AACYedit, 'String', num2str(handles.data.aacXYZ(2)));
    set(handles.AACZedit, 'String', num2str(handles.data.aacXYZ(3)));
else
    set(handles.AACXedit, 'String', '');
    set(handles.AACYedit, 'String', '');
    set(handles.AACZedit, 'String', ''); 
end
if(~isempty(handles.data.midSagXYZ))
    set(handles.midSagXedit, 'String', num2str(handles.data.midSagXYZ(1)));
    set(handles.midSagYedit, 'String', num2str(handles.data.midSagXYZ(2)));
    set(handles.midSagZedit, 'String', num2str(handles.data.midSagXYZ(3)));
else
    set(handles.midSagXedit, 'String', '');
    set(handles.midSagYedit, 'String', '');
    set(handles.midSagZedit, 'String', '');
end
if(~isempty(handles.data.sacXYZ))
    set(handles.SACXedit, 'String', num2str(handles.data.sacXYZ(1)));
    set(handles.SACYedit, 'String', num2str(handles.data.sacXYZ(2)));
    set(handles.SACZedit, 'String', num2str(handles.data.sacXYZ(3)));
else
    set(handles.SACXedit, 'String', '');
    set(handles.SACYedit, 'String', '');
    set(handles.SACZedit, 'String', '');
end
if(~isempty(handles.data.iacXYZ))
    set(handles.IACXedit, 'String', num2str(handles.data.iacXYZ(1)));
    set(handles.IACYedit, 'String', num2str(handles.data.iacXYZ(2)));
    set(handles.IACZedit, 'String', num2str(handles.data.iacXYZ(3)));
else
    set(handles.IACXedit, 'String', '');
    set(handles.IACYedit, 'String', '');
    set(handles.IACZedit, 'String', '');
end
if(~isempty(handles.data.lacXYZ))
    set(handles.LACXedit, 'String', num2str(handles.data.lacXYZ(1)));
    set(handles.LACYedit, 'String', num2str(handles.data.lacXYZ(2)));
    set(handles.LACZedit, 'String', num2str(handles.data.lacXYZ(3)));
else
    set(handles.LACXedit, 'String', '');
    set(handles.LACYedit, 'String', '');
    set(handles.LACZedit, 'String', '');    
end
if(~isempty(handles.data.racXYZ))
    set(handles.RACXedit, 'String', num2str(handles.data.racXYZ(1)));
    set(handles.RACYedit, 'String', num2str(handles.data.racXYZ(2)));
    set(handles.RACZedit, 'String', num2str(handles.data.racXYZ(3)));
else
    set(handles.RACXedit, 'String', '');
    set(handles.RACYedit, 'String', '');
    set(handles.RACZedit, 'String', '');
end

set(handles.coronalEdit,'String',num2str(handles.data.curSlice(1)));
set(handles.axialEdit,'String',num2str(handles.data.curSlice(2)));
set(handles.sagittalEdit,'String',num2str(handles.data.curSlice(3)));

set(handles.gammaEdit, 'String', num2str(handles.data.displayGamma));

if(~isempty(handles.data.acXYZ) & ~isempty(handles.data.pcXYZ))
    set(handles.PPCbutton, 'Enable', 'on');
    set(handles.AACbutton, 'Enable', 'on');
    set(handles.midSagButton, 'Enable', 'on');
else
    set(handles.PPCbutton, 'Enable', 'off');
    set(handles.AACbutton, 'Enable', 'off');
    set(handles.midSagButton, 'Enable', 'off');
end
if(~isempty(handles.data.midSagXYZ))
    set(handles.SACbutton, 'Enable', 'on');
    set(handles.IACbutton, 'Enable', 'on');
    set(handles.LACbutton, 'Enable', 'on');
    set(handles.RACbutton, 'Enable', 'on');
else
    set(handles.SACbutton, 'Enable', 'off');
    set(handles.IACbutton, 'Enable', 'off');
    set(handles.LACbutton, 'Enable', 'off');
    set(handles.RACbutton, 'Enable', 'off');
end

return;


% ***************************************************************************
%
% plotPointXYZ
%
% Plots a point in the specified figNum, but only if xyz is not empty, and
% if curSlice==xyz(sliceAxis). It also figures out how to translate 3d xyz
% coords to local figure 2d xy coords.
%
%****************************************************************************
function plotPointXYZ(xyz, curSlice, sliceAxis, labelText, figNum)
if(isempty(xyz))
    return;
end
if(curSlice==xyz(sliceAxis))
    figure(figNum);
    switch(sliceAxis)
    case 1, % Coronal- so local x,y = xyz(3),xyz(2)
        x = xyz(3);
        y = xyz(2);
    case 2, % Axial- so local x,y = xyz(3),xyz(1)
        x = xyz(3);
        y = xyz(1);
    case 3, % Sagittal- so local x,y = xyz(1),xyz(2)
        x = xyz(1);
        y = xyz(2);
    end
    hold on; plot(x, y,'bo'); hold off;
    h = text(x-4, y-6, labelText);
    set(h(1),'Color', 'white'); set(h(1),'FontWeight', 'bold');
    h = text(x-5, y-7, labelText);
    set(h(1),'Color', 'blue'); set(h(1),'FontWeight', 'bold');
end
return;


% ***************************************************************************
%
% plotLine
%
%****************************************************************************
function plotLine(xyz0, xyz1, planeP0, figNum)
% plots any oblique line on the given slice.
% xyz0 and xyz1 are the two points defining the line. 
% planeP0 is a point on the plane. Since the plane is assumed to be a slice
% coplanar with one of the three axes, we can define it by this one point.
% This parameter _must_ be a 1x3 vector with exactly one non-zero element.
% Think of it as specifying the origin of the slice. (eg [10,0,0] specifies
% the 10th x-axis slice, while [0,0,77] specifies z-axis slice 77.
%
% Here's the math:
%   u = line.P0 - line.P1; % two points that form our line
%   w = line.P0 - plane.P0;
%   D = plane.normal * u; 
% plane.normal can be computed as n=u*v where u and v are direction vectors
% staring at the origin point of the plane, plane.P0. (ie. (V1-V0) X (V2-V1)
% where V0 V1 and V2 are all points in the plane (vertices of a triangle)).
% But, since our plane is a single slice, we can just select a point in the
% plane- the origin will do:
%    plane.V0 = [0 0 curSlice(3)];
% and a point in an adjacent slice that would form the perpendicular:
%    plane.n = plane.V0 + [0 0 1];
% 
% N = -(plane.n * w);
% if(abs(D) < SMALL_NUM)
%   if(N==0) % line lies in plane
%   else % line and plane are disjoint
% end
% % they are not parallel- compute intersection
% I = line.P0 + (N/D) * u;

u = xyz0 - xyz1;
%planeP0 = [0, data.curSlice(2), 0];
nzIndex = find(planeP0>0);
if(length(nzIndex) > 1)
    error([mfileName,': planeP0 must have only one non-zero element.']);
end
% add one to the non-zero element
planeNormal = planeP0 + (planeP0>0);
w = xyz0 - planeP0;
D = planeNormal * u';
N = -(planeNormal * w');
if(round(D)==0)
    if(N==0)
        % line lies in the plane
        % make the line long (100*u is arbitrary, but seems to work)
        line0 = xyz0 + 100*u;
        line1 = xyz1 - 100*u;
    else
        % line and plane are disjoint
        line0 = [];
        line1 = [];
    end
else
    I = xyz0 + (N/D) * u;
    % find intersecting point of the slice below this one
    planeP0_lo = planeP0 - (planeP0>0);
    planeNormal = planeP0_lo + (planeP0>0);
    w = xyz0 - planeP0_lo;
    D = planeNormal * u';
    N = -(planeNormal * w');
    I_lo = xyz0 + (N/D) * u;
    % find intersecting point of the slice above this one
    planeP0_hi = planeP0 + (planeP0>0);
    planeNormal = planeP0_hi + (planeP0>0);
    w = xyz0 - planeP0_hi;
    D = planeNormal * u';
    N = -(planeNormal * w');
    I_hi = xyz0 + (N/D) * u;
    %line0 = floor(I + (I - I_lo) / 2);
    %line1 = ceil(I + (I - I_hi) / 2);
    line0 = I + (I - I_lo) / 2;
    line1 = I + (I - I_hi) / 2;
end
if(~isempty(line0))
    figure(figNum);
    % we have to be careful here, converting our x,y,z point to 
    % the appropriate 2-d coordinate frame for the particular slice view.
    switch nzIndex
    case 1, h = line([line0(3), line1(3)], [line0(2), line1(2)]);
    case 2, h = line([line0(3), line1(3)], [line0(1), line1(1)]);
    case 3, h = line([line0(1), line1(1)], [line0(2), line1(2)]);
    end
    set(h,'LineWidth',2);
    set(h,'Color','blue');
end
return;


% ***************************************************************************
%
% nearestPointLine
%
% Projects the point xyz3 to the line defined by xyz1 and xyz2.
%
%****************************************************************************
function xyzNearest = nearestPointLine(xyz1, xyz2, xyz3)
%
% The equation of a line defined through two points P1 (x1,y1,z1) and P2 (x2,y2,z2) is 
% P = P1 + u (P2 - P1) 
% The point P3 (x3,y3,z3) is closest to the line at the tangent to the line 
% which passes through P3. That is, the dot product of the tangent and line is 0, thus:
% (P3 - P) dot (P2 - P1) = 0 
%
% Substituting the equation of the line gives:
% [P3 - P1 - u(P2 - P1)] dot (P2 - P1) = 0 
%
% Solving this gives the value of u:
%  
%  u = ((x3-x1)*(x2-x1) + (y3-y1)*(y2-y1) + (z3-z1)*(z2-z1))/norm(p2-p1)^2
%
% Substituting this into the equation of the line gives the point of 
% intersection (x,y,z) of the tangent as 
%   x = x1 + u (x2 - x1) 
%   y = y1 + u (y2 - y1) 
%   z = z1 + u (z2 - z1)
%

if(norm(xyz2 - xyz1)==0)
    error([mfilename,': points are coincident!']);
else
    s = sum((xyz3 - xyz1) .* (xyz2 - xyz1));
    u =  s / norm(xyz2 - xyz1)^2;
    xyzNearest = xyz1 + u * (xyz2 - xyz1);
end
return;


% ***************************************************************************
%
% nearestLinePerpendicular
%
% Finds the perpendicular to the line defined by xyz1 and xyz2 that goes
% as close as possible to the point xyz3 and passes through xyz1.
%
%****************************************************************************
function xyzPerp = nearestLinePerpendicular(xyz1, xyz2, xyz3)
% first, find the nearest point on the line, nearestXYZ.
% The line defined by xyz3 and xyzNearest will necessarily be 
% perpendicular to the xyz1, xyz2 line.
xyzNearest = nearestPointLine(xyz1, xyz2, xyz3);
% Now, slide the point (along the line) to the point xyz1.
xyzPerp = xyz3 - (xyzNearest - xyz1);


% ***************************************************************************
%
% getPoint
%
% Allows the user to first select a figure (valid figNums are listed
%   in validFigNums). Then, it uses ginput to let the user select a point
%   in that figure. The figures are assumed to be 3 orthogonal views of
%   a 3d dataset, so x,y,z are inferred from the inplane x,y and the figNum.
%
% validFigNums must be 1x3, where the figure for the first (x) axis is first,
% the figure for the y axis is second, and the figure for the z axis is last.
% If any of these are zero, then the user won't be allowed to select from
% that figure.
%
%****************************************************************************
function xyz = getPoint(validFigNums, curSlice)
figNum = 0;
while(~figNum & ~any(figNum==validFigNums))
    waitforbuttonpress;
    figNum = gcf;
end
figNumIndex = find(figNum==validFigNums);

[inplaneX, inplaneY] = ginput(1);
switch figNumIndex
case 1, xyz = round([curSlice(figNumIndex),inplaneY,inplaneX]);
case 2, xyz = round([inplaneY,curSlice(figNumIndex),inplaneX]);
case 3, xyz = round([inplaneX,inplaneY,curSlice(figNumIndex)]);
end
return;


% ***************************************************************************
%
% figure1_CloseRequestFcn
%
%****************************************************************************
function varargout = figure1_CloseRequestFcn(h, eventdata, handles, varargin)
% Stub for CloseRequestFcn of the figure handles.figure1.
closereq
eval('close(handles.data.coronalFigNum);','');
eval('close(handles.data.axialFigNum);','');
eval('close(handles.data.sagittalFigNum);','');


function P = spm_imatrix(M)
% returns the parameters for creating an affine transformation
% FORMAT P = spm_imatrix(M)
% M      - Affine transformation matrix
% P      - Parameters (see spm_matrix for definitions)
%___________________________________________________________________________
% @(#)spm_imatrix.m	2.1 John Ashburner & Stefan Kiebel 98/12/18

% Translations and zooms
%-----------------------------------------------------------------------
R         = M(1:3,1:3);
C         = chol(R'*R);
P         = [M(1:3,4)' 0 0 0  diag(C)'  0 0 0];
if det(R)<0, P(7)=-P(7);end % Fix for -ve determinants

% Shears
%-----------------------------------------------------------------------
C         = diag(diag(C))\C;
P(10:12)  = C([4 7 8]);
R0        = spm_matrix([0 0 0  0 0 0 P(7:12)]);
R0        = R0(1:3,1:3);
R1        = R/R0;

% This just leaves rotations in matrix R1
%-----------------------------------------------------------------------
%[          c5*c6,           c5*s6, s5]
%[-s4*s5*c6-c4*s6, -s4*s5*s6+c4*c6, s4*c5]
%[-c4*s5*c6+s4*s6, -c4*s5*s6-s4*c6, c4*c5]

P(5) = asin(rang(R1(1,3)));
if (abs(P(5))-pi/2).^2 < 1e-9,
	P(4) = 0;
	P(6) = atan2(-rang(R1(2,1)), rang(-R1(3,1)/R1(1,3)));
else,
	c    = cos(P(5));
	P(4) = atan2(rang(R1(2,3)/c), rang(R1(3,3)/c));
	P(6) = atan2(rang(R1(1,2)/c), rang(R1(1,1)/c));
end;
return;

% There may be slight rounding errors making b>1 or b<-1.
function a = rang(b)
a = min(max(b, -1), 1);
return;

function [A] = spm_matrix(P)
% returns an affine transformation matrix
% FORMAT [A] = spm_matrix(P)
% P(1)  - x translation
% P(2)  - y translation
% P(3)  - z translation
% P(4)  - x rotation about - {pitch} (radians)
% P(5)  - y rotation about - {roll}  (radians)
% P(6)  - z rotation about - {yaw}   (radians)
% P(7)  - x scaling
% P(8)  - y scaling
% P(9)  - z scaling
% P(10) - x affine
% P(11) - y affine
% P(12) - z affine
%
% A     - affine transformation matrix
%___________________________________________________________________________
%
% spm_matrix returns a matrix defining an orthogonal linear (translation,
% rotation, scaling or affine) transformation given a vector of
% parameters (P).  The transformations are applied in the following order:
%
% 1) translations
% 2) rotations
% 3) scaling
% 4) affine
%
% SPM uses a PRE-multiplication format i.e. Y = A*X where X and Y are 4 x n
% matrices of n coordinates.
%
%__________________________________________________________________________
% @(#)spm_matrix.m	1.1 95/08/07

% pad P with 'null' parameters
%---------------------------------------------------------------------------
q  = [0 0 0 0 0 0 1 1 1 0 0 0];
P  = [P q((length(P) + 1):12)];
A  = eye(4);

A  = A*[1 	0 	0 	P(1);
        0 	1 	0 	P(2);
        0 	0 	1 	P(3);
        0 	0 	0 	1];

A  = A*[1    0   	0   	   0;
        0    cos(P(4))  sin(P(4))  0;
        0   -sin(P(4))  cos(P(4))  0;
        0    0    	0   	   1];

A  = A*[cos(P(5))  0   	sin(P(5))  0;
        0    	   1    0  	   0;
       -sin(P(5))  0  	cos(P(5))  0;
        0          0    0   	   1];

A  = A*[cos(P(6))   sin(P(6))   0  0;
       -sin(P(6))   cos(P(6))   0  0;
        0           0           1  0;
        0     	    0    	0  1];

A  = A*[P(7) 	0   	0    	0;
        0    	P(8) 	0    	0;
        0    	0    	P(9) 	0;
        0    	0    	0    	1];

A  = A*[1   	P(10)   P(11)   0;
        0   	1 	P(12)   0;
        0   	0   	1	0;
        0    	0    	0    	1];

return;


% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuFileClose_Callback(hObject, eventdata, handles)
data = handles.data;

figure(data.coronalFigNum); close(data.coronalFigNum);
figure(data.axialFigNum);   close(data.axialFigNum);
figure(data.sagittalFigNum);close(data.sagittalFigNum)

closereq;

return;

