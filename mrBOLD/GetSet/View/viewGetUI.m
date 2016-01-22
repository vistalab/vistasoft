function val = viewGetUI(vw,param,varargin)
% Get data from various view structures
%
% This function is wrapped by viewGet. It should not be called by anything
% else other than viewGet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];


switch param
    
    case 'ishidden'
        val = strcmp(viewGet(vw, 'name'), 'hidden');
    case 'ui'
        if (checkfields(vw, 'ui'))
            val = vw.ui;
        else
            warning('vista:viewError','No user interface found. Returning empty...');
        end
    case 'fignum'
        if (checkfields(vw, 'ui', 'figNum'))
            if isnumeric(vw.ui.figNum), val = vw.ui.figNum;
            else                           val = vw.ui.figNum.Number; end
        else
            warning('vista:viewError','No figure number found. Returning empty...');
        end
    case 'windowhandle'
        if (checkfields(vw, 'ui', 'windowHandle'))
            val = vw.ui.windowHandle;
        else
            warning('vista:viewError','No window handle found. Returning empty...');
        end
    case 'displaymode'
        if (checkfields(vw, 'ui', 'displayMode'))
            val = vw.ui.displayMode;
        else
            warning('vista:viewError', 'No display mode found. Returning empty...');
        end
    case 'anatomymode'
        if (checkfields(vw, 'ui', 'anatMode'))
            val = vw.ui.anatMode;
        else
            warning('vista:viewError', 'No anatomy mode found. Returning empty...');
        end
    case 'coherencemode'
        if (checkfields(vw, 'ui', 'coMode'))
            val = vw.ui.coMode;
        else
            warning('vista:viewError', 'No coherence mode found. Returning empty...');
        end
    case 'correlationmode'
        if (checkfields(vw, 'ui', 'corMode'))
            val = vw.ui.corMode;
        else
            warning('vista:viewError', 'No correlation mode found. Returning empty...');
        end
    case 'phasemode'
        if (checkfields(vw, 'ui', 'phMode'))
            val = vw.ui.phMode;
        else
            warning('vista:viewError', 'No phase mode found. Returning empty...');
        end
    case 'amplitudemode'
        if (checkfields(vw, 'ui', 'ampMode'))
            val = vw.ui.ampMode;
        else
            warning('vista:viewError', 'No amplitude mode found. Returning empty...');
        end
    case 'projectedamplitudemode'
        if (checkfields(vw, 'ui', 'projampMode'))
            val = vw.ui.projampMode;
        else
            warning('vista:viewError', 'No projected amplitude mode found. Returning empty...');
        end
    case 'mapmode'
        if (checkfields(vw, 'ui', 'mapMode'))
            val = vw.ui.mapMode;
        else
            warning('vista:viewError', 'No map mode found. Returning empty...');
        end
    case 'zoom'
        if checkfields(vw, 'ui', 'zoom')
            val = vw.ui.zoom;
        else
            warning('vista:viewError', 'No UI zoom setting found. Returning empty...');
        end
    case 'crosshairs'
        if checkfields(vw, 'ui', 'crosshairs')
            val = vw.ui.crosshairs;
        else
            warning('vista:viewError', 'No crosshairs found. Returning empty...');
        end
    case 'locs'
        if ~isfield(vw, 'loc')
            if checkfields(vw, 'ui', 'sliceNumFields')
                % single-orientation vw: get from slice # fields
                str = (get(vw.ui.sliceNumFields, 'String'))';
                for n=1:3, val(n) = str2num(str{n}); end %#ok<ST2NM>
            else
                warning('vista:viewError', 'No cursor location found. Returning empty...');
            end
        else
            val = vw.loc;
        end
        
    case 'phasecma'
        % This returns only the color part of the map
        nGrays = viewGet(vw, 'curnumgrays');
        if (isempty(nGrays)),
            warning('vista:viewError', 'Number of grays necessary to retrieve phase color map. Returning empty...');
            return;
        end
        if (checkfields(vw, 'ui', 'phMode', 'cmap'))
            val = round(vw.ui.phMode.cmap(nGrays+1:end,:) * 255)';
        else
            warning('vista:viewError', 'No phase color map found. Returning empty...');
        end
    case 'cmapcurrent'
        nGrays = viewGet(vw, 'curnumgrays');
        displayMode = viewGet(vw, 'displayMode');
        if (isempty(displayMode) || isempty(nGrays)),
            warning('vista:viewError', 'Display mode/number of grays necessary to retrieve color map. Returning empty...');
            return;
        end
        
        displayMode = [displayMode 'Mode'];
        if (checkfields(vw, 'ui', displayMode, 'cmap'))
            val = round(vw.ui.(displayMode).cmap(nGrays+1:end,:) * 255)';
        else
            warning('vista:viewError', 'No color map found for display mode ''%s''. Returning empty...', displayMode);
        end
        
    case 'cmapcurmodeclip'
        displayMode = viewGet(vw, 'displayMode');
        if (isempty(displayMode)),
            warning('vista:viewError', 'Display mode necessary to retrieve clip mode. Returning empty...');
            return;
        end
        
        displayMode = [displayMode 'Mode'];
        if (checkfields(vw, 'ui', displayMode, 'clipMode'))
            val = vw.ui.(displayMode).clipMode;
        else
            warning('vista:viewError', 'No clip mode found for display mode ''%s''. Returning empty...', displayMode);
        end
    case 'cmapcurnumgrays'
        displayMode = viewGet(vw, 'displayMode');
        if (isempty(displayMode)),
            warning('vista:viewError', 'Display mode necessary to retrieve number of grays. Returning empty...');
            return;
        end
        
        displayMode = [displayMode 'Mode'];
        if (checkfields(vw, 'ui', displayMode, 'numGrays'))
            val = vw.ui.(displayMode).numGrays;
        else
            warning('vista:viewError', 'No number of grays found for display mode ''%s''. Returning empty...', displayMode);
        end
    case 'cmapcurnumcolors'
        displayMode = viewGet(vw, 'displayMode');
        if (isempty(displayMode)),
            warning('vista:viewError', 'Display mode necessary to retrieve number of colors. Returning empty...');
            return;
        end
        
        displayMode = [displayMode 'Mode'];
        if (checkfields(vw, 'ui', displayMode, 'numColors'))
            val = vw.ui.(displayMode).numColors;
        else
            warning('vista:viewError', 'No number of grays found for display mode ''%s''. Returning empty...', displayMode);
        end
    case 'flipud'
        % Return the boolean indicating whether to invert the image u/d in
        % the graphical user interface.  It is sometimes convenient to do
        % this in the Inplane view if the top of the slice corresponds to
        % the bottom of the brain.
        % Example:
        %   flipud = viewGet(vw, 'flip updown');
        if checkfields(vw, 'ui', 'flipUD'), val = vw.ui.flipUD;
        else                                val = 0; end
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
