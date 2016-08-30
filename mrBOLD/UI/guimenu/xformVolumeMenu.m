function vw = xformVolumeMenu(vw)

% vw = xformVolumeMenu(vw);
% 
% Set up the callbacks for the xformView menu in the volume vw
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

if (~strcmp(vw.viewType,'GeneralVolumeData')) 
    % The point of the GVD vw type is that it is not derived from 
    % INPLANE data.
    inplane2volumeMenu = uimenu(xformMenu, 'Label', 'Inplane->Volume', ...
                                'Separator', 'off');

    ipRoiSubmenu(vw, inplane2volumeMenu);
    ipCorAnalSubmenu(vw, inplane2volumeMenu);
    ipMapSubmenu(vw, inplane2volumeMenu);
    ipTSeriesSubmenu(vw, inplane2volumeMenu);
    ipOtherSubmenu(vw, inplane2volumeMenu); % spatial gradient, ROI data
    ipRMSubmenu(vw, inplane2volumeMenu);
end     


flatSubmenu(vw, xformMenu);
flatLevelSubmenu(vw, xformMenu);
% bvSubmenu(vw, xformMenu);  % none of the code is checked in
niftiGraySubmenu(vw, xformMenu);
analyzeSubmenu(vw, xformMenu);
acrSessionsSubmenu(vw, xformMenu);

return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function vw = ipRoiSubmenu(vw, inplane2volumeMenu)
% Submenu for xforming ROIs from Inplane -> Volume

% Xform ROI (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volCurROI(inplane,vw);
%   vw=refreshScreen(vw,0);
%   clear inplane;
cb = ['inplane=checkSelectedInplane; ',...
      vw.name,'=ip2volCurROI(inplane,',vw.name,'); ',...
      vw.name,'=refreshScreen(',vw.name,',0); ' ...
      'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','ROI (selected)','Separator','off',...
    'CallBack',cb);

% Xform All ROIs (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volAllROIs(inplane,vw);
%   vw=refreshScreen(vw,0);
cb = ['inplane=checkSelectedInplane; ',...
      vw.name,'=ip2volAllROIs(inplane,',vw.name,'); ',...
      vw.name,'=refreshScreen(',vw.name,',0); ' ...
      'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','ROIs (all)','Separator','off',...
    'CallBack',cb);
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function vw = ipCorAnalSubmenu(vw, inplane2volumeMenu)
% Sub-submenu for xforming corAnals from inplane -> volume.

% Xform CorAnal all scans (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volCorAnal(inplane,vw,0);
%   vw=refreshScreen(vw,1);
%   clear inplane;
cb=['inplane=checkSelectedInplane; ',...
        vw.name,'=ip2volCorAnal(inplane,',vw.name,',0); ',...
        vw.name,'=refreshScreen(',vw.name,',1);' ...
        'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','CorAnal (all scans)','Separator','on',...
    'CallBack',cb);

% Xform CorAnal current scan (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volCorAnal(inplane,vw,getCurScan(vw));
%   vw=refreshScreen(vw,1);
cb=['inplane=checkSelectedInplane; ',...
        vw.name,'=ip2volCorAnal(inplane,',vw.name,',getCurScan(',vw.name,')); ',...
        vw.name,'=refreshScreen(',vw.name,',1);' ...
        'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','CorAnal (current scan)','Separator','off',...
    'CallBack',cb);

% Xform CorAnal select scans (Inplane->Volume) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volCorAnal(inplane,vw);
%   vw=refreshScreen(vw,1);
cb=['inplane=checkSelectedInplane; ',...
        vw.name,'=ip2volCorAnal(inplane,',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,',1);' ...
        'clear inplane; '];
uimenu(inplane2volumeMenu,'Label','CorAnal (select scans)','Separator','off',...
    'CallBack',cb);
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function vw = ipMapSubmenu(vw, inplane2volumeMenu)
% Sub-submenu for xforming parameter maps from inplane -> volume.

%%%%%%%%%%%%%%%%%%%%
% (1) All scans    %
%%%%%%%%%%%%%%%%%%%%
xformMenuMapAll = uimenu(inplane2volumeMenu,'Label',...
                         'Parameter Map (all scans)','Separator','on');

%%%%%nearest-neighbor interpolation, all scans
% ip = checkSelectedInplane; 
% vw = ip2volParMap(ip, vw, 0, [], 'nearest'); 
% vw = setDisplayMode(vw, 'map');
% vw = refreshScreen(vw);
% clear ip
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, 0, [], ''nearest''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', vw.name, vw.name) ...
      'clear ip '];
uimenu(xformMenuMapAll, 'Label', 'Nearest-neighbor Interpolation', ....
            'Separator', 'off', 'CallBack', cb);

%%%%%linear interpolation, all scans
% ip = checkSelectedInplane; 
% vw = ip2volParMap(ip, vw, 0, [], 'linear'); 
% vw = setDisplayMode(vw, 'map');
% vw = refreshScreen(vw);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, 0, [], ''linear''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', vw.name, vw.name) ...
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
% vw = ip2volParMap(ip, vw, getCurScan(vw), [], 'nearest'); 
% vw = setDisplayMode(vw, 'map');
% vw = refreshScreen(vw);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, viewGet(%s, ''curScan''), [], ''nearest''); ', ...
              vw.name, vw.name, vw.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', vw.name, vw.name) ...
      'clear ip; '];
uimenu(xformMenuMapCur, 'Label', 'Nearest-neighbor Interpolation', ...
        'Separator', 'off', 'Callback',cb);

%%%%%linear interpolation, current scan
% ip = checkSelectedInplane; 
% vw = ip2volParMap(ip, vw, getCurScan(vw), [], 'linear'); 
% vw = setDisplayMode(vw, 'map');
% vw = refreshScreen(vw);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, viewGet(%s, ''curScan''), [], ''linear''); ', ...
              vw.name, vw.name, vw.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', vw.name, vw.name) ...
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
% vw = ip2volParMap(ip, vw, [], [], 'nearest'); 
% vw = setDisplayMode(vw, 'map');
% vw = refreshScreen(vw);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, []), [], ''nearest''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', vw.name, vw.name) ...
      'clear ip; '];
uimenu(xformMenuMapSel, 'Label', 'Nearest neighbor interpolation', ...
        'Separator', 'off', 'CallBack', cb);
    
%%%%%linear interpolation, all scans
% ip = checkSelectedInplane; 
% vw = ip2volParMap(ip, vw, [], [], 'linear'); 
% vw = setDisplayMode(vw, 'map');
% vw = refreshScreen(vw);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s = ip2volParMap(ip, %s, [], [], ''linear''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = setDisplayMode(%s, ''map''); ', ...
              vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', vw.name, vw.name) ...
      'clear ip; '];
uimenu(xformMenuMapSel, 'Label', 'Trilinear Interpolation', ...
        'Separator', 'off', 'CallBack', cb);
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(4) linear interpolation, all scans AND all maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xformMenuAllMaps = uimenu(inplane2volumeMenu,'Label',...
                         'All Maps in Data Type','Separator','off');
                     
% ip = checkSelectedInplane; 
% vw = ip2volAllParMaps(ip, vw, 'linear'); 
% clear ip;
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('ip2volAllParMaps(ip, %s, ''nearest''); ', vw.name) ...
      'clear ip;'];
uimenu(xformMenuAllMaps, 'Label', 'Nearest neighbor Interpolation', ...
        'Separator', 'off', 'CallBack', cb);       
    
% ip = checkSelectedInplane; 
% vw = ip2volAllParMaps(ip, vw, 'linear'); 
% clear ip;
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('ip2volAllParMaps(ip, %s, ''linear''); ', vw.name) ...
      'clear ip;'];
uimenu(xformMenuAllMaps, 'Label', 'Trilinear Interpolation', ...
        'Separator', 'off', 'CallBack', cb);       
    
    
return
% /-------------------------------------------------------------------/ %





% /-------------------------------------------------------------------/ %
function vw = ipRMSubmenu(vw, inplane2volumeMenu)
% Sub-submenu for xforming retinotopic model data from inplane -> volume.

%%%%%%%%%%%%%%%%%%%%
% All parameters   %
%%%%%%%%%%%%%%%%%%%%
xformMenuRMAll = uimenu(inplane2volumeMenu,'Label',...
                         'Retinotopic model','Separator','on');

%%%%%nearest-neighbor interpolation, all scans
% ip = checkSelectedInplane; 
% vw = ip2volParMap(ip, vw, 0, [], 'nearest'); 
% vw = setDisplayMode(vw, 'map');
% vw = refreshScreen(vw);
% clear ip
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s =rmIp2Vol(ip, %s, ''nearest'',0); ', ...
              vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', vw.name, vw.name) ...
      'clear ip '];
uimenu(xformMenuRMAll, 'Label', 'Nearest-neighbor Interpolation', ....
       'Separator', 'off', 'CallBack', cb);

%%%%%linear interpolation, all scans
% ip = checkSelectedInplane; 
% vw = ip2volParMap(ip, vw, 0, [], 'linear'); 
% vw = setDisplayMode(vw, 'map');
% vw = refreshScreen(vw);
cb = ['ip = checkSelectedInplane; ' ...
      sprintf('%s =rmIp2Vol(ip, %s, ''linear'',0); ', ...
              vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 1); ', vw.name, vw.name) ...
      'clear ip '];
uimenu(xformMenuRMAll, 'Label', 'Trilinear Interpolation', ...
        'Separator', 'off', 'CallBack', cb);

return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function vw = ipTSeriesSubmenu(vw, inplane2volumeMenu)
% sub-submenu for xforming tSeries from inplane -> volume.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xformMenuTseriesAll = uimenu(inplane2volumeMenu,'Label','tSeries (all scans)','Separator','on');

% Xform tSeries (all) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volTSeries(inplane,vw,0);
%   clear inplane;
cb=['inplane=checkSelectedInplane; ',...
        vw.name,'=ip2volTSeries(inplane,',vw.name,',0,''nearest''); ' ...
        'clear inplane; '];
uimenu(xformMenuTseriesAll,'Label','nearest neighbor interpolation','Separator','on',...
    'CallBack',cb);

% Xform tSeries (all) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volTSeries(inplane,vw,0);
cb = ['inplane=checkSelectedInplane; ',...
      vw.name,'=ip2volTSeries(inplane,',vw.name,',0,''linear''); ' ...
      'clear inplane; '];
uimenu(xformMenuTseriesAll,'Label','trilinear interpolation','Separator','off',...
    'CallBack',cb);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xformMenuTseriesCur = uimenu(inplane2volumeMenu,'Label','tSeries (current scan)','Separator','off');

% Xform tSeries (current scan) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volTSeries(inplane,vw,getCurScan(vw));
cb = ['inplane=checkSelectedInplane; ',...
      vw.name '=ip2volTSeries(inplane, ',vw.name,',getCurScan(',vw.name,'),''nearest''); ' ...
      'clear inplane; '];
uimenu(xformMenuTseriesCur,'Label','nearest neighbor interpolation','Separator','off',...
    'CallBack',cb);

% Xform tSeries (current scan) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volTSeries(inplane,vw,getCurScan(vw));
cb = ['inplane=checkSelectedInplane; ',...
     vw.name,'=ip2volTSeries(inplane,',vw.name,',getCurScan(',vw.name,'),''linear''); ' ...
     'clear inplane; '];
uimenu(xformMenuTseriesCur,'Label','trilinear interpolation','Separator','off',...
    'CallBack',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xformMenuTseriesSel = uimenu(inplane2volumeMenu,'Label','tSeries (select scans)','Separator','off');
% Xform tSeries (select scans) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volTSeries(inplane,vw);
cb = ['inplane=checkSelectedInplane; ',...
        vw.name,'=ip2volTSeries(inplane,',vw.name,',[],''nearest'');'];
uimenu(xformMenuTseriesSel,'Label','nearest neighbor interpolation','Separator','off',...
    'CallBack',cb);

% Xform tSeries (select scans) callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volTSeries(inplane,vw);
cb = ['inplane=checkSelectedInplane; ',...
      vw.name,'=ip2volTSeries(inplane,',vw.name,',[],''linear''); ' ...
      'clear inplane; '];
uimenu(xformMenuTseriesSel,'Label','trilinear interpolation','Separator','off',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %


 

% /-------------------------------------------------------------------/ %
function vw = ipOtherSubmenu(vw, inplane2volumeMenu)
% Some other sub-submenus for xforming tseries for an ROI only
% (rory's multivoxel analyses), and xforming the spatial gradient map.

% Xform tSeries + voxel data (ROI) callback:
%   vw=ip2volVoxelData([],vw,vw.selectedROI);
cb = sprintf('ip2VolVoxelData([],%s,%s.selectedROI);',vw.name,vw.name);
uimenu(inplane2volumeMenu,'Label','tSeries + Voxel Data (Cur ROI)','Separator','on',...
    'CallBack',cb);

% Xform tSeries + voxel data (select ROIs) callback:
%   vw=ip2volVoxelData([],vw);
cb=['ip2volVoxelData([],',vw.name,');'];
uimenu(inplane2volumeMenu,'Label','tSeries + Voxel Data (Select ROIs)','Separator','off',...
    'CallBack',cb);


% Xform Spatial Gradient callback:
%   inplane=checkSelectedInplane;
%   vw=ip2volSpatialGradient(inplane,vw);
cb=['inplane=checkSelectedInplane; ',...
        vw.name,'=ip2volSpatialGradient(inplane,',vw.name,');'];
uimenu(inplane2volumeMenu,'Label','Spatial gradient','Separator','on',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %





% /-------------------------------------------------------------------/ %
function vw = flatSubmenu(vw, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Flat->Volume submenu

flat2volumeMenu = uimenu(xformMenu,'Label','Flat->Volume','Separator','on');

% Xform ROIs (Flat->Volume) callback:
%   flat=checkSelectedflat;
%   vw=flat2volCurROI(flat,vw);
%   vw=refreshScreen(vw,0);
cb=['flat=checkSelectedFlat; ',...
        vw.name,'=flat2volCurROI(flat,',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(flat2volumeMenu,'Label','ROI - selected (Flat->Volume)','Separator','on',...
    'CallBack',cb);

% Xform All ROIs (Flat->Volume) callback:
%   flat=checkSelectedflat;
%   vw=flat2volAllROIs(flat,vw);
%   vw=refreshScreen(vw,0);
cb=['flat=checkSelectedFlat; ',...
        vw.name,'=flat2volAllROIs(flat,',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(flat2volumeMenu,'Label','ROIs - all (Flat->Volume)','Separator','on',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %






% /-------------------------------------------------------------------/ %
function flatLevelSubmenu(vw, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Flat Level->Volume submenu

flat2volumeMenu = uimenu(xformMenu,'Label','Flat Level->Volume','Separator','off');

% Xform ROIs (Flat Level->Volume) callback:
%   flat=checkSelectedflat;
%   vw=flat2volCurROILevels(flat,vw);
%   vw=refreshScreen(vw,0);
cb=['flat=checkSelectedFlat; ',...
        vw.name,'=flat2volCurROILevels(flat,',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(flat2volumeMenu,'Label','ROI - selected (Flat Level->Volume)','Separator','on',...
    'CallBack',cb);

% Xform All ROIs (Flat->Volume) callback:
%   flat=checkSelectedflat;
%   vw=flat2volAllROIsLevels(flat,vw);
%   vw=refreshScreen(vw,0);
cb=['flat=checkSelectedFlat; ',...
        vw.name,'=flat2volAllROIsLevels(flat,',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(flat2volumeMenu,'Label','ROIs - all (Flat Level->Volume)','Separator','on',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function vw = analyzeSubmenu(vw, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Volume->Analyze submenu

volume2Analyze = uimenu(xformMenu,'Label','Volume->Analyze','Separator','off');

% write Analyze Functional data callback:
cb = 'mrLoadRet3StatsToAnalyze;';
uimenu(volume2Analyze,...
    'Label', 'write functional analyze data: current scan',...
    'Separator', 'off',...
    'CallBack', cb);

return
% /-------------------------------------------------------------------/ %


% /-------------------------------------------------------------------/ %
function vw = niftiGraySubmenu(vw, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Volume->nifti submenu

volume2niftiMenu = uimenu(xformMenu,'Label','Volume->nifti','Separator','off');

% Export selected ROI as NIFTI for nifti 
%   roiSaveAsNifti(vw, [fname], [roiColor]);
cb=['roiSaveAsNifti(',vw.name,'); '];
uimenu(volume2niftiMenu,'Label','Export ROI as NIFTI - current','Separator','off',...
    'Callback',cb);

% Export all ROIs as NIFTI as nifti
%   roiSaveAllAsNifti(vw, fname)(vw, [fname]);
cb=['roiSaveAllAsNifti(',vw.name,'); '];
uimenu(volume2niftiMenu,'Label','Export ROI as NIFTI - all','Separator','off',...
    'Callback',cb);

% write nifti functional data overlay callback:
%   functionals2nifti(vw);
cb = ['functionals2nifti(',vw.name,');'];
uimenu(volume2niftiMenu,'Label','write nifti functional data overlay','Separator','on',...
    'CallBack',cb);

% nifti->Gray submenu
nifti2volumeMenu = uimenu(xformMenu,'Label','nifti->Gray','Separator','off');

% read nifti functional data into parameter map callback:
%   nifti2functionals(vw);
%   vw = refreshScreen(vw);
cb = [vw.name '=nifti2functionals(',vw.name,');' ,...
          vw.name,'=refreshScreen(',vw.name,',0); '];
uimenu(nifti2volumeMenu,'Label','import nifti data as parameter map','Separator','on',...
    'CallBack',cb);

return
% /-------------------------------------------------------------------/ %


% /-------------------------------------------------------------------/ %
function vw = acrSessionsSubmenu(vw, xformMenu)
%%%%%%%%%%%%%%%%%%%%%
% Other Session->This Session submenu

sess2sessMenu = uimenu(xformMenu, 'Label', 'Other Session->This Session', ...
                        'Separator', 'on');

% import scans
cb = sprintf('%s = importScans(%s);', vw.name, vw.name);
uimenu(sess2sessMenu, 'Label', 'Import Scan (tSeries, maps, + corAnal)', ...
    'Separator', 'off', 'Callback', cb);

% import tSeries
cb = sprintf('%s = importTSeries(%s);',vw.name,vw.name);
uimenu(sess2sessMenu, 'Label', 'Import tSeries only', ...
    'Separator', 'off', 'Callback', cb);

% import corAnal
cb = sprintf('%s = importCorAnal(%s);',vw.name,vw.name);
uimenu(sess2sessMenu,'Label','Import Cor Anal only','Separator','off','Callback',cb);

% import parameter map
cb = sprintf('%s = importMap(%s);',vw.name,vw.name);
uimenu(sess2sessMenu,'Label','Import Parameter Map only','Separator','off','Callback',cb);

% import retinitopy model fit
cb = sprintf('%s = importRetModelFit(%s);',vw.name,vw.name);
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
