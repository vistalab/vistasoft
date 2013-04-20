function vw = viewSetUI(vw,param,val,varargin)
%Organize methods for setting view parameters.
%
% This function is wrapped by viewSet. It should not be called by anything
% else other than viewSet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'),  error('No view defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'),   val = []; end

mrGlobals;

param = mrvParamFormat(param);


% Standardize the name of the parameter field with name-mapping function
param = viewMapParameterField(param);
paramSplit = viewMapParameterSplit(param);


switch paramSplit
    
    case 'initdisplaymodes'
        vw = resetDisplayModes(vw);
    case 'ui'
        vw.ui = val;
    case 'anatomymode'
        vw.ui.anatMode = val;
    case 'coherencemode'
        vw.ui.coMode = val;
    case 'correlationmode'
        vw.ui.corMode = val;
    case 'phasemode'
        vw.ui.phMode = val;
    case 'fignum'
        vw.ui.figNum = val;
    case 'windowhandle'
        vw.ui.windowHandle = val;
    case 'mainaxishandle'
        vw.ui.mainAxisHandle = val;
    case 'colorbarhandle'
        vw.ui.colorbarHandle = val;
    case 'cbarrange'
        vw.ui.cbarRange = val;
    case 'amplitudemode'
        vw.ui.ampMode = val;
    case 'uiimage'
        vw.ui.image = val;
    case 'projectedamplitudemode'
        vw.ui.projampMode = val;
    case 'mapmode'
        vw.ui.mapMode = val;
    case 'displaymode'
        vw.ui.displayMode = val;
    case 'phasecma'
        nGrays = viewGet(vw, 'curnumgrays');
        
        % allow transposed version (3 x n) instead of usual matlab cmap order (n x 3)
        if size(val, 2) > 3 && size(val, 1)==3, val = val'; end
        if max(val(:)) > 1, val = val ./ 255;               end
        vw.ui.phMode.cmap((nGrays+1):end,:) = val ;
        
    case 'cmap'
        % RFBEDIT: Adding flexibility for hidden views
        nGrays      = viewGet(vw, 'curnumgrays');
        displayMode = viewGet(vw, 'displayMode');
        
        % allow transposed version (3 x n) instead of usual matlab cmap order (n x 3)
        if size(val, 2) > 3 && size(val, 1)==3,	val = val'; end
        if max(val(:)) > 1, val = val ./ 255;		end
        
        displayMode = [displayMode 'Mode'];
        vw.ui.(displayMode).cmap(nGrays+1:end,:) = val;
        vw.ui.(displayMode).name = 'user';
        
    case 'locs'
        % cursor location as [axi cor sag]
        vw.loc = val;
        if checkfields(vw, 'ui', 'sliceNumFields')  % set UI fields
            for n = 1:3
                set(vw.ui.sliceNumFields(n), 'String', num2str(val(n)));
            end
        end
    case 'crosshairs'
        vw.ui.crosshairs = val;
    case 'flipud'
        % Boolean indicating whether to invert the image u/d in
        % the graphical user interface.  It is sometimes convenient to do
        % this in the Inplane view if the top of the slice corresponds to
        % the bottom of the brain.
        % Example:
        %   vw = viewSet(vw, 'flip updown', true);
        if checkfields(vw, 'ui'),   vw.ui.flipUD = val; end
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return