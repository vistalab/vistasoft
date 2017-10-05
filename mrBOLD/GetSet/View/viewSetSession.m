function vw = viewSetSession(vw,param,val,varargin)
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

if ~exist('vw', 'var'), error('No view defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'),   val = []; end

mrGlobals;

switch param
    
    case 'homedir'
        HOMEDIR = val;  %#ok<NASGU>
    case 'sessionname'
        vw.sessionCode = val;
    case 'subject'
        vw.subject = val;
    case 'name'
        vw.name = val;
    case 'viewtype'
        vw.viewType = val;
    case 'subdir'
        vw.subdir = val;
    case 'curdt'
        if isnumeric(val), vw = selectDataType(vw, val); end
        if ischar(val)
            match = false;
            for dt =1:length(dataTYPES) %#ok<*NODEF>
                if strcmpi(val, dataTYPES(dt).name), vw = viewSet(vw, 'curdt', dt); end
                match = true;
            end
            if ~match, warning('vista:viewError', 'DataTYPE %s not found', val); end
        end
        
    case 'curslice'
        sliceNum = val;
        vw.tSeriesSlice = sliceNum;
        
        if isequal(vw.name,'hidden')
            return
        end
        
        switch vw.viewType
            case 'Inplane'
                setSlider(vw,vw.ui.slice, sliceNum);
                
                % remove the trailing digits
                str = sprintf('%.0f', sliceNum);
                set(vw.ui.slice.labelHandle, 'String', str);
                
            case {'Volume', 'Gray'}
                volSize = viewGet(vw,'Size');
                sliceOri=getCurSliceOri(vw);
                sliceNum=clip(val,1,volSize(sliceOri));
                set(vw.ui.sliceNumFields(sliceOri), 'String',num2str(sliceNum));
                
            case 'Flat' % this case accomplishes nothing since the variable h is not used.
                if checkfields(vw, 'numLevels')
                    % 'flat-level' view
                    if val > 2 + vw.numLevels(1), h = 2;
                    else                          h = 1; end
                else
                    % regular flat view
                    if val <= 2
                        h = val; %sliceNum
                    else
                        h = [1 2];  % both hemispheres at once
                    end
                end
                selectButton(vw.ui.sliceButtons,h)
        end
        
    case 'refreshfn'
        vw.refreshFn = val;
        
    case 'curscan'
        %vw = setCurScan(vw,val);
        vw.curScan = val;
        % If we have a GUI open, update it as well:
        if checkfields(vw, 'ui', 'scan'),
            setSlider(vw,vw.ui.scan,val,0);
        end
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return