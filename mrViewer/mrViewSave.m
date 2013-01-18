function ui = mrViewSave(ui, pth, type, format);
% Save MR data file / ROI / other data from a mrViewer UI to disk.
%
%   ui = mrViewSave([ui, pth, type, format]);
%
% ui: mrViewer UI struct. Finds the most current one if
% omitted.
%
% pth: path to the MR file/s to load. (see mrLoad.)
%
% type: flag for what type of data to load:
%       0:      save the newMR object as the new 'base' newMR object
%                    (stored in the ui.newMR field); the spaces,
%                    as well as any overlays/ROIs/ will need to be
%                    redefined in terms of this new space.
%       1 [default]: save a map in the ui.maps field (prompt user if more
%                    than one).
%       2:          save ROI.
%       3:          save space transformation information. Right now,
%                   this means loading a mrSESSION.alignment field. May
%                   become more general in the future.
%       4:          save stimulus files / parfiles.
%       5:          segmentation.
%       6:          mesh.
%       7:          mesh settings file.
% type can also be a string out of:
%   'base', 'map', 'roi', 'space', 'stim', 'segmentation', 'mesh'.
%   'meshsettings'.
%
% format: file format (see mrLoad). Usually, this can be omitted
% and will be inferred from the filename.
%
% ras 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;            end
if ishandle(ui),                     ui = get(ui,'UserData');   end
if ~exist('type','var') | isempty(type), type = 1;     end
if ~exist('pth', 'var') | isempty(pth), pth = ''; end

if ischar(type)
	typesList = {'base', 'map', 'roi', 'space', 'stim', 'segmentation', ...
		'mesh' 'meshsettings'};
	type = cellfind(typesList, lower(type))-1;
	if isempty(type)
		error('Invalid data type specified.')
	end
end



switch type
	case 0,
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% save base object:
		% adjust spaces accordingly. When overlays
		% and ROIs are added, will need to adjust these as
		% well.
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		mrSave(ui.mr, '', ui.mr.format);

	case 1,
		%%%%%%%%%%%%%%%%%
		% save a map    %
		%%%%%%%%%%%%%%%%%
		% N.Y.I.

	case 2,
		%%%%%%%%%%%%
		% Save ROI %
		%%%%%%%%%%%%
		% pth should be the index into the viewer's ROIs; 
		% we save in back-compatible mrVista 1 format for now.
		mrGlobals2;
		ROI = ui.rois(pth);
		
		if isequal(ROI.viewType, 'Inplane')
			saveDir = roiDir(INPLANE{1});
			inplane = fullfile(HOMEDIR, 'Inplane', 'anat.mat');
			ROI = roiCheckCoords(ROI, mrLoadHeader(inplane));
			
		elseif isequal(ROI.viewType, 'Volume')
			saveDir = roiDir(VOLUME{1}, 0); % save non-locally
			hdr = mrLoadHeader(vANATOMYPATH);
			ROI = roiCheckCoords(ROI, hdr);
			
		end
		
		roiPath = fullfile(saveDir, [ROI.name '.mat']);
		
		if exist(roiPath, 'file')
			q = sprintf('ROI %s exists. Save over this file?', roiPath);
			confirm = questdlg(q);
			if ~isequal(confirm, 'Yes'), disp('ROI not saved.'); return; end
		end
		
		save(roiPath, 'ROI');
		fprintf('Saved ROI %s. \n', roiPath);


	case 3,
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Save Space Transformation / Alignment %
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% N.Y.I.

	case 4, % save stim files / parfiles
		% N.Y.I.

	case 5, % save segmentation
		seg = mrViewGet(ui, 'segmentation');
		segPath = fullfile(fileparts(seg.class), 'segmentation.mat');
		save(segPath, 'seg');
		fprintf('Saved segmentation info in %s.\n', segPath);

	case 6,
		%%%%%%%%%%%%%
		% Save Mesh %
		%%%%%%%%%%%%%
		msh = mrViewGet(ui, 'CurMesh');
		if isempty(pth)
			p = sprintf('Save Mesh: %s', msh.name);
			pth = mrvSelectFile('w', 'mat', [], p, mrViewGet(ui, 'MeshDir'));
			if isempty(pth), return; end
		end
		[msh savePath] = mrmWriteMeshFile(msh, pth);

	case 7, % save mesh settings
		% N.Y.I.

end


return
