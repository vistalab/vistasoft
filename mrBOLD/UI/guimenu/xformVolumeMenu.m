function view = xformVolumeMenu(view)

% view = xformVolumeMenu(view);
% 
% Set up the callbacks for the xformView menu in the volume view
% 
% djh, 1/9/98
% rmk, 1/10/99 added xform Parameter Map 
% rmk, 1/15/99 added xform all ROIs
% rfd&baw 02/16/99	added write mrGray ROI
% sjc, 2/19/99 added xform CorAnal (Volume->Gray) and write mrGray functional data overlay
% wap, 2/26/99 added submenus
% huk and wandell, 12/5/00, added checkCoordsNodes
% djh, 2/8/2001
%   - call various functions with local rather than global variables
%   - allow for multiple windows/structures of each viewType with different
%     names.
% ras, 1/06 broke each submenu into its own function (and in the inplane
%           case, did this with sub-submenus).
mrGlobals

xformMenu = uimenu('Label', 'Xform', 'Separator', 'on');

if (~strcmp(view.viewType,'GeneralVolumeData')) 
    % The point of the GVD view type is that it is not derived from 
    % INPLANE data.
    inplane2volumeMenu = uimenu(xformMenu, 'Label', 'Inplane->Volume', ...
                                'Separator', 'off');

    ipRoiSubmenu(view, inplane2volumeMenu);
    ipCorAnalSubmenu(view, inplane2volumeMenu);
    ipMapSubmenu(view, inplane2volumeMenu);
    ipTSeriesSubmenu(view, inplane2volumeMenu);
    ipOtherSubmenu(view, inplane2volumeMenu); % spatial gradient, ROI data
    ipRMSubmenu(view, inplane2volumeMenu);
end     


flatSubmenu(view, xformMenu);
flatLevelSubmenu(view, xformMenu);
mrGraySubmenu(view, xformMenu);
% bvSubmenu(view, xformMenu);  % none of the code is checked in
itkGraySubmenu(view, xformMenu);
analyzeSubmenu(view, xformMenu);
acrSessionsSubmenu(view, xformMenu);

return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function view = ipRoiSubmenu(view, inplane2volumeMenu);
% Submenu for xforming ROIs from Inplane -> Volume

% Xform ROI (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volCurROI(inplane,view);
%   view=refreshScreen(view,0);
%   clear inplane;
cb = ['inplane=checkSelectedInplane; ',...
      view.name,'=ip2volCurROI(inplane,',view.name,'); ',...
      view.name,'=refreshScreen(',view.name,',0); ' ...
      'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','ROI (selected)','Separator','off',...
    'CallBack',cb);

% Xform All ROIs (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volAllROIs(inplane,view);
%   view=refreshScreen(view,0);
cb = ['inplane=checkSelectedInplane; ',...
      view.name,'=ip2volAllROIs(inplane,',view.name,'); ',...
      view.name,'=refreshScreen(',view.name,',0); ' ...
      'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','ROIs (all)','Separator','off',...
    'CallBack',cb);
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function view = ipCorAnalSubmenu(view, inplane2volumeMenu);
% Sub-submenu for xforming corAnals from inplane -> volume.

% Xform CorAnal all scans (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volCorAnal(inplane,view,0);
%   view=refreshScreen(view,1);
%   clear inplane;
cb=['inplane=checkSelectedInplane; ',...
        view.name,'=ip2volCorAnal(inplane,',view.name,',0); ',...
        view.name,'=refreshScreen(',view.name,',1);' ...
        'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','CorAnal (all scans)','Separator','on',...
    'CallBack',cb);

% Xform CorAnal current scan (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volCorAnal(inplane,view,getCurScan(view));
%   view=refreshScreen(view,1);
cb=['inplane=checkSelectedInplane; ',...
        view.name,'=ip2volCorAnal(inplane,',view.name,',getCurScan(',view.name,')); ',...
        view.name,'=refreshScreen(',view.name,',1);' ...
        'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','CorAnal (current scan)','Separator','off',...
    'CallBack',cb);

% Xform CorAnal select scans (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volCorAnal(inplane,view);
%   view=refreshScreen(view,1);
cb=['inplane=checkSelectedInplane; ',...
        view.name,'=ip2volCorAnal(inplane,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',1);' ...
        'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','CorAnal (select scans)','Separator','off',...
    'CallBack',cb);
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function view = ipMapSubmenu(view, inplane2volumeMenu);
% Sub-submenu for xforming parameter maps from inplane -> volume.

%%%%%%%%%%%%%%%%%%%%
% (1) All scans    %
%%%%%%%%%%%%%%%%%%%%
xformMenuMapAll = uimenu(inplane2volumeMenu,'Label',...
                         'Parameter Map (all scans)','Separator','on');

%%%%%nearest-neighbor interpolation, all scans
% ip = checkSelectedInplane; 
% view = ip2volParMap(ip, view, 0, [], 'nearest'); 
% view = setDisplayMode(view, 'map');
% view = refreshScreen(view);
% clear ip
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, 0, [], ''nearest''); ', ...
              view.name, view.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', view.name, view.name) ...
      'clear ip '];
uimenu(xformMenuMapAll, 'Label', 'Nearest-neighbor Interpolation', ....
            'Separator', 'off', 'CallBack', cb);

%%%%%linear interpolation, all scans
% ip = checkSelectedInplane; 
% view = ip2volParMap(ip, view, 0, [], 'linear'); 
% view = setDisplayMode(view, 'map');
% view = refreshScreen(view);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, 0, [], ''linear''); ', ...
              view.name, view.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', view.name, view.name) ...
      'clear ip;'];
uimenu(xformMenuMapAll, 'Label', 'Trilinear Interpolation', ...
        'Separator', 'off', 'CallBack', cb);
    

%%%%%%%%%%%%%%%%%%%%
% (2) Current scan %
%%%%%%%%%%%%%%%%%%%%
xformMenuMapCur = uimenu(inplane2volumeMenu,'Label',...
                         'Parameter Map (current scan)','Separator','off');

%%%%%nearest-neighbor interpolation, current scan
% ip = checkSelectedInplane; 
% view = ip2volParMap(ip, view, getCurScan(view), [], 'nearest'); 
% view = setDisplayMode(view, 'map');
% view = refreshScreen(view);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, viewGet(%s, ''curScan''), [], ''nearest''); ', ...
              view.name, view.name, view.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', view.name, view.name) ...
      'clear ip; '];
uimenu(xformMenuMapCur, 'Label', 'Nearest-neighbor Interpolation', ...
        'Separator', 'off', 'Callback',cb);

%%%%%linear interpolation, current scan
% ip = checkSelectedInplane; 
% view = ip2volParMap(ip, view, getCurScan(view), [], 'linear'); 
% view = setDisplayMode(view, 'map');
% view = refreshScreen(view);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, viewGet(%s, ''curScan''), [], ''linear''); ', ...
              view.name, view.name, view.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', view.name, view.name) ...
      'clear ip; '];
uimenu(xformMenuMapCur, 'Label', 'Trilinear Interpolation', ...
        'Separator', 'off', 'Callback', cb);

%%%%%%%%%%%%%%%%%%%%
% (3) Select scans %
%%%%%%%%%%%%%%%%%%%%
xformMenuMapSel = uimenu(inplane2volumeMenu,'Label',...
                         'Parameter Map (select scans)','Separator','off');

%%%%%nearest-neighbor interpolation, select scan
% ip = checkSelectedInplane; 
% view = ip2volParMap(ip, view, [], [], 'nearest'); 
% view = setDisplayMode(view, 'map');
% view = refreshScreen(view);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, []), [], ''nearest''); ', ...
              view.name, view.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', view.name, view.name) ...
      'clear ip; '];
uimenu(xformMenuMapSel, 'Label', 'Nearest neighbor interpolation', ...
        'Separator', 'off', 'CallBack', cb);
    
%%%%%linear interpolation, all scans
% ip = checkSelectedInplane; 
% view = ip2volParMap(ip, view, [], [], 'linear'); 
% view = setDisplayMode(view, 'map');
% view = refreshScreen(view);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, [], [], ''linear''); ', ...
              view.name, view.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', view.name, view.name) ...
      'clear ip; '];
uimenu(xformMenuMapSel, 'Label', 'Trilinear Interpolation', ...
        'Separator', 'off', 'CallBack', cb);
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(4) linear interpolation, all scans AND all maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xformMenuAllMaps = uimenu(inplane2volumeMenu,'Label',...
                         'All Maps in Data Type','Separator','off');
                     
% ip = checkSelectedInplane; 
% view = ip2volAllParMaps(ip, view, 'linear'); 
% clear ip;
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('ip2volAllParMaps(ip, %s, ''nearest''); ', view.name) ...
      'clear ip;'];
uimenu(xformMenuAllMaps, 'Label', 'Nearest neighbor Interpolation', ...
        'Separator', 'off', 'CallBack', cb);       
    
% ip = checkSelectedInplane; 
% view = ip2volAllParMaps(ip, view, 'linear'); 
% clear ip;
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('ip2volAllParMaps(ip, %s, ''linear''); ', view.name) ...
      'clear ip;'];
uimenu(xformMenuAllMaps, 'Label', 'Trilinear Interpolation', ...
        'Separator', 'off', 'CallBack', cb);       
    
    
return
% /-------------------------------------------------------------------/ %





% /-------------------------------------------------------------------/ %
function view = ipRMSubmenu(view, inplane2volumeMenu)
% Sub-submenu for xforming retinotopic model data from inplane -> volume.

%%%%%%%%%%%%%%%%%%%%
% All parameters   %
%%%%%%%%%%%%%%%%%%%%
xformMenuRMAll = uimenu(inplane2volumeMenu,'Label',...
                         'Retinotopic model','Separator','on');

%%%%%nearest-neighbor interpolation, all scans
% ip = checkSelectedInplane; 
% view = ip2volParMap(ip, view, 0, [], 'nearest'); 
% view = setDisplayMode(view, 'map');
% view = refreshScreen(view);
% clear ip
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s =rmIp2Vol(ip, %s, ''nearest'',0); ', ...
              view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', view.name, view.name) ...
      'clear ip '];
uimenu(xformMenuRMAll, 'Label', 'Nearest-neighbor Interpolation', ....
       'Separator', 'off', 'CallBack', cb);

%%%%%linear interpolation, all scans
% ip = checkSelectedInplane; 
% view = ip2volParMap(ip, view, 0, [], 'linear'); 
% view = setDisplayMode(view, 'map');
% view = refreshScreen(view);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s =rmIp2Vol(ip, %s, ''linear'',0); ', ...
              view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', view.name, view.name) ...
      'clear ip '];
uimenu(xformMenuRMAll, 'Label', 'Trilinear Interpolation', ...
        'Separator', 'off', 'CallBack', cb);

return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function view = ipTSeriesSubmenu(view, inplane2volumeMenu)
% sub-submenu for xforming tSeries from inplane -> volume.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xformMenuTseriesAll = uimenu(inplane2volumeMenu,'Label','tSeries (all scans)','Separator','on');

% Xform tSeries (all) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volTSeries(inplane,view,0);
%   clear inplane;
cb=['inplane=checkSelectedInplane; ',...
        view.name,'=ip2volTSeries(inplane,',view.name,',0,''nearest''); ' ...
        'clear inplane; '];
uimenu(xformMenuTseriesAll,'Label','nearest neighbor interpolation','Separator','on',...
    'CallBack',cb);

% Xform tSeries (all) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volTSeries(inplane,view,0);
cb = ['inplane=checkSelectedInplane; ',...
      view.name,'=ip2volTSeries(inplane,',view.name,',0,''linear''); ' ...
      'clear inplane; '];
uimenu(xformMenuTseriesAll,'Label','trilinear interpolation','Separator','off',...
    'CallBack',cb);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xformMenuTseriesCur = uimenu(inplane2volumeMenu,'Label','tSeries (current scan)','Separator','off');

% Xform tSeries (current scan) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volTSeries(inplane,view,getCurScan(view));
cb = ['inplane=checkSelectedInplane; ',...
      view.name '=ip2volTSeries(inplane, ',view.name,',getCurScan(',view.name,'),''nearest''); ' ...
      'clear inplane; '];
uimenu(xformMenuTseriesCur,'Label','nearest neighbor interpolation','Separator','off',...
    'CallBack',cb);

% Xform tSeries (current scan) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volTSeries(inplane,view,getCurScan(view));
cb = ['inplane=checkSelectedInplane; ',...
     view.name,'=ip2volTSeries(inplane,',view.name,',getCurScan(',view.name,'),''linear''); ' ...
     'clear inplane; '];
uimenu(xformMenuTseriesCur,'Label','trilinear interpolation','Separator','off',...
    'CallBack',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xformMenuTseriesSel = uimenu(inplane2volumeMenu,'Label','tSeries (select scans)','Separator','off');
% Xform tSeries (select scans) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volTSeries(inplane,view);
cb = ['inplane=checkSelectedInplane; ',...
        view.name,'=ip2volTSeries(inplane,',view.name,',[],''nearest'');'];
uimenu(xformMenuTseriesSel,'Label','nearest neighbor interpolation','Separator','off',...
    'CallBack',cb);

% Xform tSeries (select scans) callback:
%   inplane=checkSelectedInplane;
%   view=ip2volTSeries(inplane,view);
cb = ['inplane=checkSelectedInplane; ',...
      view.name,'=ip2volTSeries(inplane,',view.name,',[],''linear''); ' ...
      'clear inplane; '];
uimenu(xformMenuTseriesSel,'Label','trilinear interpolation','Separator','off',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %


 

% /-------------------------------------------------------------------/ %
function view = ipOtherSubmenu(view, inplane2volumeMenu)
% Some other sub-submenus for xforming tseries for an ROI only
% (rory's multivoxel analyses), and xforming the spatial gradient map.

% Xform tSeries + voxel data (ROI) callback:
%   view=ip2volVoxelData([],view,view.selectedROI);
cb = sprintf('ip2VolVoxelData([],%s,%s.selectedROI);',view.name,view.name);
uimenu(inplane2volumeMenu,'Label','tSeries + Voxel Data (Cur ROI)','Separator','on',...
    'CallBack',cb);

% Xform tSeries + voxel data (select ROIs) callback:
%   view=ip2volVoxelData([],view);
cb=['ip2volVoxelData([],',view.name,');'];
uimenu(inplane2volumeMenu,'Label','tSeries + Voxel Data (Select ROIs)','Separator','off',...
    'CallBack',cb);


% Xform Spatial Gradient callback:
%   inplane=checkSelectedInplane;
%   view=ip2volSpatialGradient(inplane,view);
cb=['inplane=checkSelectedInplane; ',...
        view.name,'=ip2volSpatialGradient(inplane,',view.name,');'];
uimenu(inplane2volumeMenu,'Label','Spatial gradient','Separator','on',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %





% /-------------------------------------------------------------------/ %
function view = flatSubmenu(view, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Flat->Volume submenu

flat2volumeMenu = uimenu(xformMenu,'Label','Flat->Volume','Separator','on');

% Xform ROIs (Flat->Volume) callback:
%   flat=checkSelectedflat;
%   view=flat2volCurROI(flat,view);
%   view=refreshScreen(view,0);
cb=['flat=checkSelectedFlat; ',...
        view.name,'=flat2volCurROI(flat,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(flat2volumeMenu,'Label','ROI - selected (Flat->Volume)','Separator','on',...
    'CallBack',cb);

% Xform All ROIs (Flat->Volume) callback:
%   flat=checkSelectedflat;
%   view=flat2volAllROIs(flat,view);
%   view=refreshScreen(view,0);
cb=['flat=checkSelectedFlat; ',...
        view.name,'=flat2volAllROIs(flat,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(flat2volumeMenu,'Label','ROIs - all (Flat->Volume)','Separator','on',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %






% /-------------------------------------------------------------------/ %
function flatLevelSubmenu(view, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Flat Level->Volume submenu

flat2volumeMenu = uimenu(xformMenu,'Label','Flat Level->Volume','Separator','off');

% Xform ROIs (Flat Level->Volume) callback:
%   flat=checkSelectedflat;
%   view=flat2volCurROILevels(flat,view);
%   view=refreshScreen(view,0);
cb=['flat=checkSelectedFlat; ',...
        view.name,'=flat2volCurROILevels(flat,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(flat2volumeMenu,'Label','ROI - selected (Flat Level->Volume)','Separator','on',...
    'CallBack',cb);

% Xform All ROIs (Flat->Volume) callback:
%   flat=checkSelectedflat;
%   view=flat2volAllROIsLevels(flat,view);
%   view=refreshScreen(view,0);
cb=['flat=checkSelectedFlat; ',...
        view.name,'=flat2volAllROIsLevels(flat,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(flat2volumeMenu,'Label','ROIs - all (Flat Level->Volume)','Separator','on',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function view = mrGraySubmenu(view, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Volume->mrGray submenu

volume2mrGrayMenu = uimenu(xformMenu,'Label','Volume->mrGray','Separator','off');

% write mrGray ROI callback:
%   roi = view.ROIs(view.selectedROI);
%   [fname pname] = uiputfile('*.roi','volROI2mrGray');
%   volROI2mrGray(roi.name, roi, pname);
%	 disp(['Wrote selected ROI as mrGray ROI file ' roi.name '.']);
cb = ['roi = ',view.name,'.ROIs(',view.name,'.selectedROI);',...
        'curDir = pwd; anatDir = getAnatomyPath([]); if(exist(anatDir,''dir'')) chdir(anatDir); end; ' ...
        '[fname pname] = uiputfile(''*.roi'',''Choose directory: volROI2mrGray'');', ...
        'volROI2mrGray(roi.name, roi, pname); chdir(curDir);',...
        'disp([''Wrote selected ROI as mrGray ROI file '' roi.name ''.'']);'];
uimenu(volume2mrGrayMenu,...
    'Label','write mrGray ROI - selected',...
    'Separator','on',...
    'CallBack',cb);

% write mrGray ROI callback:
%   roi = view.ROIs(view.selectedROI);
%   [fname pname] = uiputfile('*.roi','volROI2mrGray');
%   volROI2mrGray(roi.name, roi);
%	 disp(['Wrote selected ROI as mrGray ROI file ' roi.name '.']);
cb = ...
    [ 'curDir = pwd; anatDir = getAnatomyPath([]); if(exist(anatDir,''dir'')) chdir(anatDir); end; ' ...
        '[fname pname] = uiputfile(''*.roi'',''Choose directory: volROI2mrGray'');', ...
        'for whichROI=1:length(',view.name,'.ROIs) ',...
        'roi = ',view.name,'.ROIs(whichROI);',...
        'volROI2mrGray(roi.name, roi,pname);',...
        'disp([''Wrote ROI #'' num2str(whichROI) '' as mrGray ROI file '' roi.name ''.'']);',...
        'end;chdir(curDir);'];
uimenu(volume2mrGrayMenu,'Label','write mrGray ROIs - all','Separator','on',...
    'CallBack',cb);

% write mrGray functional data overlay callback:
%   functionals2mrGray(view);
cb = ['functionals2mrGray(',view.name,');'];
uimenu(volume2mrGrayMenu,'Label','write mrGray functional data overlay','Separator','on',...
    'CallBack',cb);

% write mrGray functional data overlay callback (masked w/ ROI):
%   functionals2mrGray(view);
cb = ['functionals2mrGray(',view.name,', getCurROIcoords(',view.name,'));'];
uimenu(volume2mrGrayMenu,'Label','write mrGray functional, masked w/ cur ROI','Separator','off',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function view = bvSubmenu(view, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Volume->BrainVoyager submenu

volume2BVMenu = uimenu(xformMenu,'Label','Volume->BrainVoyager','Separator','off');

% write BV Functional data callback:

cb = ['BV_mrLoadRet3StatsToVMPFile;'];
uimenu(volume2BVMenu,...
    'Label','write BV Functional: current scan',...
    'Separator','off',...
    'CallBack',cb);

% write BV ROI callback:

cb = ['BV_mrLoadRet3GrayROIsToVOIFile;'];
uimenu(volume2BVMenu,...
    'Label','write BV ROIs (all)',...
    'Separator','off',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function view = analyzeSubmenu(view, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Volume->Analyze submenu

volume2Analyze = uimenu(xformMenu,'Label','Volume->Analyze','Separator','off');

% write Analyze Functional data callback:
cb = ['mrLoadRet3StatsToAnalyze;'];
uimenu(volume2Analyze,...
    'Label', 'write functional analyze data: current scan',...
    'Separator', 'off',...
    'CallBack', cb);

return
% /-------------------------------------------------------------------/ %


% /-------------------------------------------------------------------/ %
function view = itkGraySubmenu(view, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Volume->itkGray submenu

volume2itkGrayMenu = uimenu(xformMenu,'Label','Volume->itkGray','Separator','off');

% Export selected ROI as NIFTI for itkGray 
%   roiSaveForItkGray(vw, [fname], [roiColor]);
cb=['roiSaveForItkGray(',view.name,'); '];
uimenu(volume2itkGrayMenu,'Label','Export ROI as NIFTI - curernt','Separator','off',...
    'Callback',cb);

% Export all ROIs as NIFTI for itkGray 
%   roiSaveAllForItkGray(vw, fname)(view, [fname]);
cb=['roiSaveAllForItkGray(',view.name,'); '];
uimenu(volume2itkGrayMenu,'Label','Export ROI as NIFTI - all','Separator','off',...
    'Callback',cb);

% write itkGray functional data overlay callback:
%   functionals2itkGray(view);
cb = ['functionals2itkGray(',view.name,');'];
uimenu(volume2itkGrayMenu,'Label','write itkGray functional data overlay','Separator','on',...
    'CallBack',cb);

% itkGray (nifti)->Gray submenu
itkGray2volumeMenu = uimenu(xformMenu,'Label','itkGray(nifti)->Gray','Separator','off');

% read itkGray functional data into parameter map callback:
%   nifti2functionals(view);
%   view = refreshScreen(view);
cb = [view.name '=nifti2functionals(',view.name,');' ,...
          view.name,'=refreshScreen(',view.name,',0); '];
uimenu(itkGray2volumeMenu,'Label','import itkGray data as parameter map','Separator','on',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %


% /-------------------------------------------------------------------/ %
function view = acrSessionsSubmenu(view, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Other Session->This Session submenu

sess2sessMenu = uimenu(xformMenu, 'Label', 'Other Session->This Session', ...
                        'Separator', 'on');

% import scans
cb = sprintf('%s = importScans(%s);', view.name, view.name);
uimenu(sess2sessMenu, 'Label', 'Import Scan (tSeries, maps, + corAnal)', ...
    'Separator', 'off', 'Callback', cb);

% import tSeries
cb = sprintf('%s = importTSeries(%s);',view.name,view.name);
uimenu(sess2sessMenu, 'Label', 'Import tSeries only', ...
    'Separator', 'off', 'Callback', cb);

% import corAnal
cb = sprintf('%s = importCorAnal(%s);',view.name,view.name);
uimenu(sess2sessMenu,'Label','Import Cor Anal only','Separator','off','Callback',cb);

% import parameter map
cb = sprintf('%s = importMap(%s);',view.name,view.name);
uimenu(sess2sessMenu,'Label','Import Parameter Map only','Separator','off','Callback',cb);

% import retinitopy model fit
cb = sprintf('%s = importRetModelFit(%s);',view.name,view.name);
uimenu(sess2sessMenu,'Label','Import Retinotopy Model','Separator','on','Callback',cb);

% create combined session
% sessions = selectSessions('..');
% prompt = 'Name Combined Session';
% default = fileparts(sessions{1});
% combined = inputdlg({prompt}, prompt, 1, {default});
% createCombinedSession(combined, sessions);
cb = ['sessions = selectSessions(''..''); ' ...
      'prompt = ''Name Combined Session''; ' ...
      'default = fileparts(sessions{1}); ' ...
      'combined = inputdlg({prompt}, prompt, 1, {default}); ' ...
      'createCombinedSession(combined, sessions); '];
uimenu(sess2sessMenu, 'Label', 'Create Combined Session', ...
        'Separator', 'on', 'Callback', cb);

return;
