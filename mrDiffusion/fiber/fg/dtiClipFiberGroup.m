function fg = dtiClipFiberGroup(fg, rlClip, apClip, siClip,saveFlag)
%
% [fg fgNot] = dtiClipFiberGroup(fg, rlClip, apClip, siClip,[saveFlag])
%
% Clips a MrD fiber group. Adapted from dtiFiberUI (RFD)
% If saveFlag == 1 then the fiber group will be written to the working
% directory with the fg.name'_clip'.
%
% HISTORY:
% 03.26.2009 - LMP wrote the thing.
% 08.2009 ER added proper treatment of "subgroup" field.

if notDefined('saveFlag'), saveFlag = 0; end
if(nargin<4) siClip = []; end
if(nargin<3) apClip = []; end
newName = [fg.name '_clip'];
if(nargin==1)
    prompt = {'Left (-80) Right (+80) clip (blank for none):',...
          'Posterior (-120) Anterior (+80) clip (blank for none):',...
          'Inferior (-50) Superior (+90) clip (blank for none):',...
          'New Fiber Group name:'};
    defAns = {'','','',newName};
    resp = inputdlg(prompt,'Clip Current FG',1,defAns);
    if(isempty(resp))
        disp('User cancelled clip.');
        return;
    end
    rlClip = str2num(resp{1});
    apClip = str2num(resp{2});
    siClip = str2num(resp{3});
    fg.name = resp{4};
end
empty = zeros(size(fg.fibers));
for ii=1:length(fg.fibers)
    keep = ones(size(fg.fibers{ii}(1,:)));
    if(~isempty(rlClip))
        keep = keep & (fg.fibers{ii}(1,:)<rlClip(1) | fg.fibers{ii}(1,:)>rlClip(2));
    end
    if(~isempty(apClip))
        keep = keep & (fg.fibers{ii}(2,:)<apClip(1) | fg.fibers{ii}(2,:)>apClip(2));
    end
    if(~isempty(siClip))
        keep = keep & (fg.fibers{ii}(3,:)<siClip(1) | fg.fibers{ii}(3,:)>siClip(2));
    end
    fg.fibers{ii} = fg.fibers{ii}(:,keep);
    empty(ii) = isempty(fg.fibers{ii})|size(fg.fibers{ii},2)==1;
end
fg.fibers = fg.fibers(~empty);
if isfield(fg, 'subgroup')
fg.subgroup = fg.subgroup(~empty);
end
fg.name = newName;

if saveFlag == 1
   dtiWriteFiberGroup(fg,fg.name); 
end
return;