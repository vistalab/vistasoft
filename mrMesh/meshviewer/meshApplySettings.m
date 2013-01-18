function msh = meshApplySettings(msh, settings);
% Apply stored settings to a mrMesh window.
%
% msh = meshApplySettings(<msh>, <settings=get from UI>);
%
% See meshSettings for info on the settings struct. This contains info
% about the lights, camera, main mesh rotation, cursor, and ROI locations.
%
% If the first 'msh' argument is omitted, gets the selected mesh from the
% selected gray view. If settings is omitted, assumes this function was
% called from a GUI, and searches for a listbox uicontrol with the tag
% 'MeshSettingsList'.
%
% ras, 03/14/06.
if notDefined('msh'), msh = viewGet(getSelectedGray, 'selectedMesh');  end

if notDefined('settings')
    % get from UI -- first need to implement the UI :)
    return    
end

verbose = prefsVerboseCheck;

if verbose
	hmsg = msgbox('Applying Stored Mesh Settings...');
end

% set background color 
msh = mrmSet(msh, 'background', settings.backgroundColor);

% set camera settings
p = settings.camera;
p.actor = 0;
mrMesh(msh.host, msh.id, 'set', p);

% % get an actor list for the lights, mesh below
% actorList = mrmGet(msh, 'ListOfActors');
% actors = actorList.objectList;
%  (temp disabled, very slow, faster if we assume lights are 33 and 34)

% check there are enough actors for the settings (maybe fewer lights, etc)
% N.Y.I.

% set lights
for i = 1:2 % min(length(settings.lights), length(actors)-1)
    if ~isempty(settings.lights(i))
        p = settings.lights(i);
        p.actor = i+32; % actors(i+1);
		try
			% get lighting values from the settings -- sometimes this
			% hangs:
			p.ambient = settings.lights(i).ambient;
			p.diffuse = settings.lights(i).diffuse;
		catch
			% use default values
			p.ambient = [.4 .4 .3]; 
			p.diffuse = [.5 .5 .6]; 
		end
        mrMesh(msh.host, msh.id, 'set', p);
    end
end

% set cursor position
if settings.cursor > 0
    try
        mrmSet(msh, 'CursorVertex', settings.cursor);
    catch
        disp('Could not set cursor')
    end
end
 
% set main mesh rotation, origin
p = mrmGet(msh, 'ActorData', 32);
p.rotation = settings.mesh.rotation;
p.origin = settings.mesh.origin;
p.actor = 32;
mrMesh(msh.host, msh.id, 'set', p);

% % set ROI (n.y.i.)
% if ~isfield(settings.roi, 'error')
%     try
%         
%     catch
%         disp('Could not set ROI')
%     end
% end 
    
if verbose, close(hmsg); end
   
return

