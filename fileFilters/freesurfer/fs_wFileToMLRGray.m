function [view,dt]=fs_wFileToMLRGray(view,wFileName,surfFileName,scaleFactor,hemisphere,fieldToMap,dataType,scanNum)
% [view,dt]=fs_wFileToMLRGray(view,wFileName,surfFileName,scaleFactor,hemisphere,fieldToMap,dataType,scanNumber)
% Takes Freesurfer data from a .w file and maps it into the gray nodes of a
% mrLoadRet Gray view using nearpoints.
% If hemisphere is specified (1=left, 2=right, 3=both), we will try to map appropriately. 
% In this way you can call the function twice: Once for left and once for
% right and generate a complete functional map. Defaults to 'both' (3).
% fieldToMap can be 'co','amp','ph','map' (defaults to 'map');
% 
% dataType is an index. Defaults to current dataType
% scanNumber is an index. Defaults to current scan.
%
% Useful for many things. But particularly for mapping data back from an
% Freesurfer averaged subject to MLR so that you can see the data relative
% to ROIs, project it to the Flat view etc.
%
% ARW 091605 : Wrote it.
% REQUIRES: Darren Weber's EEGToolbox
% e.g.
% [VOLUME{1}=fs_wFileToMLRGray(VOLUME{1},...
% '/raid/data/test/mlr/wFiles/leftAmp.w',...
% '/raid/anatomy/sub1/meshes/lh.surf',...
% 0,1,'map');
mrGlobals;

MAX_DIST_SQ=16;

% Do checks
if (ieNotDefined('view'))
    error('You must supply a view (i.e. VOLUME{1})');
end

% Check the view type
if (~strcmp(view.viewType,'Gray'))
    error('You must be working with a Gray view');
end

% Check to see if the anatomy is loaded in the MLR view. If not, load it...
if (isempty(view.anat))
    disp('Loading anatomy');
    view=loadAnat(view);
end

if (ieNotDefined('wFileName'))
    error('You must supply a Freesurfer-format .w file name');
end

if(ieNotDefined('surfFileName'))
    error('You must supply a Freesurfer-format surface file name like lh.smoothwm');
end

if (ieNotDefined('scaleFactor'))
    disp('Defaulting to unity scale factor');
    scaleFactor=1;
end

if (ieNotDefined('hemisphere'))
    disp('Defaulting to whole cortex for gray matter nodes (left + right hemispheres will be overwritten');
    hemisphere=3;    
end

if (ieNotDefined('fieldToMap'))
    disp('Mapping data to the ''map'' field');
    fieldToMap='map';
end

if (ieNotDefined('dataType'))
    disp('Defaulting to current dataType');
    dataType=view.curDataType;
    
end

if (ieNotDefined('scanNum'))
    disp('Defaulting to current scan');
    scanNum=view.curScan;
end


% Load in 2 FREESURFER - specific things
% 1: Load in the wFile 
disp('Loading wFile');
[data,meshVertexIndex] = freesurfer_read_wfile(wFileName); % 
data=data*scaleFactor;


% 2: Load in the mesh file (to tell us where the vertices are in 3D space).
disp('Loading surface file');
[vertexLocs, faces] = freesurfer_read_surf(surfFileName);
  [vertexLocs,T] = freesurfer_surf2voxels(vertexLocs);
 % vertexLocs(:,3)=256-(vertexLocs(:,3));

  
  vertexLocs=vertexLocs';
  
% 
% % vertexLocs comes out as a Nx3 array
% vertexLocs=128-round(vertexLocs');
% 
 vertexLocs=vertexLocs([2 3 1],:);
 disp(size(vertexLocs));
 disp(size(data));
 vertexLocs(2,:)=257-vertexLocs(2,:);
 vertexLocs(3,:)=257-vertexLocs(3,:);
vertexLocs=round(vertexLocs);
 
% 

% The crucial fields in the Gray view are 'coords' (a list of 3d coords)
% and inplaneLeftIndices / inplaneRightIndices. I >think< you can use those
% to map separately to the left and right.
 
grayCoords=round(view.coords);
visualizeVertexAlignment(grayCoords,vertexLocs,[100 105]);
 

% If the coords are in the correct order, and if they are in the same range
% as the surface vertices then we should be able to do nearpoints right now
% and get a mapping between the list of surface vertices and the gray
% points. Then we just assign the wFile values at each point to the correct
% gray matter node. 
% l=(sub2ind([256 256 256],vertexLocs(1,:),vertexLocs(2,:),vertexLocs(3,:)));
% lgc=(sub2ind([256 256 256],grayCoords(1,:),grayCoords(2,:),grayCoords(3,:)));
% j=view.anat;
% j(l)=350; 
% %j(lgc)=250;
% sl=squeeze(j(120,:,:));
% sl2=squeeze(j(120,:,:));

% figure(99);
% 
% imagesc(sl2);
% cm=[gray(256);hsv(256)];
% colormap (cm);
% 
% colorbar;

[gray_to_fsIndices, bestSqDist] = nearpoints(double(grayCoords),double(vertexLocs)); % gray_to_fsIndices: For each gray node, this tells you the freesurfer node that its closest to.
% We could do this the other way as well: For each freesurfer node, find the gray node that its closest to. This would be a 
% many to one mapping. So ultimately (after weighting for
% distance) we could compute an average at each grey node position.
% The more I think about this, the more I want to do it.

[fsIndices_to_grayNodes,bestSqDist2]=nearpoints(double(vertexLocs),double(grayCoords));

% exclude things that were too far from a gray matter node
closeEnough_grayToFS=(bestSqDist<MAX_DIST_SQ);
closeEnough_FSToGray=(bestSqDist2<MAX_DIST_SQ);



caIndex_grayToFS=find(closeEnough_grayToFS); % This is a list of indices into gray_to_fsIndices. Each gray node gets at most 1 freesurfer node).
caIndex_FSToGray=find(closeEnough_FSToGray); % This is a list of indices into fsIndices_to_grayNodes. Each Freesurfer node gets (at most) 1 gray node. Each gray node can be linked to by many FS nodes.

% Think we're going to assign the gray nodes based on an unweighted
% average of the fsNode values later... For now we will assign a value to each
% gray node based on its nearest FS node....

% We assign the values in the appropriate map... This is not trivial: Depending on how the maps already look, we might be adding to 
% an existing map, overwriting an existing map or creating a new map / scan. 
% We have to check things like scan numbers, data types etc etc...

% FIRST: Switch to the requested dataType
% If it doesn't exist, make it and then switch to it.

if (existDataType(dataType))
    view=selectDataType(view,dataType);
else
    dataTypeNum=addDataType(dataType);
    dataType=dataTypeNum;
    view=selectDataType(view,dataType);
end

% NEXT:  check the scanNum
% If the scan does not exist, make a fake entry with zeros and ones in the
% relevent fields.

% Take a look at the map and co fields. I think these must be the same size
% (can you load in a map without setting the co?). 
sizeCo=length(view.co); % This will be [0 0] if nothing is loaded.
sizeMap=length(view.map); % ditto
nCoords=length(view.coords);
% view.co (like view.map, view.amp etc..) is a cell array with one cell per scan. Each cell is 1xnCoords where
% nCoords is the length of view.coords

% If we are making a new 'map' field, we must also fake co, amp and ph. If
% we're making a 'co' field we fake ph and amp. A new 'ph' field? Fake 'co'
% and 'amp'. A new amp field? Fake 'ph' and 'co'.
% We also have to fix (fake) dataTYPES.blockedAnalysisParams, scanParams
% and event analysisParams
fakeDataTypeFlag=0;
switch fieldToMap % This is a little long-winded right now. It might become more compact later.
    case 'co'
        if (sizeCo<scanNum)
            view.co{scanNum}=zeros(1,nCoords);
            view.ph{scanNum}=zeros(1,nCoords);
            view.amp{scanNum}=zeros(1,nCoords);           
            fakeDataTypeFlag=1;
        else
            % Do nothing for now
        end    
        
        thisMap=view.co{scanNum};
        thisMap(closeEnough_grayToFS)=data(gray_to_fsIndices(closeEnough_grayToFS));
        
        view.co{scanNum}=thisMap;
        
    case 'amp'
        if (sizeCo<scanNum)
            view.co{scanNum}=ones(1,nCoords); % Note this is now ones not zeros
            view.ph{scanNum}=zeros(1,nCoords);
            view.amp{scanNum}=zeros(1,nCoords);   
            fakeDataTypeFlag=1;     
        else
            % Do nothing for now
        end
        
        thisMap=view.amp{scanNum};
        thisMap(closeEnough_grayToFS)=data(gray_to_fsIndices(closeEnough_grayToFS));
        view.amp{scanNum}=thisMap;
        
    case 'ph'
        if (sizeCo<scanNum)
            view.co{scanNum}=ones(1,nCoords);
            view.ph{scanNum}=zeros(1,nCoords);
            view.amp{scanNum}=zeros(1,nCoords);                    
            fakeDataTypeFlag=1;
            
        else
            % Do nothing for now
        end
        thisMap=view.ph{scanNum};
        thisMap(closeEnough_grayToFS)=data(gray_to_fsIndices(closeEnough_grayToFS));
        view.ph{scanNum}=thisMap;
        
    case 'map'
        if (sizeMap<scanNum) % Check the size of the map field
             if (sizeCo<scanNum)
                view.co{scanNum}=ones(1,nCoords);
                view.ph{scanNum}=zeros(1,nCoords);
                view.amp{scanNum}=zeros(1,nCoords);
                fakeDataTypeFlag=1;
            end
            
            view.map{scanNum}=zeros(1,nCoords);
            
        else
            % Do nothing for now
        end
        
        thisMap=view.map{scanNum};
        thisMap(find(closeEnough_grayToFS))=data(gray_to_fsIndices(find(closeEnough_grayToFS)));
        view.map{scanNum}=thisMap;

        
     case 'projco'
        if (sizeMap<scanNum) % Check the size of the map field
             if (sizeCo<scanNum)
                view.co{scanNum}=ones(1,nCoords);
                view.ph{scanNum}=zeros(1,nCoords);
                view.amp{scanNum}=zeros(1,nCoords);
                fakeDataTypeFlag=1;
            end
            
            view.map{scanNum}=zeros(1,nCoords);
            
        else
            % Do nothing for now
        end
        
        thisMap=view.map{scanNum};
        thisMap(find(closeEnough_grayToFS))=data(gray_to_fsIndices(find(closeEnough_grayToFS)));
        view.map{scanNum}=thisMap;
        view.co{scanNum}=abs(thisMap); % This lets you restrict by the co field
        view.ph{scanNum}=pi/2.*sign(thisMap)+pi/2;
        view.amp{scanNum}=abs(thisMap); % This lets you restrict by the co field
               
        
        
end

if (fakeDataTypeFlag)
    disp('Faking data type');
    
    % Fake this entry in the dataTYPES array
    dataTYPES(view.curDataType).scanParams(scanNum).annotation='From w file';
    dataTYPES(view.curDataType).scanParams(scanNum).nFrames=1;
    dataTYPES(view.curDataType).scanParams(scanNum).framePeriod=1;
    dataTYPES(view.curDataType).scanParams(scanNum).slices=1;
    dataTYPES(view.curDataType).scanParams(scanNum).cropSize=NaN;
    dataTYPES(view.curDataType).scanParams(scanNum).cropSize=NaN;
    dataTYPES(view.curDataType).blockedAnalysisParams(scanNum).blockedAnalysis=0;
    dataTYPES(view.curDataType).blockedAnalysisParams(scanNum).nCycles=1;
    dataTYPES(view.curDataType).eventAnalysisParams(scanNum).eventAnalysis=0;
    
    % Maybe we don't need more than this
    
end

% Now save either the corAnal or the map (or both)? And saveSession

saveSession;

saveCorAnal(view,[],1);

dt=dataTYPES;







