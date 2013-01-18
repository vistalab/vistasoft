function [view,OK] = combineMultROIsWithCurrent(view)
% function [view,OK] = combineMultROIsWithCurrent(view)
% 
% opens a dialog box that allows the user to combine multiple ROIs
% with the current selection
% into a set of new ROI using logical operators:
%
% Union:  set union
% Intersection : set intersection
% XOR : exclusive or
% A not B : set difference (all elements in A that are not also
%           in B)
% 
% rmk 10/30/98
% fwc 12/07/02 multiple ROIs
% fwc 25/07/02  fixed color assignment
% ras 04/10/05 uses generalDialog

% Select ROIs to combine with current
nROIs=size(view.ROIs,2);
roiList=cell(1,nROIs);
for r=1:nROIs
    roiList{r}=view.ROIs(r).name;
end
selectedROIs = find(buttondlg('ROIs to combine with current ROI',roiList));
nROIs=length(selectedROIs);
if (nROIs==0)
    error('No ROIs selected');
end

curRoi=view.selectedROI;
curRoiName = view.ROIs(view.selectedROI).name;

actionList = {'Union','Intersection','XOR','A not B'};

actionChar = char(actionList)';
actionChar = actionChar(1,:);

actionNum=2; % default to Intersection


colorList = {'yellow','magenta','cyan','red','green','blue'};

colorChar = char(colorList)';
colorChar = colorChar(1,:);

uiStruct.string = 'Action';
uiStruct.fieldName = 'action';
uiStruct.list = actionList;
uiStruct.choice = actionNum;
uiStruct.style = 'popupmenu';
uiStruct.value = 'Union';

ttl = sprintf('Combine ROIs with %s',curRoiName);
outStruct = generalDialog(uiStruct,ttl);

% If user selects 'OK', change the parameters.  Otherwise the
% user isn't happy with these settings so bail out.

if ~isempty(outStruct)
  % if modification occurs then perform operation and create
  % combined ROI:
  
  % first find input ROIs:
  c=1;
  maxc=length(colorList);
  for r=1:nROIs
      if selectedROIs(r)~=curRoi
          % now perform operation:
          coords=combineCoords(view.ROIs(curRoi).coords,view.ROIs(selectedROIs(r)).coords,outStruct.action);
          name=[view.ROIs(selectedROIs(r)).name '_' curRoiName];
          %curScan = getCurScan(view);
          %co = getCurDataROI(view,'co',curScan,coords);
          % we only add the scan if there are
          if isempty(coords)
               warnstr=['FYI: ROI ' name ' was not created because it was empty.'];
               disp(warnstr);
          else
              
              % now add new ROI:
             
              ROI.color=colorChar(c);
              c=c+1;
              if c>maxc
                  c=1;
              end
              ROI.coords=coords;
              ROI.name=name;
              ROI.viewType=view.viewType;
             
              ROI=sortFields(ROI);  
              
              view=addROI(view,ROI);
          end
      end
  end
  OK = 1;
else 
  OK = 0;
end


return


