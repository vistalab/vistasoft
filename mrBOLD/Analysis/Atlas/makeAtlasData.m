function [vw images] = makeAtlasData(vw, p, varargin)
%
% Make atlas data for the use of fitting function written by Jens Heyder
% from the dataType (e.g. Atlases-1) created by 'createAtlas'. Once you get
% 'images', you can p.atlasType gui(images) to iniciate the fitting GUI by Jens
% Heyder
%
% [vw images] = makeAtlasData([vw], [params=get from dialog]);
%  
% OPTIONS: 
%	[atlasDt], [dataDt], [dataFields], [p.hemisphere], [corners], [gain], [p.atlasType]
%
% INPUT
%  vw: 
%  atlasDt: name of the data p.atlasType containing atlas data.
%  dataDt: name of the data p.atlasType containing the data to fit. [Default 'Averages']
%  p.hemisphere (1 for left and 2 for right) 
%  corners: corners of ROIs (created by "atlasCreate")
%  gain: modulation of angle relative to pi since you might want to get a
%        smaller angle modulation (default = [1 1]). Only for the atlas of
%        LO-1,2 TO-1,2.
%  p.atlasType: p.atlasType of the atlas. MT (default): remove the ecc of LO-1, MT2:
%        remove the ecc of LO-1 and TO-2. V1-3: This is because the cortical
%        magnification of LO-1 and TO-2 seems to be rather different from
%        LO-2 and TO-1. If you want to leave all atlases, specify the p.atlasType
%        name 'V1-3' or other names you want.
%
% OUTPUT
%  images: includes raw data (images.M1, images.M2), atlas (images.A1,
%  images.A2), and coherence data (images.W1, images.W2) and mask
%  (images.areasImg). 
%
% 08/03 KA wrote it
% 09/04 RAS extensive updates: consolidated the various parameters into a
% params struct, which can be passed in as a struct, as param/value pairs,
% or with a dialog; made more flexible in the allowed data types for the
% data and atlas; added mean-thresholding option.
if notDefined('vw'),	vw = getSelectedFlat;			end
if ~isequal(vw.viewType, 'Flat'), error('Requires Flat view p.atlasType.');	end


%% get default parameters
defaults = makeAtlasData_defaultParams(vw);

%% parse user parameter specification
if notDefined('p') | isequal(p, -1) | isequal(p, 'dialog')
	p = makeAtlasData_paramsGUI(vw, defaults);
else
	p = mergeStructures(defaults, p);
end

for ii = 1:2:length(varargin)
	p.(varargin{ii}) = varargin{ii+1};
end
	
%% make sure we have the corners
corners = makeAtlasData_getCorners(vw, p);

%% get the experimental data
[M1 M2 W1 W2] = makeAtlasData_getData(vw, p);

%% get the atlas data
[A1 A2 areasImg] = makeAtlasData_getModel(vw, p);

%%%%% old code here
% vw = selectDataType(vw,vw.curDataType);
% vw = loadCorAnal(vw);
% 
% M1=vw.ph{2}(:,:,p.hemisphere);
% M2=vw.ph{1}(:,:,p.hemisphere);
% W1=vw.co{2}(:,:,p.hemisphere);
% W2=vw.co{2}(:,:,p.hemisphere);
% 
% % Get Data for 'Atlas'
% vw = selectDataType(vw, atlasDt);
% vw = loadCorAnal(vw);
% 
% A1=vw.ph{2}(:,:,p.hemisphere);
% A2=vw.ph{1}(:,:,p.hemisphere);
% areasImg=vw.co{2}(:,:,p.hemisphere)+1;

% % angle template including LO1
% A3=vw.ph{2}(:,:,p.hemisphere);


%% I need to figure out what these adjustments here are for. (ras, 04/09)
if strcmp(p.atlasType,'MT')
    % for the new atlas with 6 ROIs (LO1/2, TO1/2 + wall of LO1 and TO2)

	% ras 04/9: the A3 definition is functionally the same statement as was present
	% before, but outside this if statement.
	A3 = A1; 
	
    for i=1:size(areasImg,1)
        for j=1:size(areasImg,2)
            % Eccentricity template only for LO2, TO1 and TO2
            %             if areasImg(i,j)==1 | areasImg(i,j)==2 | areasImg(i,j)==3 | areasImg(i,j)==4
            if areasImg(i,j)==2 || areasImg(i,j)==3 || areasImg(i,j)==4
                A1(i,j)=A1(i,j);
            else
                A1(i,j)=NaN;
            end
            if areasImg(i,j)==1 || areasImg(i,j)==2 || areasImg(i,j)==3 || areasImg(i,j)==4
                A3(i,j)=A3(i,j);
            else
                A3(i,j)=NaN;
            end
            if areasImg(i,j)==1 || areasImg(i,j)==2
                A2(i,j)=(A2(i,j)-pi/2)*gain(1) + pi/2;
            elseif areasImg(i,j)==3 || areasImg(i,j)==4
                A2(i,j)=(A2(i,j)-pi/2)*gain(2) + pi/2;
            else
                A2(i,j)=NaN;
            end
        end
    end
    
elseif strcmp(p.atlasType,'MT2') % ecc template only for LO2 and MT
    for i=1:size(areasImg,1)
        for j=1:size(areasImg,2)
            % Eccentricity template only for LO1, TO1 and TO2
            if areasImg(i,j)==2 || areasImg(i,j)==3
                A1(i,j)=A1(i,j);
            else
                A1(i,j)=NaN;
            end
            if areasImg(i,j)==1 || areasImg(i,j)==2
                A2(i,j)=(A2(i,j)-pi/2)*gain(1) + pi/2;
            elseif areasImg(i,j)==3 || areasImg(i,j)==4
                A2(i,j)=(A2(i,j)-pi/2)*gain(2) + pi/2;
            else
                A2(i,j)=NaN;
            end
        end
    end
    
elseif strcmp(p.atlasType,'V1-3')
    tmp = areasImg;
    tmp(areasImg==1)=3;% V1
    tmp(areasImg==2)=2;% V2v
    tmp(areasImg==3)=4;% V2d
    tmp(areasImg==4)=1;% V3v 
    tmp(areasImg==5)=5;% V3d    
    areasImg = tmp;
	
else
	% do we need to do this for other model types?
	
end

% For left hemishpre, flip angle data so that the angle is within the range
% between pi/2 and pi/2*3
if p.hemisphere==1
    M2=mod(pi-M2,2*pi);
%     A2=mod(pi-A2,2*pi);
end

% descard the data whose coherence is 0, which means no data
M1(W1==0)=0;
M2(W2==0)=0;
W1(W1==0)=0;
W2(W2==0)=0;

images.A1=A1; images.A2=A2; images.M1=M1; images.M2=M2;
images.W1=W1; images.W2=W2; images.CO=W1; images.areasImg=areasImg;
if exist('A3', 'var'), images.A3 = A3; end

%% plot data
images_size = size(images.A1,1);
figure('Color', 'w', 'Name', 'Atlas Fit Images');
subplot(231)
hold on
imagesc(images.M2)
% plot(corners{1}(:,1),corners{1}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{2}(:,1),corners{2}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{3}(:,1),corners{3}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{4}(:,1),corners{4}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{1}(2:3,1),corners{1}(2:3,2),'wo','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{3}(2:3,1),corners{3}(2:3,2),'wo','MarkerFaceColor','k','LineWidth', 2)
title( sprintf('Angle data: \n%s', p.dataDt) )
set(gca,'YDir','reverse');
axis([0 images_size 0 images_size])
axis equal
axis off

subplot(232)
hold on
imagesc(images.A2)
% plot(corners{1}(:,1),corners{1}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{2}(:,1),corners{2}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{3}(:,1),corners{3}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{4}(:,1),corners{4}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{1}(2:3,1),corners{1}(2:3,2),'wo','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{3}(2:3,1),corners{3}(2:3,2),'wo','MarkerFaceColor','k','LineWidth', 2)
title( sprintf('Angle atlas: \n%s', p.atlasDt) )
set(gca,'YDir','reverse');
axis([0 images_size 0 images_size])
axis equal
axis off

subplot(233)
hold on
imagesc(images.CO)
% plot(corners{1}(:,1),corners{1}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{2}(:,1),corners{2}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{3}(:,1),corners{3}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{4}(:,1),corners{4}(:,2),'ko','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{1}(2:3,1),corners{1}(2:3,2),'wo','MarkerFaceColor','k','LineWidth', 2)
% plot(corners{3}(2:3,1),corners{3}(2:3,2),'wo','MarkerFaceColor','k','LineWidth', 2)
set(gca,'YDir','reverse');
axis([0 images_size 0 images_size])
title('Atlas mask (coherence)')
axis equal
axis off

subplot(234)
hold on
imagesc(images.M1)
% plot(corners{3}(:,1),corners{3}(:,2),'w+','LineWidth', 2)
% plot(corners{4}(:,1),corners{4}(:,2),'w+','LineWidth', 2)
% plot(corners{1}(:,1),corners{1}(:,2),'k+','LineWidth', 2)
% plot(corners{2}(:,1),corners{2}(:,2),'k+','LineWidth', 2)
title( sprintf('Eccentricity data: \n%s', p.dataDt) )
set(gca,'YDir','reverse');
axis([0 images_size 0 images_size])
axis equal
axis off

subplot(235)
hold on
imagesc(images.A1)
% plot(corners{3}(:,1),corners{3}(:,2),'w+','LineWidth', 2)
% plot(corners{4}(:,1),corners{4}(:,2),'w+','LineWidth', 2)
% plot(corners{1}(:,1),corners{1}(:,2),'k+','LineWidth', 2)
% plot(corners{2}(:,1),corners{2}(:,2),'k+','LineWidth', 2)
title( sprintf('Eccentricity atlas: \n%s', p.atlasDt) )
set(gca,'YDir','reverse');
axis([0 images_size 0 images_size])
axis equal
axis off

subplot(236)
hold on
imagesc(images.areasImg)
% plot(corners{3}(:,1),corners{3}(:,2),'w+','LineWidth', 2)
% plot(corners{4}(:,1),corners{4}(:,2),'w+','LineWidth', 2)
% plot(corners{1}(:,1),corners{1}(:,2),'k+','LineWidth', 2)
% plot(corners{2}(:,1),corners{2}(:,2),'k+','LineWidth', 2)
title('Areas image')
set(gca,'YDir','reverse');
axis([0 images_size 0 images_size])
axis equal
axis off

colormap( mrvColorMaps('rgby', 256) );

% save data
if strcmp(p.atlasType,'MT') 
    if p.hemisphere==1
        tmp=strcat('save atlas_TO12_left_',datestr(now,1), ' images corners');
    else
        tmp=strcat('save atlas_TO12_right_',datestr(now,1), ' images corners');
    end
elseif strcmp(p.atlasType,'MT2') 
    if p.hemisphere==1
        tmp=strcat('save atlas_TO12_2_left_',datestr(now,1), ' images corners');
    else
        tmp=strcat('save atlas_TO12_2_right_',datestr(now,1), ' images corners');
    end
elseif strcmp(p.atlasType,'V1-3')
    if p.hemisphere==1
        tmp=strcat('save atlas_V1-3_left_',datestr(now,1), ' images corners');
    else
        tmp=strcat('save atlas_V1-3_right_',datestr(now,1), ' images corners');
    end
else
    if p.hemisphere==1
        tmp=strcat('save atlas_', p.atlasType, '_left_',datestr(now,1), ' images corners');
    else
        tmp=strcat('save atlas_', p.atlasType, '_right_',datestr(now,1), ' images corners');
    end
end
eval(tmp)

return;
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function corners = makeAtlasData_getCorners(vw, p)
%% find the corners used to define the different visual field
%% representations
% this used to require that the corners be passed in as an input
% argument. This in turn required that you do the fitting at the same time
% you generated the atlas, since the corners weren't saved anywhere. A
% recent update (4/2009) now saves the corners in a params file. So, if the
% corners have been passed in by the user, we use those values; otherwise,
% we look for the saved corners in the params file here. If this code can't
% find the corners, it errors, since we need the corners to proceed.
if isfield(p, 'corners') & ~isempty(p.corners)
	return
end

% if we got here, it wasn't specified by the user. Check for the file.
paramsFile = fullfile(viewDir(vw), p.atlasDt, 'atlasParams.mat');
if ~exist(paramsFile, 'file')
	error(['Can''t find visual field map corners. Variable not ' ...
		   'specified, and the params file (%s) not found. ' ...
		   'Can not proceed.'], paramsFile);
end

load(paramsFile, 'corners');

return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function p = makeAtlasData_defaultParams(vw)
% list of default parameter values for makeAtlasData.
mrGlobals;

p.dataSource = 'Traveling Wave Analysis';
if existDataType('Averages')
	p.dataDt = 'Averages';
else
	p.dataDt = getDataTypeName(vw);
end
p.dataPolScan = 1;
p.dataEccScan = 2;
p.dataPolField = 'ph';
p.dataEccField = 'ph';
tmp = strmatch('Atlas', {dataTYPES.name}); % guess this will be a suffix
if ~isempty(tmp)
	p.atlasDt = dataTYPES(tmp(1)).name;
else
	p.atlasDt = dataTYPES(end).name; % try the last data p.atlasType
end
p.prfModelFile = '';  % for when dataSource=='pRF Model'
p.hemisphere = viewGet(vw, 'Current Slice');
p.gain = [1 1];
p.atlasType = 'V1-3';
p.meanThresh = [];

return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function p = makeAtlasData_paramsGUI(vw, p)
% Dialog to allow the user to set parameters for the atlas model
if notDefined('p'),	p = makeAtlasData_defaultParams(vw);  end
mrGlobals;

%% build the dialog structure
dlg(1).fieldName		= 'dataSource';
dlg(end).style			= 'popup';
dlg(end).list			= {'Traveling Wave Analysis' 'pRF Model' 'Loaded Data'};
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Where are the data to be fit saved?';

dlg(end+1).fieldName	= 'dataDt';
dlg(end).style			= 'popup';
dlg(end).list			= {dataTYPES.name};
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Data p.atlasType for the data to fit?';

dlg(end+1).fieldName	= 'dataPolScan';
dlg(end).style			= 'number';
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Scan number for the polar angle data?';

dlg(end+1).fieldName	= 'dataEccScan';
dlg(end).style			= 'number';
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Scan number for the eccentricity data?';

dlg(end+1).fieldName	= 'dataPolField';
dlg(end).style			= 'popup';
dlg(end).list			= {'ph' 'map' 'amp' 'co'};
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Data field with the polar angle data (if using loaded data)?';

dlg(end+1).fieldName	= 'dataEccField';
dlg(end).style			= 'popup';
dlg(end).list			= {'ph' 'map' 'amp' 'co'};
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Data field with the eccentricity data (if using loaded data)?';

dlg(end+1).fieldName	= 'prfModelFile';
dlg(end).style			= 'filename';
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= ['If using pRF model, which model file? ' ...
						   '(enter -1 to load default file)'];

dlg(end+1).fieldName	= 'atlasDt';
dlg(end).style			= 'popup';
dlg(end).list			= {dataTYPES.name};
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Data p.atlasType containing the atlas model?';

dlg(end+1).fieldName	= 'hemisphere';
dlg(end).style			= 'popup';
dlg(end).list			= {'left' 'right'};
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Hemisphere to fit?';

dlg(end+1).fieldName	= 'atlasType';
dlg(end).style			= 'popup';
dlg(end).list			= {'V1-3' 'MT' 'MT2' 'other'};
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Type of atlas?';

dlg(end+1).fieldName	= 'gain';
dlg(end).style			= 'number';
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= 'Gain on [polar angle ecc], for incomplete coverage?';

dlg(end+1).fieldName	= 'meanThresh';
dlg(end).style			= 'number';
dlg(end).value			= p.(dlg(end).fieldName);
dlg(end).string			= ['Mask out values less than a given mean map ' ...
						   'intensity? (empty if no, otherwise enter ' ...
						   'threshold): '];

%% get a user response
[p ok] = generalDialog(dlg, 'Fit Data to Atlas');
if ~ok, error('User Aborted.');	end

%% parse any options which require additional processing
p.hemisphere = cellfind({'left' 'right'}, p.hemisphere);

return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function [M1 M2 W1 W2] = makeAtlasData_getData(vw, p)
% load the eccentricity and polar angle maps for the observed data.
% M1 -- eccentricity data
% M2 -- polar angle data
% W1 -- eccentricity weights (co or varexp)
% W2 -- polar angle weights (co or varexp)
vw = selectDataType(vw, p.dataDt);

%% load the data
switch lower(p.dataSource)
	case {'prf' 'prf model'}
		if ismember(p.prfModelFile, {char(-1) '-1' 'default'})
			p.prfModelFile = rmDefaultModelFile(vw);
		end
		
		if ~check4File(p.prfModelFile)
			% try to see if it's relative to the data directory
			p.prfModelFile = fullfile(dataDir(vw), p.prfModelFile);
		end
		
		if ~check4File(p.prfModelFile)
			% still not found? We have a problem.
			error('No pRF Model Found! Tried: %s', p.prfModelFile)
		end
		
		% load the pRF model
		load(p.prfModelFile, 'model');
		model = model{1};
		
		% get the polar angle and eccentricity maps
		M1 = rmGet(model, 'ecc');
		M2 = rmGet(model, 'pol');
		W1 = rmGet(model, 'varexp');
		W2 = rmGet(model, 'varexp'); % same for both maps
		
		M1 = M1(:,:,p.hemisphere);
		M2 = M2(:,:,p.hemisphere);
		W1 = W1(:,:,p.hemisphere);
		W2 = W2(:,:,p.hemisphere);
		
		
	case {'coranal' 'traveling wave analysis'}
		if ~check4File( fullfile(dataDir(vw), 'corAnal') )
			error('corAnal should be computed for data %s.', p.dataDt);
		end
		vw = loadCorAnal(vw);
		M1 = vw.ph{p.dataEccScan}(:,:,p.hemisphere);
		M2 = vw.ph{p.dataPolScan}(:,:,p.hemisphere);
		W1 = vw.co{p.dataEccScan}(:,:,p.hemisphere);
		W2 = vw.co{p.dataPolScan}(:,:,p.hemisphere);	
		
    	% TODO (possibly): check for the visual field mapping params, using
    	% retinoCheckParams, and convert M1 and M2 to real-world units if
    	% available. This would only be useful if the atlas fit was already
    	% in real-world units. (ras 04/09)
		
	case {'loaded data' 'vw'}
		M1 = vw.(p.dataEccField){p.dataEccScan}(:,:,p.hemisphere);
		M2 = vw.(p.dataPolField){p.dataPolScan}(:,:,p.hemisphere);
		W1 = vw.co{p.dataEccScan}(:,:,p.hemisphere);
		W2 = vw.co{p.dataPolScan}(:,:,p.hemisphere);		
		
	otherwise
		error('Invalid dataSource parameter.')
end
	
%% threshold by mean map if specified
if ~isempty(p.meanThresh)
	vw = loadMeanMap(vw);
	lowSignal = (vw.map{1}(:,:,p.hemisphere) < p.meanThresh);
	M1(lowSignal) = NaN;
	M2(lowSignal) = NaN;
	W1(lowSignal) = 0;
	W2(lowSignal) = 0;
end

	
return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function [A1 A2 areasImg] = makeAtlasData_getModel(vw, p)
% load the model maps from the atlas data.
vw = selectDataType(vw, p.atlasDt);
vw = loadCorAnal(vw);
A1 = vw.ph{2}(:,:,p.hemisphere); 
A2 = vw.ph{1}(:,:,p.hemisphere);
areasImg = vw.co{2}(:,:,p.hemisphere) + 1;
return

