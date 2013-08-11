function [labelTxt, labelNum] = dtiGetBrainLabel(ssCoords, labelType)
%
% labelTxt = dtiGetBrainLabel(ssCoords, labelType)
%
% Given the proper standard-space coordinates (usually MNI), returns the
% text label from a label map atlas. Call this function with no arguments
% to get a list of available label maps.
%
% E.g.:
% dtiGetBrainLabel([7 -95 0], 'MNI_AAL')      % returns 'Calcarine_R'
% dtiGetBrainLabel([7 -95 0], 'MNI_Brodmann') % returns 'Brodmann_Area_17'
%
% For help in getting an image-to-MNI transform, see the code snippets at
% the bottom of this file.
% 
% HISTORY:
% 2007.07.17 RFD: wrote it.
%

persistent labelMaps;

if(nargin==0)
   % Return a list of all available label maps. 
   labelTxt = getAvailableLabelMaps();
   return;
end

if(~exist('labelType','var')||isempty(labelType))
    labelType = 'MNI_AAL';
end

if(isempty(labelMaps))
    [labelMaps.availableMaps,labelMaps.mapDir] = getAvailableLabelMaps();
    labelMaps.maps = cell(size(labelMaps.availableMaps));
end

mapNum = strmatch(labelType,labelMaps.availableMaps);
if(isempty(mapNum))
    error(['Map type ''' labelType ''' not found.']);
end

if(isempty(labelMaps.maps)||isempty(labelMaps.maps{mapNum}))
    labelMaps.maps{mapNum} = niftiRead(fullfile(labelMaps.mapDir, [labelType '.nii.gz']));
    tmp = readTab(fullfile(labelMaps.mapDir, [labelType '.txt']),',',false);
    % FIXME- make this more robust
    labelMaps.maps{mapNum}.labelTxt = tmp(:,2);
end

ic = round(mrAnatXformCoords(labelMaps.maps{mapNum}.qto_ijk, double(ssCoords)));
% Do a boundary check before just using these coordinates to lookup
szMap = size(labelMaps.maps{mapNum}.data);
if any(ic>szMap) || any(ic<1)
    labelNum=0;
else
    labelNum = labelMaps.maps{mapNum}.data(ic(1),ic(2),ic(3));
end

if(labelNum>0)
    labelTxt = labelMaps.maps{mapNum}.labelTxt{labelNum};
else
    labelTxt = 'none';
end

return

function [availableMaps,mapDir] = getAvailableLabelMaps()
   mapDir = fileparts(which(mfilename));
   d = dir(fullfile(mapDir,'*.txt'));
   for(ii=1:length(d))
    [junk,availableMaps{ii}] = fileparts(d(ii).name);
   end
return



% To get labels for an individual brain:
mni = niftiRead('/home/bob/cvs/VISTASOFT/mrDiffusion/templates/MNI_T1.nii.gz');
t1 = niftiRead('/biac3/wandell4/data/reading_longitude/dti_adults/as050307/bin/backgrounds/t1.nii.gz');
% Compute the spatial normalization (maps template voxels to image voxels)
sn = mrAnatComputeSpmSpatialNorm(double(t1.data), t1.qto_xyz, mni);
% Invert the spatial norm to map image voxels to template voxels
[defX, defY, defZ] = mrAnatInvertSn(sn);
% Convert the image-to-template defomration to a compact look-up table.
% NOTE: to save space and time, we use int16.
defX(isnan(defX)) = 0; defY(isnan(defY)) = 0; defZ(isnan(defZ)) = 0;
coordLUT = int16(round(cat(4,defX,defY,defZ)));
intentCode = 1006;   % NIFTI_INTENT_DISPVECT=1006
intentName = 'ToMNI';
% NIFTI format requires that the 4th dim is always time, so we put the
% deformation vector [x,y,z] in the 5th dimension.
tmp = reshape(coordLUT,[size(defX) 1 3]);
lutFile = '/biac3/wandell4/data/reading_longitude/dti_adults/as050307/MNI_coordLUT.nii.gz';
dtiWriteNiftiWrapper(tmp,sn.VF.mat,lutFile,1,'',intentName,intentCode);

% To use the transform:
ni = niftiRead(lutFile);
xform.coordLUT = ni.data;
xform.inMat = ni.qto_ijk;
t1AcpcCoords = [5 -90 -4]; 
% to use native image-space coords: 
% t1AcpcCoords = mrAnatXformCoords(t1.qto_xyz,[86 31 57]);
mniCoords = mrAnatXformCoords(xform, t1AcpcCoords);
dtiGetBrainLabel(mniCoords, 'MNI_AAL')
dtiGetBrainLabel(mniCoords, 'MNI_Brodmann')
