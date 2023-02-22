function [pptPath status] = prfMakePPTFromImages(sessDir, dtNames);
% Using images created from the meshscript_[date] script for each object
% pRF session, create a power point deck with images from both hemispheres,
% for easy comparison.
%
%   [pptPath status] = prfMakePPTFromImages([sessDir=pwd], [dtNames]);
%
% ras, 08/2008.
if notDefined('sessDir'),	sessDir = pwd;			end
if notDefined('dtNames'),	
	dtNames = {'Averages' 'FaceAverages' 'HouseAverages' 'CheckerboardAverages'};
	
	% alternate: include odd/even subsets
% 	dtNames = {'Averages' 'FaceAverages' 'HouseAverages' 'CheckerboardAverages' ...
%			   'Odd' 'Even' 'FaceOdd' 'FaceEven' 'HouseOdd' 'HouseEven' ...
% 				'CheckerboardOdd' 'ChecerkboardEven'};	
end

%% get params
cd(sessDir);
load mrSESSION
sessName = mrSESSION.sessionCode;
fields = {'Variance Explained' 'Eccentricity' 'Polar Angle' 'pRF Diameter'};
viewAngles = {'Medial' 'LateralOccipital' 'VentralZoom'};
hemiOrder = {[2 1] [1 2] [2 1]}; % L=1, R=2: order on the slide

%% open the PPT file
pptFile = sprintf('pRF Mesh Images %s.ppt', sessName);
pptPath = fullfile(prfDir, 'results', pptFile);
[ppt op] = pptOpen(pptPath);

%% main loop
for dt = dtNames
	% make a title slide for this analysis
	hFig = figure('Color', 'w');
	axes; axis off;
	pptPaste(op, hFig, 'meta', dt{1});
	close(hFig);
	
	for v = viewAngles
		for f = fields
			% load the images
			lh = imread( sprintf('Images/%s LH %s %s.png', v{1}, f{1}, dt{1}) );
			rh = imread( sprintf('Images/%s RH %s %s.png', v{1}, f{1}, dt{1}) );			
			
			% display in a figure
			hFig = figure('Color', 'w', 'Units', 'norm', 'Position', [.1 .1 .8 .8]);
			hAx(1) = subplot('Position', [0 0 .5 1]);
			hAx(2) = subplot('Position', [.5 0 .5 1]);
			
			if isequal( hemiOrder{cellfind(viewAngles, v{1})}, [1 2] );
				% display left, then right
				axes(hAx(1));  imagesc(lh);  axis image;  axis off;  title('LH')
				axes(hAx(2));  imagesc(rh);  axis image;  axis off;  title('RH')
			else
				% display right, then left
				axes(hAx(1));  imagesc(rh);  axis image;  axis off;  title('RH')
				axes(hAx(2));  imagesc(lh);  axis image;  axis off;	 title('LH')			
			end
			
			% add a colorbar
			switch f{1}
				case 'Variance Explained',
					cmap = mrvColorMaps('blueredyellow', 256);
% 					cmap = hot(256);
					clim = [0 .8];
					colorWheel = 0;
				case 'Eccentricity',
					cmap = mrvColorMaps('hsvshort', 256);
					clim = [0 30];
					colorWheel = 0;
				case 'Polar Angle',
					cmap = hsv(256);
					clim = [0 360];
					colorWheel = 1;
				case 'pRF Diameter',
					cmap = flipud( mrvColorMaps('hsvshort', 256) );
% 					cmap = jet(256);
					clim = [0 15];
					colorWheel = 0;
			end
			cbar = cbarCreate(cmap, f{1}, 'Clim', clim, ...
							  'ColorWheel', colorWheel, ...
							  'ColorWheelStart', 180);
			hLeg = mrvPanel('below', .15);
			axes('Parent', hLeg, 'Units', 'norm', 'Position', [.3 .3 .4 .4]);
			cbarDraw(cbar, gca);
			
			% copy into PPT
			ttl = sprintf('%s %s', dt{1}, f{1});
			pptPaste(op, hFig, 'meta', ttl);
			
			% close figure
			close(hFig);
		end
	end
end

pptClose(op, ppt, pptPath);

fprintf('\n\n\t*** [%s]: All done! ***\n\n', mfilename);

return
