function n=findROI(view,name);
% function n=findROI(view,name);
%
% finds name in the ROI list of view and returns n if found, 0 if 
% not found

n=0;

for i=1:length(view.ROIs)
  if strcmp(name,view.ROIs(i).name)
    n=i;
  end
end
  