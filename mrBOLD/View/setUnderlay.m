function view = setUnderlay(view,underlayName);
% view = setUnderlay(view,[underlayName]):
%
% provides an interface for setting the underlay
% (anatomical) image in mrVista.
%
% This is, essentially, a hack: it creates
% a variable 'underlay' which contains information
% on a series of possible underlays for the current
% view. By default this starts with T1 anatomtical
% images that are normally shown, but other possibilities
% include the mean T2* functionals from a user-selected
% set of scans, or interpolated inplanes if an alignment
% is present. These images are all scaled to be equal to
% the viewSize of the current view, and can be swapped
% into the view's 'anat' field to quickly change underlays.
%
% The underlay variable can be appended to the 
% anat.mat file containing the T1 images, for later
% use. Normally, the 'anat' field in this file is 
% unchanged (so if you start up another view it uses the
% normal T1 images). However, if you press the 'Save as
% Default' button, it will set the current underlay as
% the 'anat' matrix, so future use of this session -- 
% including doing an alignment with mrAlign3 -- will use
% that set of underlays. Note also, this does _not_ cause
% the T1 images to be lost, they are saved in the underlay
% variable and they can be swapped back in later.
%
% This should be useful in case a subject moved between
% inplanes and functional scans; or if the inplanes are
% not as clear at showing sulci and gyri as the interpolated
% inplanes (and you have faith in your alignment); or if you
% want to do an alignment of the mean functionals directly
% on to a vAnatomy. 
%
% Down the line, however, it would probably make more sense
% to have the anat matrix be something like a cell or struct
% array, and directly append this variable instead of having
% the extra underlay variable. (Also to do: set mrInitRet
% to accept mean functionals as a substitute for T1s, if you
% don't have a good set of those.)
%
% ras 08/10/04.
if ~isequal(view.viewType,'Inplane')
    fprintf('Sorry, only works with Inplane views right now.\n');
    return
end

global underlay HOMEDIR dataTYPES

% initialize underlay struct if it's empty
if isempty(underlay)
    underlay = struct('name','T1 Anatomicals','data',view.anat);

    % save the underlay variable in anat.mat
    anatFile = fullfile(HOMEDIR,view.viewType,'anat.mat');
    save(anatFile,'underlay','-append');
    fprintf('Updated anat.mat with underlay data.\n');
end

% open the UI figure
h = setUnderlayFig;

% put the view name as the fig's userdata -- I realize this 
% is a clumsy way to do it, will fix if I find time...
set(h,'UserData',view.name);

% set the default strings for various uicontrols
% to correspond to this view's settings
scan = viewGet(view,'curscan');
hscans = findobj('Parent',h,'Tag','ScansEdit');
set(hscans,'String',num2str(scan));

for i = 1:length(dataTYPES)
    dtnames{i} = dataTYPES(i).name;
end
hdt = findobj('Parent',h,'Tag','DataTypePopup');
set(hdt,'String',dtnames);

for i = 1:length(underlay)
    unames{i} = underlay(i).name;
end
hunderlay = findobj('Parent',h,'Tag','UnderlayListbox');
set(hunderlay,'String',unames);

return
