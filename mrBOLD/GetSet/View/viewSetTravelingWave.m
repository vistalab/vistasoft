function vw = viewSetTravelingWave(vw,param,val,varargin)
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

switch param
    
    case 'coherence'
        % This must be a cell array of 1 x nScans
        vw.co = val;
    case 'scanco'
        if length(varargin) < 1, error('You must specify a scan number.'); end
        scan = varargin{1};
        vw.co{scan} = val;
    case 'phase'
        vw.ph = val;
    case 'scanph'
        if length(varargin) < 1, error('You must specify a scan number.'); end
        scan = varargin{1};
        vw.ph{scan} = val;
    case 'amplitude'
        vw.amp = val;
    case 'scanamp'
        if length(varargin) < 1, error('You must specify a scan number.'); end
        scan = varargin{1};
        vw.ph{scan} = val;
    case 'phwin'
        %vw = setPhWindow(vw, val);
        if length(val) ~= 2,
            error('[%s]: 2 values needed to set phase window', mfilename);
        end
        if strcmpi(viewGet(vw, 'name'), 'hidden')
            % hidden view: set in a special settings field
            vw.settings.phWin = val;
            
        else
            % non-hidden view: set in UI
            setSlider(vw, vw.ui.phWinMin, val(1));
            setSlider(vw, vw.ui.phWinMax, val(2));
            
        end
    case 'spatialgrad'
        vw.spatialGrad = val;
    case 'cothresh'
        vw = setCothresh(vw, val);
    case 'refph'
        vw.refPh = val;
    case 'ampclip'
        if checkfields(vw, 'ui', 'ampMode', 'clipMode')
            vw.ui.ampMode.clipMode = val;
            vw = refreshScreen(vw);
        else
            error('Can''t set Amp Clip Mode -- no UI information in this view.');
        end
        
    case 'framestouse'
        % Set the time frames in the current or specified
        % scan to be used for coranal (block) analyses
        % Example:
        %   scan = 1;
        %   nframes = viewGet(vw, 'nframes', scan);
        %   vw = viewSet(vw,'frames to use', 7:nframes, scan);
        %
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt         = viewGet(vw, 'dtStruct');
        blockParms = dtGet(dt,'bparms');
        blockParms(scan).framesToUse = val;
        dt = dtSet(dt, 'blockparams', blockParms);
        dtnum = viewGet(vw, 'current dt');
        dataTYPES(dtnum) = dt; %#ok<NASGU>

    case 'ncycles'
        % Return the number of cycles in the current or specified scan
        % (assuming scan is set up for coranal).
        %   scan = 1; vw = viewSet(vw,'num cycles', 8, scan);
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt         = viewGet(vw, 'dtStruct');
        blockParms = dtGet(dt,'bparms');
        blockParms(scan).nCycles = val;
        dt = dtSet(dt, 'blockparams', blockParms);
        dtnum = viewGet(vw, 'current dt');
        dataTYPES(dtnum) = dt; %#ok<NASGU>
        
     
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return