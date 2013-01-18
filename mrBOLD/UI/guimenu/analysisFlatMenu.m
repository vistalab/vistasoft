function view=analysisFlatMenu(view)
%
% view=analysisFlatMenu(view)
% 
% Set up the callbacks of the ANALYSIS menu for the FLAT view.
% 
% wap, 5/18/99
% arp, 052199 
%

analysismenu = uimenu('Label','Analysis','separator','on');

% Cortical distance measurement (prompt for user input)
callBackstr=['measureCorticalDistance(' view.name ');'];
uimenu(analysismenu,'Label','Measure cortical distance (select points)','Separator','off',...
    'CallBack',callBackstr);

% Cortical distance measurement (use current ROI)
callBackstr=['measureCorticalDistance(' view.name ', getCurROIcoords(' view.name ') );'];
uimenu(analysismenu,'Label','Measure cortical distance (current ROI)','Separator','off',...
    'CallBack',callBackstr);

% Cortical distance measurement- sub-sampling method (use current line ROI)
callBackstr=['measureCorticalDistanceLineROI(' view.name ', getCurROIcoords(' view.name ') );'];
uimenu(analysismenu,'Label','Measure cortical distance (subsamples ROI)','Separator','off',...
    'CallBack',callBackstr);

% Cortical distance measurement- Binning method (use current line ROI)
callBackstr=['measureCorticalDistanceBins(' view.name ', getCurROIcoords(' view.name ') , 4);'];
uimenu(analysismenu,'Label','Measure cortical distance (bins ROI, binDist=4mm)','Separator','off',...
    'CallBack',callBackstr);

% Cortical distance measurement- Binning method (use current line ROI)
callBackstr=['measureCorticalDistanceBins(' view.name ', getCurROIcoords(' view.name '));'];
uimenu(analysismenu,'Label','Measure cortical distance (bins ROI, specify binDist)','Separator','off',...
    'CallBack',callBackstr);


% Current ROI surface area measurement 
callBackstr=['measureFlatROIArea(' view.name ');'];
uimenu(analysismenu,'Label','ROI surface area (old, slow, inaccurate!)','Separator','on',...
    'CallBack',callBackstr);
callBackstr=[ view.name ' = measureFlatROIAreaMesh(' view.name ');'];
uimenu(analysismenu,'Label','ROI surface area (new mesh method)','Separator','off',...
    'CallBack',callBackstr);

%---------Atlas Version 2----------------------------------------------------

% atlasV2 = uimenu(analysismenu,'Label','Atlas (v. 2)','Separator','on');

% view = atlasCreate(atlasName, ringWedgeScans,view);
atlasCreate = uimenu(analysismenu,'Label','Create atlas','Separator','on');

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''Hemifield'',[],', view.name ');'];
uimenu(atlasCreate,'Label','Hemifield','Separator','off','CallBack',callBackstr);

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''uqf'',[],', view.name ');'];
uimenu(atlasCreate,'Label','upperquarterfield','Separator','off','CallBack',callBackstr);

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''lqf'',[],', view.name ');'];
uimenu(atlasCreate,'Label','lowerquarterfield','Separator','off','CallBack',callBackstr);

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''HemiLowerVF'',[],', view.name ');'];
uimenu(atlasCreate,'Label','HemiLowerVF','Separator','off','CallBack',callBackstr);

callBackstr = [ '[' view.name ' corners] = atlasCreate(''HemiUpperVF'',[],', view.name ');'];
uimenu(atlasCreate,'Label','HemiUpperVF (V3v/hV4)','Separator','off','CallBack',callBackstr);

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''V1/V2'',[],', view.name ');'];
uimenu(atlasCreate,'Label','V1/V2','Separator','off','CallBack',callBackstr);

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''V1/V2/V3'',[],', view.name ');'];
uimenu(atlasCreate,'Label','V1/V2/V3','Separator','off','CallBack',callBackstr);

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''ventralV2V3V4'',[],', view.name ');'];
uimenu(atlasCreate,'Label','V2v/V3v/V4v','Separator','off','CallBack',callBackstr);

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''V4/V8'',[],', view.name ');'];
uimenu(atlasCreate,'Label','V4/V8','Separator','off','CallBack',callBackstr);

% view = atlasCreate(atlasName, ringWedgeScans,view);
callBackstr = [ '[' view.name ' corners] = atlasCreate(''2hemifields'',[],', view.name ');'];
uimenu(atlasCreate,'Label','2 Hemifields (VO1/VO2)','Separator','off','CallBack',callBackstr);

callBackstr = [ '[' view.name ' corners] = atlasCreate(''4 hemifields'',[],', view.name ');'];
uimenu(atlasCreate,'Label','4 Hemifields (LO-1/2, TO-1/2)','Separator','off','CallBack',callBackstr);

%---------------------------------------------------------
% [view images] = makeAtlasData(view,[],[],corners);
callBackstr=[ '[' view.name  ' images] = makeAtlasData(' view.name ');'];
uimenu(analysismenu,'Label','Create data for the fitting GUI','Separator','off','CallBack',callBackstr);

% gui(images);
callBackstr=[ 'atlasfitGUI(images)'];
uimenu(analysismenu,'Label','Open the fitting GUI','Separator','off','CallBack',callBackstr);

% [images2 images3 images]= RawToCommonAtlas(images, corners, '/biac3/wandell4/data/MT/YM070815/safirData_left0706', '/biac3/wandell4/data/MT/YM070815/safirResult_left0706');
callBackstr=['images = loadPRFsize(' view.name ', images); [images images2 images3] = RawToCommonAtlas(images, corners, ''' pwd '/safirData'',''' pwd '/safirResult''); atlasStore(' view.name ',images)'];
uimenu(analysismenu,'Label','Create data type for the fitted atlas','Separator','off','CallBack',callBackstr);

% view = warpFromViews(view);
callBackstr=[ view.name ' = warpFromViews(' view.name ');'];
uimenu(analysismenu,'Label','Warp Atlas (Atlas view)','Separator','on','CallBack',callBackstr);

% Visual area ROI from atlas
% view = makeAreaROI(view);
callBackstr=[ view.name ' = makeAreaROI(' view.name ');'];
uimenu(analysismenu,'Label','Create Area ROI (Data view)','Separator','off','CallBack',callBackstr);

% view= atlasIsoAngleROIs(view);
callBackstr=[ view.name ' = atlasIsoAngleROIs(' view.name ');'];
uimenu(analysismenu,'Label','Iso-angle ROI (Data view)','Separator','off','CallBack',callBackstr);

% view= atlasIsoEccROIs(view);
callBackstr=[ view.name ' = atlasIsoEccROIs(' view.name ');'];
uimenu(analysismenu,'Label','Iso-eccentricity ROI (Data view)','Separator','off','CallBack',callBackstr);

% Atlas Error 
callBackstr=[ view.name ' = atlasError(' view.name ');'];
uimenu(analysismenu,'Label','Compute error (data view)','Separator','off',...
    'CallBack',callBackstr);

%--------------------------------------------------------------------------
% Cortical Magnification computation
callBackstr=[ view.name ' = measureCortMag(' view.name ');'];
uimenu(analysismenu, 'Label', 'Compute cortical magnification', 'Separator', 'on',...
    'CallBack', callBackstr);
callBackstr=[ view.name ' = measureCortMag(' view.name ', [], uigetfile);'];
uimenu(analysismenu, 'Label', 'Compute cortMag from file', 'Separator', 'off',...
    'CallBack', callBackstr);

%------------Atlas V. 1 (Old)---------------------------------------------------------
atlasOldmenu = uimenu(analysismenu,'Label','Atlas (v. 1)','Separator','on');
% Create Rectangle ROI with default name callback
%   view=newROI(view);
%   view=addROIrect(view,1);
%   view=refreshScreen(view,1);

% 2-D Atlas fitting 
callBackstr=['createAtlas(' view.name ');'];
uimenu(atlasOldmenu,'Label','Create Retinotopy Atlas (data view)','Separator','on',...
    'CallBack',callBackstr);

% 2-D Atlas phase adjustment
callBackstr=[ view.name ' = fixPhase(' view.name ');'];
uimenu(atlasOldmenu,'Label','Fix atlas phase (atlas view)','Separator','off',...
    'CallBack',callBackstr);

% 2-D Atlas affine transform
callBackstr=[ view.name ' = atlasAffineTransform(' view.name ');'];
uimenu(atlasOldmenu,'Label','Affine transform Atlas (atlas view)','Separator','off',...
    'CallBack',callBackstr);

% 2-D Atlas warping
callBackstr=[ view.name ' = warpFromViews(' view.name ');'];
uimenu(atlasOldmenu,'Label','Warp atlas (atlas view)','Separator','off',...
    'CallBack',callBackstr);
% Visual area ROI from atlas
callBackstr=[ view.name ' = makeAreaROI(' view.name ');'];
uimenu(atlasOldmenu,'Label','Create area ROI (data view)','Separator','off',...
    'CallBack',callBackstr);

% Iso-angle ROI from atlas
callBackstr=[ view.name ' = makeIsoAngleROIs(' view.name ');'];
uimenu(atlasOldmenu,'Label','Create iso-angle ROIs (data view)','Separator','off',...
    'CallBack',callBackstr);

% Iso-angle ROI from atlas
callBackstr=[ view.name ' = makeIsoEccenROIs(' view.name ');'];
uimenu(atlasOldmenu,'Label','Create iso-eccentricity ROIs (data view)','Separator','off',...
    'CallBack',callBackstr);

% Atlas Error Map
callBackstr=[ view.name ' = atlasErrorMap(' view.name ');'];
uimenu(atlasOldmenu,'Label','Compute error map (data view)','Separator','off',...
    'CallBack',callBackstr);

return;