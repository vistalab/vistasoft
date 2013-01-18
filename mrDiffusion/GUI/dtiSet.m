function dtiH = dtiSet(dtiH,param,val,varargin)
% Setting data in the dtiH from the mrDiffusion window structure
%
%    dtiH = dtiSet(dtiH,param,val,varargin);
%
%  The dtiH are obtained from mrDiffusion window as 
%
%        dtiH = guidata(dtiF);
%
%  Changes to the dtiH are updated in the window with another guidata
%  call in the form guidata(gcf,dtiH), or if you know the figHandle
%
%        guidata(dtiF,dtiH);
%
% See t_mrd for a discussion of opening mrDiffusion and managing the dtiH
% handles.
%
% PARAMS:
%  Parameters (param) are specified in free text which is then transformed
%  to lower case with spaces removed.  Hence, 'AC PC position' is
%  transformed to 'acpcposition'.
% 
%  There are not enough sets here.  I am guessing that most of the code
%  does not rely on this yet.  We should be converting.  Particularly
%  missing are the sets for fiber group data, T1 data, B0 data - although,
%  they may be attached to the mesh rather than here directly.  
%
%   {'acpc position','acpcpos'} 
%   {'talairach position','talpos'}
%   {'mrmesh'}
%   {'cur background num','currentbackgroundimagenumber','curbgnum','curbacknumber','curbacknum'}
%   {'cur overlay num'}
%   {'cur overlay thresh'} % convert the normalized input value into real image units.
%   {'cur overlay thresh slider'}
%   {'current fiber group','fgcurrent','fgcur','currentfg','curfg'}
%   {'current roi','roicurrent','roicur','curroi'}
%   {'dti to anat xform','dti2anatxform','dtianatxform'}
%   {'acpc xform'}   % T1 to acpc transform
%   {'add standard space'}
%
%   {'add fiber group'}
%   {'replace fiber group'}
%
% Examples: 
%
%
% (c) Stanford VISTA Team, 2008

if notDefined('dtiH'), error('Must pass in dtiFiberUI data dtiH'); end
if notDefined('param'), error('Unknown parameter'); end
if ~exist('val','var'), error('No value specified.'); end

% Squeeze param string spaces and set to lower case
param = mrvParamFormat(param);

switch lower(param)
    
    % Cursor management
    case {'acpcposition','acpcpos'}
        set(dtiH.cbTalairach,'Value',0);
        set(dtiH.editPosition, 'String',num2str(val));
        
    case {'talairachposition','talpos'}
        set(dtiH.cbTalairach,'Value',1);
        set(dtiH.editPosition, 'String',num2str(val));
        
        % mrMesh
    case {'mrmesh'}
        dtiH.mrMesh = val;
                
    case {'curbackgroundnum','currentbackgroundimagenumber','curbgnum','curbacknumber','curbacknum'}
        set(dtiH.popupBackground,'Value',val);
    
        % Overlay management
    case {'curoverlaynum'}
        set(dtiH.popupOverlay,'Value',val);   
        
    case {'overlayalpha'}
        % alpha = str2double(dtiGet(dtiH.editOverlayAlpha,'string'));
        set(dtiH.editOverlayAlpha,'string',sprintf('%0.5g',val));
        
    case {'curoverlaythresh'}
        % convert the normalized input value into real image units.
        curRng = dtiGet(dtiH,'curOverlayRange');
        val = curRng(1)+val*(curRng(2)-curRng(1));
        if(val<curRng(1)), val=curRng(1); end
        if(val>curRng(2)), val=curRng(2); end
        set(dtiH.editOverlayThresh, 'String', sprintf('%0.5g',val));
        
    case {'curoverlaythreshslider'}
        curRng = dtiGet(dtiH,'curOverlayRange');
        if(val<curRng(1)), val=curRng(1); end
        if(val>curRng(2)), val=curRng(2); end
        set(dtiH.editOverlayThresh, 'String', sprintf('%0.5g',val));
        % convert real image units to normalized units for the slider.
        val = (val-curRng(1))./(curRng(2)-curRng(1));
        set(dtiH.slider_overlayThresh, 'Value', val);
        
        
        % Fiber group
        % We should be able to replace fg number N
        % We should distinguish fiber group number and fiber group data
        % calls more clearly.
    case {'fibergroupnumber','curfibergroupnum','currentfibergroupnumber'}
        % Set the current fiber group number
        % dtiH = dtiSet(dtiH,'cur fg',1);
        dtiH.curFiberGroup = val;
        
    case {'currentfibergroup','fgcurrent','fgcur','currentfg','curfg'}
        % Replace the current fiber group structure 
        % dti = dtiSet(dti,'current fiber group',fg);
        %
        gn = dtiGet(dtiH,'curFiberGroupNum');
        % if(gn<=0 || isempty(dtiH.fiberGroups)), error('No fibers!'); end
        if(gn<=0), error('Bad fiber group number'); end
        if isempty(dtiH.fiberGroups), dtiH.fiberGroups = val;
        else  dtiH.fiberGroups(gn) = val; 
        end

    case {'addfibergroup'}
        % Add a new fiber group structure
        %   dtiH = dtiSet(dtiH,'add fiber group',fg);
        %
        % Replaces an existing one
        %   dtiH = dtiSet(dtiH,'replace fiber group',fg,num);
        if isempty(varargin)
            % Add to the end of the list.
            dtiH = dtiAddFG(val,dtiH);
            % Also sets this to current and refreshes the window.  Not sure
            % we should do all that.
        else
            % Person sent in a specific slot using replace
            thisNum = varargin{1};
            if thisNum < 1, error('Bad fg number'); end
            
            % Matlab behaves badly if fiberGroups is empty.
            if isempty(dtiH.fiberGroups),  dtiH.fiberGroups = val;
            else
                % We change all of the fiber groups to include the union of
                % the fields that exist and then add the new one.
                nGroups = dtiGet(dtiH,'n fiber groups');
                
                % Add the fields from val to the current groups
                for ii=1:nGroups
                    currentGroups(ii) = structMatchFields(dtiH.fiberGroups(ii),val);
                end
                
                % Add the fields from the current groups to val
                val = structMatchFields(val,currentGroups(1));
                
                % Now put val into the named slot. And the current groups
                % into the figure handle.
                currentGroups(thisNum) = val;
                dtiH.fiberGroups = currentGroups;
            end
            
            % Should we make this FG the current one?
            % Set the current fg to be the one we just added.
            dtiH.curFiberGroup = thisNum;
            % We don't refresh because, well, that is a different job.
        end
    case {'replacefibergroup'}
        % Replace fiber group 'num' with fg 
        %  dtiSet(dtiH,'replace fiber group',fg,num)
        if isempty(varargin)
            error('Fiber group number required');
        else
            num = varargin{1};
            if length(dtiH.fiberGroups) < num
                error('No fiber group number %d\n',num);
            end
        end
        dtiH = dtiSet(dtiH,'add fiber group',val,num);
        
        % Region of interests
    case {'addroi'}
        % Add an roi structure to the mrDiffusion handle
        %   dtiSet(dtiH,'add roi',roi,setCurrent);
        setCurrent = 1;
        if isempty(varargin)
            dtiH = dtiAddROI(val,dtiH,setCurrent);
        else
            setCurrent = varargin{1};
            dtiH = dtiAddROI(val,dtiH,setCurrent);
        end
    case {'replaceroi'}
            % Not yet implemented
            % dtiSet(dtiH,'replace roi',roi,num);
            error('Not yet implemented');
    case {'currentroi','roicurrent','roicur','curroi'}
        rn = dtiGet(dtiH,'curRoiNum');
        if(rn<=0 || isempty(dtiH.rois)), error('No ROIs!'); end
        dtiH.rois(rn) = val;
        
        % Transforms
    case {'dtitoanatxform','dti2anatxform','dtianatxform'}
        dtiH.vec.mat = val;
        dtiImageNames = {'b0','fa'};
        for(ii=1:length(dtiImageNames))
            n = dtiGet(dtiH,'namedImgNum',dtiImageNames{ii});
            if(~isempty(n)), dtiH.bg(n).mat = val; end
        end
        
    case {'acpcxform'}
        % T1 to acpc transform
        dtiH.acpcXform = val;

    case {'addstandardspace'}
        curStr = get(dtiH.popupStandardSpace,'String');
        % Only add it if it doesn't already exist
        if(isempty(strmatch(val,curStr,'exact')))
            curStr{end+1} = val;
            set(dtiH.popupStandardSpace,'String',curStr);
        end
        
    otherwise
        error('Unknown parameter');
end

return