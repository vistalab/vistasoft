% example_meshscript: 
%
% quick script to collect a bunch of mesh images automagically, and save in
% the 'Images/' folder. This loops across different data types (which in
% this case represent different population receptive field models), and
% loops across maps produced by each pRF model (the variance explained, the
% polar angle, eccentricity, and pRF size), THEN loops across different
% view angles for each hemisphere, taking a snapshot and saving it as an
% PNG image with a stereotyped name. The images should then be easy to sort
% through. The final line calls a separate function (also included as an
% example) which then loads these images, and compsites the results across
% hemispheres into a PowerPoint file.
%
%
% ras, 080408.
rois = {'aFus_faces' 'pFus_faces' 'FBA_event' 'aEBA' ...
		'sEBA'  'TOS_event' 'PPA' ...
		'MT.mat' 'STS_faces_event'}; 
meshes = {'s3_left_new_football' 's3_right_new_football'};	
dtNames = {'CheckerboardAverages' 'HouseAverages' 'FaceAverages' 'Averages' ...
		   'Odd' 'Even' 'FaceOdd' 'FaceEven' 'HouseOdd' 'HouseEven' ...
		   'CheckerboardOdd' 'CheckerboardEven'};
meshViews = { {'VentralZoom' 'Medial' 'LateralOccipital'} ...
			  {'VentralZoom' 'Medial' 'LateralOccipital'} };
fields = {'co' 'map' 'ph' 'amp'};
fieldNames = {'Variance Explained' 'Eccentricity' 'Polar Angle' 'pRF Diameter'};
lr = 'LR';  leftright = {'Left' 'Right'};  rightleft = {'right' 'left'};

%% open the view
mrvCleanWorkspace;
mrVista 3
% VOLUME{1} = prfLoadROIs(VOLUME{1}, rois);
for h = 1:2
	meshPath = fullfile('3DAnatomy', leftright{h}, '3DMeshes', meshes{h});
	VOLUME{1} = meshLoad(VOLUME{1}, meshPath, 1);
end


%% loop across data types, pRF models
for dt = dtNames
	VOLUME{1} = selectDataType(VOLUME{1}, dt{1});
	
	%% load the model / maps
	% (the 'prfLoadModel' function is a personal function: this calls the
	% 'rmSelect' function to load the most recent pRF model.)
% 	VOLUME{1} = prfLoadModel(VOLUME{1});
	VOLUME{1} = rmSelect(VOLUME{1}, 'mostrecent');
	
	%% loop across view fields
	for f = 1:length(fields)
		VOLUME{1} = setDisplayMode(VOLUME{1}, fields{f});
		
		% set viewing parameters appropriate to the field
		if isequal(fields{f}, 'co')
			VOLUME{1} = setCothresh(VOLUME{1}, 0.01); % minimal thresholding	
			VOLUME{1}.ui.coMode.clipMode = [0 .6];
		else
			VOLUME{1} = setCothresh(VOLUME{1}, 0.1); 
			VOLUME{1}.ui.coMode.clipMode = [0 .5];			
		end		
		
		%% loop across meshes (hemispheres)
		for h = 1:2
			if isequal(fields{f}, 'ph')
% 				VOLUME{1}.ui.phMode.cmap(129:end,:) = circshift(hsv(128), 32);
				VOLUME{1} = cmapPolarAngleRGB(VOLUME{1}, rightleft{h});
			else
				VOLUME{1} = setPhWindow(VOLUME{1}, [0 2*pi]);
			end	
			VOLUME{1}.meshNum3d = h;
			meshColorOverlay(VOLUME{1});

			%% loop across mesh view settings
			for j = 1:3
				meshRetrieveSettings(VOLUME{1}.mesh{h}, meshViews{h}{j});
				img = mrmGet(VOLUME{1}.mesh{h}, 'screenshot') ./ 255;
				saveName = sprintf('%s %sH %s %s.png',  meshViews{h}{j}, ...
									 lr(h), fieldNames{f}, dt{1});
				savePath = fullfile(pwd, 'Images', saveName);
				imwrite(img, savePath, 'png');
				fprintf('Saved %s.\n', savePath);
			end
		end
	end
end

example_prfMakePPTFromImages;
