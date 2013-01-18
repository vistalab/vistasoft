function [hiso]=renderGray3d(view,hemisphere)
% Function to render the current functional data and gray nodes in 3D
% Note: Requires you to re-install segmentation in order to generate
% VOLUME.inplaneLeftIndices. It will do this automatically...
% Also: You must have a gray window open, selected and some phase data in
% there.
% view should be a VOLUME view (i.e. VOLUME{selectedVOLUME}) 
% hemisphere is either 'left' or 'right'
mrGlobals;
globalVolumeSet=0;

if (~exist('view','var'))
    if (isempty(selectedVOLUME))
        error('You must select a volume view for this to work');
    end
    
    view=VOLUME{selectedVOLUME};
    globalVolumeSet=1;
end

if (isempty(view))
    if (isempty(selectedVOLUME))
        error('You must select a volume view for this to work');
    end
    
    view=VOLUME{selectedVOLUME};
    globalVolumeSet=1;
end

if (~exist('hemisphere','var') )
    hemisphere='left';
end
if(isempty('hemisphere'))
    hemisphere='left';
end

if ((~isfield(view,'inplaneLeftIndices')) | (~isfield(view,'inplaneRightIndices')))
    view=getGrayCoords(view,1); % The '1' forces a rebuild of the gray nodes if the required field isn't present in the struct. 
end

if (strcmp(upper(hemisphere(1)),'L'))
    selectedIndices=view.inplaneLeftIndices;
    thisHemiName='Left hemisphere';
    nodeList=view.allLeftNodes;
    
else
    selectedIndices=view.inplaneRightIndices;
    thisHemiName='Right hemisphere';    
    nodeList=view.allRightNodes;
end

% nodeList:  a list of all the nodes that we plan to render
nodeList=nodeList(1:3,:)';
nNodes=length(nodeList);

% Compute a bounding box
minBound=min(nodeList);
maxBound=max(nodeList);
volSize=maxBound-minBound+1;
nodeList=nodeList-repmat(minBound,nNodes,1)+1;
volBox=zeros(volSize(1),volSize(2),volSize(3));
nodeInd=unique(sub2ind(volSize,nodeList(:,1),nodeList(:,2),nodeList(:,3)));

volBox(nodeInd)=1;
%[x y z volBox]=reducevolume(smooth3(volBox),[2 2 2]);

% *** HACK ALERT ***
%volBox=flipdim(volBox,1);
% Left and right hemispheres are flipped unless I do this. I don't know
% why. ARW


% volBox is now a volume containing the '1's where there are gray matter voxels.

% We'd like to accesss the ph data. This is held in a big long list
% with as many entries as there are gray nodes. So first we have to access the
% gray nodes.
% When the gray view is generated, a list of gray nodes intersecting the
% inplanes is generated. We need this list. Previously, it was just
% discarded. Now getGrayCoords has been modified to save it out.




nFuncNodes=length(selectedIndices);

[s,i,j]=unique(selectedIndices);
funcCoords=nodeList(s,:);
funcIndices=sub2ind(volSize,funcCoords(:,1),funcCoords(:,2),funcCoords(:,3));


% Now get the phase data for this scan. Restrict it to the current
% cothresh. 

% Generate another volume containing the colors of the voxels
colBox=volBox;

if (iscell(view.ph) & ~isempty(view.ph)) % See if the phase has been loaded...
    
    phaseList=view.ph{getCurScan(view)}(i); % The 'i' is there because the previous 'unique' statement re-orders the indices from lowest to highest.
    coList=view.co{getCurScan(view)}(i);
    
    if (strcmp(upper(hemisphere(1)),'L'))
        coList=coList(1:nFuncNodes);
        phaseCols=phaseList(1:nFuncNodes);
    else
        coList=coList((end-nFuncNodes+1):end);
        phaseCols=phaseList((end-nFuncNodes+1):end);
        
    end
    
    phaseCols=phaseCols/(2*pi)*100;
    phaseCols(coList<getCoThresh(view))=0;
    
    
    colBox(funcIndices)=phaseCols;
    % Make a nice colormap
    cm=hsv(100);
    cm(1,:)=[0.6 0.6 0.6];
  
else
    % Make a nice colormap
    cm=gray(100);
    cm(1,:)=[0.6 0.6 0.6];
    %colBox(funcIndices)=[0];
    %vtkIsoSurface(volBox==1,int32(size(volBox)),0.01,1);
    
    
end

    % Here's where we generate the isosurface
   FV = isosurface(smooth3(volBox),colBox) ;
 %FV = isosurface(volBox,colBox) ;
% Make sure figure is free
selectGraphWin;

% Render everything and set lighting etc.
hiso = patch(FV,...
    'EdgeColor','none','LineStyle','none','FaceColor','interp','FaceLighting','gouraud','CDataMapping','scaled');
%NVF=reducepatch(hiso,0.5,'fast');
%NVF

colormap(cm);
set(gcf,'BackingStore','on');
axis equal;
axis off;
% Set lights of both sides of the object.
lighting('gouraud');
l1=light;
set(l1,'position',[1 0 1]);
l2=light;
set(l2,'position',[1 0 -1]);

title(thisHemiName);
set(gca,'view',[90,90]);
axis off tight

% Call the routine view3d (by Torsten Vogel 09.04.1999 )
view3d rot;

disp('Press ''z'' and ''r'' over the figure to toggle rotate / zoom');

if (globalVolumeSet)
    VOLUME{selectedVOLUME}=view;
end
