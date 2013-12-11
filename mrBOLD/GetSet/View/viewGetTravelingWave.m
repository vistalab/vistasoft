function val = viewGetTravelingWave(vw,param,varargin)
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
    
    case 'coherence'
        % Coherence for all voxels, all scans in current dataTYPE
        %   co = viewGet(vw, 'Coherence');
        val = vw.co;
    case 'scanco'
        % Coherence for single scan
        %   scanco = viewGet(vw, 'scan coherence', 1);
        if length(varargin) < 1, nScan = viewGet(vw, 'Current Scan');
        else                     nScan = varargin{1};   end
        if ~isempty(vw.co) && length(vw.co) >=nScan, val = vw.co{nScan};
        else                val = []; end
    case 'spatialgrad'
        val = vw.spatialGrad;
    case 'phase'
        % Phase for all voxels, all scans in current dataTYPE
        %   ph = viewGet(vw, 'Phase');
        val = vw.ph;
    case 'scanph'
        % Phase values for single scan
        %   viewGet(vw,'Scan Phase',1);
        if length(varargin) < 1, nScan = viewGet(vw, 'curScan');
        else                     nScan = varargin{1}; end
        if ~isempty(vw.ph), val = vw.ph{nScan};
        else                val = []; end
    case 'amplitude'
        % Amplitude for all voxels, all scans in current dataTYPE
        %   amp = viewGet(vw, 'Amplitude');
        val = vw.amp;
    case 'scanamp'
        % Amplitude values for single scan (selected scan or specified
        % scan).
        %   scan = 1; scanAmp = viewGet(vw,'scan Amp', scan);
        %   scanAmp = viewGet(vw,'scan Amp');
        if length(varargin) < 1, nScan = viewGet(vw, 'curScan');
        else                     nScan = varargin{1}; end
        if ~isempty(vw.amp), val = vw.amp{nScan};
        else                 val = []; end
    case 'refph'
        % Return the reference phase used for computing phase-referred
        % coherence. Should be [0 2*pi]?
        %   refph = viewGet(vw,'reference phase');
        if isfield(vw, 'refPh'),    val = vw.refPh;
        else                        val = [];       end
    case 'ampmap'
        % Return the colormap currently used to display amplutitude data.
        % Should be 3 x numColors.
        %   ampMap = viewGet(vw, 'amplitude color map');
        nGrays = viewGet(vw, 'curnumgrays');
        val = round(vw.ui.ampMode.cmap(nGrays+1:end,:) * 255)';
    case 'coherencemap'
        % Return the colormap currently used to display coherence data.
        % Should be 3 x numColors.
        %   cohMap = viewGet(vw, 'coherence color map');
        nGrays = viewGet(vw, 'curnumgrays');  val = round(vw.ui.coMode.cmap((nGrays+1):end,:) * 255)';
    case 'correlationmap'
        % Return the colormap currently used to display correlation data.
        % Should be 3 x numColors.
        %   corMap = viewGet(vw, 'correlation color map');
        %
        % [Q: what is a correlation map and how does it differ from
        % coherence map?]
        nGrays = viewGet(vw, 'curnumgrays');  val = round(vw.ui.corMode.cmap((nGrays+1):end,:) * 255)';
    case 'cothresh'
        % Return the coherence threshold. Should be in [0 1].
        %   cothresh = viewGet(vw, 'Coherence Threshold');
        if ~isequal(vw.name,'hidden')
            val = get(vw.ui.cothresh.sliderHandle,'Value');
        else
            % threshold vals: use accessor function, deals w/ hidden views
            if checkfields(vw, 'settings', 'cothresh')
                val = vw.settings.cothresh;
            else
                % arbitrary val for hidden views
                val = 0;
            end
        end
    case 'phwin'
        % Return  phWindow values from phWindow sliders (non-hidden views)
        % or from the view.settings.phWin field (hidden views). If can't
        % find either, defaults to [0 2*pi].
        %   phwin = viewGet(vw, 'phase window');
        val = getPhWindow(vw);
        
        % colorbar-related params: this code uses a simple linear
        % mapping from coAnal phase -> polar angle or eccentricity
    case 'ncycles'
        % Return the number of cycles in the current or specified scan
        % (assuming scan is set up for coranal).
        %   nycles = viewGet(vw,'ncycles')
        %   scan = 1; nycles = viewGet(vw,'ncycles', scan)
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        curDT = viewGet(vw,'curdt');
        blockParms = dtGet(dataTYPES(curDT),'bparms',scan);
        % There are some issues with event and block that we need to figure out
        % here.
        
        if isfield(blockParms,'nCycles'), val = blockParms.nCycles;
        else                              val = 1;
        end
        
    case 'framestouse'
        % Return a vector of time frames in the current or specified
        % scan to be used for coranal (block) analyses
        %   frames = viewGet(vw,'frames to use');
        %   scan = 1; frames = viewGet(vw,'frames to use',scan);
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt         = viewGet(vw, 'dtStruct');
        blockParms = dtGet(dt,'bparms',scan);
        if checkfields(blockParms, 'framesToUse')
            val = blockParms.framesToUse;
        else
            val = 1: viewGet(vw,'nFrames',scan);
        end
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
