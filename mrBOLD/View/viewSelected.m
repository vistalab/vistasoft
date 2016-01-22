function selectedVIEW = viewSelected(viewType)
%
%   selectedVIEW = viewSelected(viewType);
%
% Author: Wandell
% Purpose:
%   Check for the presence of a currently selected view
%   (FLAT/INPLANE/GRAY/VOLUME). If the global variable (selectedINPLANE,
%   etc.) is defined, and it points to a non-empty cell entry return it. If
%   not, ask the user for a figure number and figure out which VIEW
%   structure is assigned to that figure.
%
%   Developed for open3dWindow, but it should be useful elsewhere the
%   selectedXXXX is needed.
%
% Example:
%   selectedVIEW = viewSelected('gray');
%   selectedVIEW = viewSelected('FLAT');
%   
switch lower(viewType)
    case {'volume','gray','vol'}
        global VOLUME
        global selectedVOLUME
        if     isempty(VOLUME), errordlg('mrVista VOLUME structure required.'); end
        if isempty(selectedVOLUME) | isempty(VOLUME{selectedVOLUME})
            grayList = cellfind(VOLUME);
            if length(grayList) == 1
               selectedVIEW = grayList;    % Only one, must be te answer.
                return;
            else
               str = 'Enter GRAY/VOLUME view figure number';
                vw = VOLUME;  % Query will follow below
            end
        else
            selectedVIEW = selectedVOLUME;
            return;
        end
        
    case {'inplane','ip'}
        global INPLANE
        global selectedINPLANE
        
        if     isempty(INPLANE), errordlg('mrVista INPLANE structure required.'); 
        elseif isempty(selectedINPLANE) | isempty(INPLANE{selectedINPLANE}),
            str = 'Enter INPLANE view figure number';
            vw = INPLANE;
        else
            selectedVIEW = selectedINPLANE;
            return;
        end
        
    case 'flat'
        global FLAT
        global selectedFLAT
        if     isempty(FLAT), errordlg('mrVista FLAT structure required.'); 
        elseif isempty(selectedFLAT) | isempty(FLAT{selectedFLAT}),
            str = 'Enter FLAT view figure number';
            vw = FLAT;
        else
            selectedVIEW = selectedFLAT;
            return;
        end
        
    otherwise
        error('Unknown view type.')
end
prompt={str}; def={'1'};
dlgTitle = 'Selected view';       
lineNo=1;
answer=inputdlg(prompt,dlgTitle,lineNo,def);
if isempty(answer), selectedVIEW = []; return; end
vFigure = str2num(answer{1}); 
if vFigure > 0
    selectedVIEW= fignum2VIEWindex(vFigure); 
else
    selectedVIEW = [];
    warndlg('Problem with VOLUME and selectedVOLUME selections.');
end
return;
