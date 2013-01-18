function roi = roiLoad(pth, format, referenceMR);
% Load a mrVista2 ROI.
%
% roi = roiLoad(<pth='dialog'>, <format='Inplane'>, <referenceMR>);
%
% Possible formats are 'Inplane' (mrVista Inplane ROI), 
% 'Volume' (mrVista Volume/Gray ROI), and 'mat' (saved MATLAB file,
% mrVista2 format).
%
% ras, 02/24/07.
if notDefined('pth')
	pth = mrvSelectFile('r', 'mat', [], 'Select an ROI to Load');
end

if notDefined('format'),	format = 'Inplane';		end

if exist(pth, 'file') | exist([pth '.mat'], 'file')
	roi = load(pth);
else
	error(sprintf('ROI path %s not found. ', pth))
end

% if we successfully loaded an ROI file, check for 
% the format: first check if it's a mrVista 1 ROI:
fields = fieldnames(roi);
if ismember(fields, 'ROI')
	% it's a mrVista 1 ROI: use mrVista-specific tools 
	% to parse it
	mrGlobals2;	
	roi = roi.ROI; % subsume ROI struct, only thing of interest
	if isequal(lower(roi.viewType), 'inplane')
		reference = 'Inplane';
		referenceMR = fullfile(HOMEDIR, 'Inplane', 'anat.mat');
		voxelSize = mrSESSION(1).inplanes.voxelSize;
	elseif ismember(lower(roi.viewType), {'volume', 'gray'})
		reference = 'I|P|R'; 
		if notDefined('referenceMR')
			referenceMR = mrLoadHeader(getVAnatomyPath);
		else
			referenceMR = mrParse(referenceMR);
		end
		voxelSize = referenceMR.voxelSize(1:3);
	else
		error('ROI view type not supported yet.')

	end

	template = roiCreate(reference, roi.coords, 'color', roi.color, ...
					'name', roi.name, 'voxelSize', voxelSize, ...
					'referenceMR', referenceMR);
	for f = setdiff( fieldnames(template), fieldnames(roi) )'
		roi.(f{1}) = template.(f{1});
	end
	
	for f = setdiff( fieldnames(roi), fieldnames(template) )'
		roi = rmfield(roi, f{1});
	end
				
	return
end

return

	