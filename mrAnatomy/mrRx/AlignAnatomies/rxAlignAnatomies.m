function rx = rxAlignAnatomies(oldAnat, newAnat, niftiFlag1, niftiFlag2);
% Invoke mrRx for the purpose of aligning two anatomies.
%
% rx = rxAlignAnatomies([oldAnat], [newAnat], [niftiFlag1=0, niftiFlag2=0]);
%
% This function is intended to be for the situations where some analysis
% exists based on one anatomy, and you want to port parts of the analyses
% to a new anatomy. For instance, you could have mrVista ROIs,
% segmentations, or time series you want to resample. This is intended to
% provide a framework for doing these conversions. 
%
% This calls mrRx, setting the various size and resolution fields properly.
% It then adds a new 'Align Anatomies' menu with specialized options for
% moving various files from one anatomy to another. This was initially
% started to convert ROIs across anatomies, but I can foresee many other
% things to add: segmentations, venograms, gray time series, retinotopy
% models. 
%
% INPUTS: 
%	oldAnat and newAnat are the source and target anatomies to align. This uses the
%	mrVista 2 conventions for loading MR data: they may either be a loaded
%	mr struct (see mrLoad), or a path to a file that mrVista 2 can load.
%	These include ANALYZE, NIFTI, and DICOM files, as well as mrVista
%	anatomies, or mrGray .dat files. See mrLoad for a full list of formats.
%
%	oldAnat: This is the anatomy which already has analysis files (ROIs, etc)
%	defined on it. [default: prompt to select a file/files.]
%
%	newAnat: this is the anatomy to which you want to convert the analysis
%	files. [default: prompt to select a file/files.]
%
%   niftiFlag1 and niftiFlag2 are flags indicating that one or the other of
%   the anatomies is a NIFTI saved for analysis with mrVista. In mrVista,
%   ROIs and maps are stored in a dimensionally-flipped format to how the
%   anatomy is usually saved -- if you're saving the anatomy as a NIFTI
%   file. (If you use the older mrGray .dat file, there are no flips).
%   Setting either of these flags to 1 will cause the anatomy to be flipped
%   into the mrVista orientation ("I|P|R; see mrFormatDescription for 
%	more notes"), before going into mrRx. Set these flags to 1 only if you
%	want to convert mrVista files that are associated with a .nii or
%	.nii.gz format anatomy. [default: 0]
%
% When invoked, you will rotate/shift the newAnat volume to align to
% oldAnat. You may use and of the manual or automated alignment tools in
% mrRx. When you are happy with the alignment, you can select the options
% in the 'Align Anatomies' menu to choose files to convert over. You will
% be prompted for files to convert, then they will be converted using the
% current alignment. You can then choose where to save the files.
%
%
% ras, 11/18/2009.
if notDefined('oldAnat'),	oldAnat = mrLoad;			end
if notDefined('newAnat'),	newAnat = mrLoad;			end
if notDefined('niftiFlag1'), niftiFlag1 = 0;			end
if notDefined('niftiFlag2'), niftiFlag2 = 0;			end

oldAnat = mrParse(oldAnat);
newAnat = mrParse(newAnat);

if niftiFlag1==1
	oldAnat.data = mrAnatRotateAnalyze(oldAnat.data);
	oldAnat.dims = size(oldAnat.data);
end

if niftiFlag2==1
	newAnat.data = mrAnatRotateAnalyze(newAnat.data);
	newAnat.dims = size(newAnat.data);
end

% convert the data matrices to uint8 to save memory -- this should still
% allow us to align well.
oldAnat.data = uint8( rescale2(oldAnat.data, [], [0 255]) );
newAnat.data = uint8( rescale2(newAnat.data, [], [0 255]) );


% call mrRx
rx = mrRx(newAnat.data, oldAnat.data, 'volRes', newAnat.voxelSize(1:3), ...
		 'rxRes', oldAnat.voxelSize(1:3), 'refRes', oldAnat.voxelSize(1:3), ...
	  	 'volDims', newAnat.dims(1:3), 'rxDims', oldAnat.dims(1:3), ...
		 'refDims', newAnat.dims(1:3));

% add the alignment options menu	 
rx = rxAlignAnatomiesMenu(rx);

return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function rx = rxAlignAnatomiesMenu(rx);
% add alignment-specific menus.
rx.ui.alignAnatMenu = uimenu('Parent', rx.ui.controlFig, ...
							 'Label', 'Align Anatomies', ...
							 'Separator', 'on');

						 
% align ROIs callback
uimenu(rx.ui.alignAnatMenu, 'Label', 'Convert ROIs', ...
       'Separator', 'off', ...
       'Callback', 'rxAlignAnatomies_convertROIs;'); 

return
