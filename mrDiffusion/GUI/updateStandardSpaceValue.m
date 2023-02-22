function handles = updateStandardSpaceValue(handles, acpcCoord)
% Get the standard space popup string and set the position appropriately.
% This code needs better comments.  I did a little below, but ...
%
% Pulled out of dtiFiberUI
%
% Brian (c) VISTASOFT Team, 2012.  

% The acpc coordinate was either passed in, or we get it from the position
if(~exist('acpcCoord','var'))
    acpcCoord = str2num(get(handles.editPosition, 'String'));
end

% Determine the standard space.
ssVals = get(handles.popupStandardSpace,'String');
curSs  = ssVals{get(handles.popupStandardSpace,'Value')};
curPosSs = '';
if(strcmpi(curSs,'Image'))
    % What the heck is this?  
    % OK, so Bob made handles.bg a structure.  One of the fields is .mat,
    % which contains a matrix.  This matrix apparently transforms data from
    % somewhere to somewhere else.  This code, which was worse before,
    % inverts the .mat matrix from the currently selected bg.
    %
    % This should Probably be something like
    %   acpc2img = dtiGet(handles,'acpc2img')
    %   curPosSs = mrAnatomXformCoords(acpc2img);  
    T = inv(handles.bg(get(handles.popupBackground,'Value')).mat);
    curPosSs = mrAnatXformCoords(T, acpcCoord);
elseif(strcmpi(curSs,'Talairach'))
    % Talairach version instead of general transform as above.
    curPosSs = mrAnatAcpc2Tal(handles.talairachScale, acpcCoord);
else
    % Check for other standard spaces
    if(isfield(handles,'t1NormParams')&&~isempty(handles.t1NormParams))
        normSs = strmatch(curSs,{handles.t1NormParams(:).name});
        if(~isempty(normSs))
            if(~isfield(handles.t1NormParams(normSs),'coordLUT') || isempty(handles.t1NormParams(normSs).coordLUT))
                
                lutFile = dtiGetFilenameInDT6(handles.dataFile,'lutMNI');
                if(exist(lutFile,'file') && ~isempty(lutFile))
                    disp(['Loading inverse deformation from ' lutFile '...']);
                    ni = niftiRead(lutFile);
                    handles.t1NormParams(normSs).coordLUT = squeeze(ni.data(:,:,:,1,:));
                    handles.t1NormParams(normSs).inMat = ni.qto_ijk;
                    clear ni;
                else
                    lutFile = fullfile(handles.dataDir,[curSs, '_coordLUT.nii.gz']);
                    disp('Computing inverse deformation...');
                    set(handles.editPositionTal, 'String', 'computing...');pause(0.1);
                    [defX, defY, defZ] = mrAnatInvertSn(handles.t1NormParams(normSs).sn);
                    if(max(abs(defX(:)))<127.5 && max(abs(defY(:)))<127.5 && max(abs(defZ(:)))<127.5)
                        defX(isnan(defX)) = -127; defY(isnan(defY)) = -127; defZ(isnan(defZ)) = -127;
                        handles.t1NormParams(normSs).coordLUT = int8(round(cat(4,defX,defY,defZ)));
                    else
                        defX(isnan(defX)) = -999; defY(isnan(defY)) = -999; defZ(isnan(defZ)) = -999;
                        handles.t1NormParams(normSs).coordLUT = int16(round(cat(4,defX,defY,defZ)));
                    end
                    handles.t1NormParams(normSs).inMat = inv(handles.t1NormParams(normSs).sn.VF.mat);
                    % NIFTI_INTENT_DISPVECT=1006
                    intentCode = 1006;
                    intentName = ['To' curSs];
                    % NIFTI format requires that the 4th dim is always
                    % time, so we put the deformation vector [x,y,z] in the
                    % 5th dimension.
                    tmp = reshape(handles.t1NormParams(normSs).coordLUT,[size(defX) 1 3]);
                    try
                        dtiWriteNiftiWrapper(tmp,inv(handles.t1NormParams(normSs).inMat),lutFile,1,'',intentName,intentCode);
                        dtiSetFilenameInDT6(handles.dataFile,'lutMNI',lutFile);
                    catch
                        disp('Could not save LUT transform- check permissions.');
                    end
                end
            end
            curPosSs = mrAnatXformCoords(handles.t1NormParams(normSs), acpcCoord);
        end
    end
    % Try an MNI label map
    if(isempty(curPosSs))
        % strmatch will be deprecated.  Figure out what this does and
        % replace it with strcmp
        mniSs = strmatch('MNI',{handles.t1NormParams(:).name});
        curPosSs = dtiGetBrainLabel(mrAnatXformCoords(handles.t1NormParams(mniSs), acpcCoord), curSs);
    end
end
if(isnumeric(curPosSs)), curPosSs = sprintf('%.0f, %.0f, %.0f', round(curPosSs)); end
set(handles.editPositionTal, 'String', curPosSs);

return
