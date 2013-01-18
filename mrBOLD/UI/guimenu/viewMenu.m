function vw=viewMenu(vw)
%
% viewMenu
%
% Set up the callbacks for the VIEW menu
%
% djh, 1/98
% rmk, 12/10/98  added 'Find Current ROI' to VOLUME
% ras, 04/25/04  added some INPLANE-specific options, incl
%                viewing montages w/ the overlay on it, and
%                setting the 'underlay' (anatomy image) to
%                be the mean functional img of the selected
%                scan, and back to inplanes. (Also commented
%                out the 'view annotation' option, since it
%                never seemed to work?)
% ress, 12/04    added menu items for laminar analysis

viewMenu = uimenu('Label','View','Separator','on');

% Anatomy mode callback:
%   vw=setDisplayMode(vw,'anat');
%   vw=refreshScreen(vw);
callback=[vw.name,'=setDisplayMode(',vw.name,',''anat''); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','Anatomy and ROIs (no overlay)','Separator','off',...
    'Callback',callback);

% Coherence Map callback:
%   vw=setDisplayMode(vw,'co');
%   vw=refreshScreen(vw);
callback=[vw.name,'=setDisplayMode(',vw.name,',''co''); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','Coherence Map','Separator','off',...
    'Callback',callback);

% Amplitude Map callback:
%   vw=setDisplayMode(vw,'amp');
%   vw=refreshScreen(vw);
callback=[vw.name,'=setDisplayMode(',vw.name,',''amp''); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','Amplitude Map','Separator','off',...
    'Callback',callback);

% Phase Map callback:
%   vw=setDisplayMode(vw,'ph');
%   vw=refreshScreen(vw);
callback=[vw.name,'=setDisplayMode(',vw.name,',''ph''); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','Phase Map','Separator','off',...
    'Callback',callback);

% Parameter Map callback:
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
callback=[vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','Parameter Map','Separator', 'off',...
    'Callback',callback);

% Mean map callback:
%   vw=loadMeanMap(vw);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
callback=[vw.name,'=loadMeanMap(',vw.name,'); ',...
    vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','Mean Map','Separator','off',...
    'Callback',callback);

% tSNR map callback:
%   vw=loadtSNRMap(vw);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
callback=[vw.name,'=loadtSNRMap(',vw.name,'); ',...
    vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','tSNR Map','Separator','on',...
    'Callback',callback);


% % Normalized mean map callback:
% %   normalized = true; vw=loadMeanMap(vw, normalized);
% %   vw=setDisplayMode(vw,'map');
% %   vw=refreshScreen(vw);
% callback=['normalized = true;', vw.name,'=loadMeanMap(',vw.name,', normalized); ',...
%     vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
%     vw.name,'=refreshScreen(',vw.name,');'];
% uimenu(viewMenu,'Label','Normalized Mean Map [0 1]','Separator','off',...
%     'Callback',callback);

% CrossScanCorr map callback:
%   vw=loadCrossScanCorrMap(vw);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
callback=[vw.name,'=loadCrossScanCorrMap(',vw.name,'); ',...
    vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','CrossScanCorr Map','Separator','off',...
    'Callback',callback);




% Correlation Coefficient subMenu:
corMenu = uimenu(viewMenu,'Label','Phase Projected...','Separator','off');

%   vw=setReferencePhase(vw);
%   vw=refreshScreen(vw,1);
callback=[vw.name,'=setReferencePhase(',vw.name,'); ',...
    vw.name,'=refreshScreen(',vw.name,',1);'];
uimenu(corMenu,'Label','Set/Reset Reference Phase','Separator','off',...
    'Callback',callback);

%   vw=setDisplayMode(vw,'cor');
%   vw=refreshScreen(vw,1);
%callback=[vw.name,'=setDisplayMode(',vw.name,',''cor''); ',...
%    vw.name,'=refreshScreen(',vw.name,',1);'];
%uimenu(corMenu,'Label','Correlation Coefficient map','Separator','off',...
%    'Callback',callback);
% rewritten due to bugs in previous code:
callback=[vw.name,'=computeProjectedMap(',vw.name,',''co''); ',...
          vw.name,'=setDisplayMode(',vw.name,',''map'');',...
          vw.name,'=refreshScreen(',vw.name,',1);'];
uimenu(corMenu,'Label','Coherence map','Separator','off',...
    'Callback',callback);

%   vw=setDisplayMode(vw,'projamp');
%   vw=refreshScreen(vw,1);
%callback=[vw.name,'=setDisplayMode(',vw.name,',''projamp''); ',...
%    vw.name,'=refreshScreen(',vw.name,',1);'];
%uimenu(corMenu,'Label','Projected Amplitude map','Separator','off',...
%    'Callback',callback);
callback=[vw.name,'=computeProjectedMap(',vw.name,',''amp''); ',...
          vw.name,'=setDisplayMode(',vw.name,',''map'');',...
          vw.name,'=refreshScreen(',vw.name,',1);'];
uimenu(corMenu,'Label','Amplitude map','Separator','off',...
    'Callback',callback);


% Laminar distance map callback:
callback = [vw.name, ' = DisplayLaminae(', vw.name, ');'];
uimenu(viewMenu, 'Label', 'Laminar distance map', 'Separator', 'off', ...
    'Callback', callback);

% Residual Std map callback:
%   vw=computeStdMap(vw);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
if strcmp(vw.viewType,'Inplane')
    callback=[vw.name,'=loadResStdMap(',vw.name,'); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(viewMenu, 'Label', 'Residual Std Map', 'Separator', 'off',...
        'Callback', callback);
end


% for inplane views, allow
if strcmp(vw.viewType,'Inplane')

    % ----- Anatomy underly sub-menu ----- %
    underlayMenu = uimenu(viewMenu,'Label','Anat Image...','Separator','off');

    % ----- inplane mosaic option ----- %
    % callback: inplaneMontage(vw);
    callback = [sprintf('inplaneMontage(%s);',vw.name)];
    uimenu(underlayMenu, 'Label', 'All Slices', 'Separator', 'on', ...
        'Callback',callback);

    % ----- toggle direction labels ----- %
    % callback: vw = setInplaneDirLabel(vw);
    callback = sprintf('%s = setInplaneDirLabel(%s);',vw.name,vw.name);
    uimenu(underlayMenu,'Label','Set direction labels','Separator','off',...
        'Callback',callback);


    % ----- set Anat Underlay UI -------- %
    % callback: vw = setUnderlay(vw);
    callback = sprintf('%s = setUnderlay(%s);',vw.name,vw.name);
    uimenu(underlayMenu,'Label','Change Underlay...','Separator','off',...
        'Callback',callback);

elseif ismember(vw.viewType, {'Volume' 'Gray'})
    % ----- Anatomy underly sub-menu ----- %
    underlayMenu = uimenu(viewMenu,'Label','Anat Image...','Separator','off');

    % ----- flip L/R ----- %
    callback = sprintf('%s.ui.flipLR=1; refreshScreen(%s, 0);',vw.name,vw.name);
    uimenu(underlayMenu, 'Label', 'Radiological L/R', 'Separator', 'on',...
        'Callback', callback);

    callback = sprintf('%s.ui.flipLR=0; refreshScreen(%s, 0);',vw.name,vw.name);
    uimenu(underlayMenu,'Label', 'mrVista L/R', 'Separator', 'off',...
        'Callback', callback);
    
    % ----- Publish 3-view Image ----- %
    uimenu(underlayMenu, 'Label', 'Publish Figure', ...
        'Separator', 'off', 'Callback',sprintf('publish3View(%s); ', vw.name));    

    % ----- ROI slice montage ----- %
    uimenu(underlayMenu, 'Label', 'Show ROI Slice Montage', ...
        'Separator', 'off', 'Callback','showROISlices;');

elseif isequal(vw.viewType, 'Flat')
    % ----- Option to toggle L/R flip for each hemisphere ----- %
    flipLRMenu = uimenu(viewMenu, 'Label', 'Flip Flat Patch L/R');

    % Left hemisphere toggle
    callback = sprintf(['val = umtoggle(gcbo); %s.flipLR(1) = val; ' ...
                        '%s = refreshScreen(%s); '], vw.name, vw.name, ...
                        vw.name);
    vw.ui.flipLHMenu = uimenu(flipLRMenu, 'Label', 'Left Hemisphere', ...
                        'Callback', callback, 'Checked', 'off');

    % Right hemisphere toggle
    callback = sprintf(['val = umtoggle(gcbo); %s.flipLR(2) = val; ' ...
                        '%s = refreshScreen(%s); '], vw.name, vw.name, ...
                        vw.name);
    vw.ui.flipRHMenu = uimenu(flipLRMenu, 'Label', 'Right Hemisphere', ...
        'Callback', callback, 'Checked', 'off');


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Select Slice Coords for Volume view %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(vw.viewType,'Volume') | strcmp(vw.viewType,'Gray')
    % Select Slice Coords callback:
    %   vw=selectSliceCoords(vw);
    callback=[vw.name,'=selectSliceCoords(',vw.name,');'];
    uimenu(viewMenu,'Label','Select Slice Coords','Separator','on',...
        'Callback',callback);

    % Set the current location to the maximum parameter map value of the Current ROI
    % (moved up one, I like having the 'find ROI center' option be the last
    % one. Hope it's no big deal. --ras, 02/07)
    %   vw=selectCurROISlice(vw);
    %   vw=refreshScreen(vw);
    callback=[vw.name,'=selectCurROISlice(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(viewMenu,'Label','Find Current ROI Maximum Map Value','Separator','off',...
        'Callback',callback);
    
    % Select Current ROI Slice  callback:
    %   vw=selectCurROISlice(vw);
    %   vw=refreshScreen(vw);
    callback=[vw.name,'=selectCurROISlice(',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(viewMenu,'Label','Find Current ROI','Separator','off',...
        'Callback',callback);

end


% Toggle figure menus:
addFigMenuToggle(viewMenu);


% vw=refreshScreen(vw);
callback=[vw.name,'= refreshScreen(',vw.name,');'];
uimenu(viewMenu,'Label','Refresh','Separator','off',...
    'Callback',callback);

return
