function [roi, roiNot] = dtiRoiClip(roi, rlClip, apClip, siClip)
% 
% [roi, roiNot] = dtiRoiClip(roi, rlClip, apClip, siClip)
%
% Clips a dti ROI. 
%
% HISTORY:
% 2005.01.05 RFD wrote it.

if(nargin<4) siClip = []; end
if(nargin<3) apClip = []; end
if(nargin==1)
    newName = [roi.name '_clip'];
    prompt = {'Left (-80) Right (+80) clip (blank for none):',...
          'Posterior (-120) Anterior (+80) clip (blank for none):',...
          'Inferior (-50) Superior (+90) clip (blank for none):',...
          'New ROI name:'};
    defAns = {'','','',newName};
    resp = inputdlg(prompt,'Clip Current ROI',1,defAns);
    if(isempty(resp))
        disp('User cancelled clip.');
        return;
    end
    rlClip = str2num(resp{1});
    apClip = str2num(resp{2});
    siClip = str2num(resp{3});
    roi.name = resp{4};
end

keep = ones(size(roi.coords,1),1);
if(~isempty(rlClip))
    keep = keep & (roi.coords(:,1)<rlClip(1) | roi.coords(:,1)>rlClip(2));
end
if(~isempty(apClip))
    keep = keep & (roi.coords(:,2)<apClip(1) | roi.coords(:,2)>apClip(2));
end
if(~isempty(siClip))
    keep = keep & (roi.coords(:,3)<siClip(1) | roi.coords(:,3)>siClip(2));
end
coords = roi.coords;
roi.coords = coords(keep,:);
if(nargout>1)
    roiNot = roi;
    roiNot.coords = coords(~keep,:);
    roiNot.name = [roi.name '_NOT'];
end
return;