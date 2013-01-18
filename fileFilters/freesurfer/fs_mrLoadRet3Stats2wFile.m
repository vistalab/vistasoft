function outFileList=fs_mrLoadRet3Stats2wFile(view,fs_meshPath,dataType,scanNum,hemisphere,mapName,wFileName,flipFlag,projAngle,phaseOffsetRad,phaseFlipFlag,scaleFactor)
% fs_mrLoadRet3Stats2wFile(view,fs_meshPath,dataType,scanNum,hemisphere,mapName,wFileName,flipFlag,projAngle,phaseOffsetRad,phaseFlipFlag))
% Purpose : MLR data re originally in the gray view.
% This routine writes out a wFile (a paint file) of the MLR data by mapping
% the values in the VOLUME gray matter to the specified Freesurfer mesh.
% Later you can use surf2surf (I think) to average these wFiles
%
% Here are the steps:
% 1: Read in the freesufer file and convert it to the same coordinate
% system as the gray nodes (volume 1-256 cubed, center 128)
% 2: Use nearpoints to generate a mapping from gray nodes to vertices. In
% other words we will map all gray points to the mesh (averaging along the
% way if necessary). The only time we will not do this is if we are asked
% to restrict the mapping to certain gray laters (e.g. L1)
% 3: Do the mapping. If more than one gray node maps to any vertex, we
% average the values.
% That's it. The format of a w file is very simple. We write one out
% directly.
% This routine is meant to replace the function mrLoadRet3StatsToAnalyze in
% that we will no longer write out analyze format files as part of our
% averaging procedure. The reason is that it is incredibly inefficient and
% introduces henious blurring.
%
% We read in both lh and rh separately - and we write out lh and rh
% specific w files as a result.
% flipFlag: Older freesurfer segmentations are flipped L/R. If this flag is
% set, we assume that the flip has happened. If it is not set (default) we
% assume we have a newer segmentation
% projectionAngle: For phase-projected data
% phaseOffsetRad: Add a certain phase offset to ph data (**before**
% computing projection)
% phaseFlipFlag: Sometimes you need to invert the phase map (for example
% because you are averaging phase maps from retino sessions with different
% display devices). The order of computation is offset, then flip (then
% project)


% This is how we get the vertices to gray map:
% vertexGrayMap = mrmMapVerticesToGray(...
%    initVertices, ...
%    viewGet(view,'nodes'), ...
%    viewGet(view,'mmPerVox'),...
%    viewGet(view,'edges'));

% Do checks:

if (ieNotDefined('view'))
    error('You must supply a view (e.g. VOLUME{1}');
end

if (ieNotDefined('fs_meshPath'))
    [fsMeshNamefs_meshPath,fsPath]=uigetfile('*.*','Pick a freesurfer mesh file');
    fs_meshPath=fullfile(fsPath,fsMeshName);
end

if (ieNotDefined('dataType'))
    % Default to current DT
    disp('Defaulting to current data type');
    dataType=viewGet(view,'currentdatatype');
end

if (ieNotDefined('scanNum'))
    disp('Defaulting to current scan number');
    scanNum=viewGet(view,'curscan');
end

if (ieNotDefined('hemisphere'))
    error('You must specify a hemisphere');
end

if (ieNotDefined('wFileName'))
    error('You must supply a wFileName');
end

if (ieNotDefined('flipFlag'))
    flipFlag=0;
end

if (ieNotDefined('phaseOffsetRad'))
    phaseOffsetRad=0;
end

if (ieNotDefined('projAngle'))
    projAngle=0;
end

if (ieNotDefined('scaleFactor'))
    scaleFactor=1;
end
% Look for mesh file. If it exists, load it..
% We need to construct a basic msh structure from the file data.

[path,name,ext,ver]=fileparts(fs_meshPath);

% See which format the freesurfer mesh is in
if (strcmp(upper(ext),'.TRI'))
    [vertex,face]=freesurfer_read_tri(fs_meshPath);
else

    [vertex,face]=freesurfer_read_surf(fs_meshPath);
end

% When these data are read in, they are in the following orientation:
% x : L->R
% y : P->A
% z : I->S

% The gray matter in the VOLUME structure (which is important for our
% purposes here) is in the following format
% x : A->P
% y : S->I
% z : L->R

% Therefore we must switch the orientation of the FS vertex data so that we
% can run nearpoints and compute the nearest vertices for each gray matter
% node.

% First the numbers have to come into registration.
vertex=vertex+128;

% 
% Vertices come back rotated in an odd way. The entire cortex is rotated 90
% degrees about the L/R axis (i.e. the sag view is rotated 90degrees
% anticlockwise).
vertex=vertex(:,[2 3 1]);
% Now we have
% x: P->A
% y: I->S 
% z: L->R

% Finally we flip the direction of the first and second dimensions
vertex(:,1)=256-vertex(:,1);
vertex(:,2)=256-vertex(:,2);

if (flipFlag)
    vertex(:,3)=256-vertex(:,3);
end
vertex(:,3)=vertex(:,3)+1;
nVerts=length(vertex);

grayNodes=view.nodes;

% Now map the data out from the gray matter to the mesh
% To make this easier, we will only map the layer1 data
l1Nodes=find(grayNodes(6,:)==1);
grayNodes=grayNodes(1:3,l1Nodes);

% Compute the indices into coords. We are about to extract map values which
% are indexed in the same way as coords (I think).
% grayNodes and coords have the x and y axes switched:
grayNodes2=grayNodes([2 1 3],:);
[a,b]=ismember(grayNodes2',view.coords','rows');

visualizeVertexAlignment(grayNodes,vertex',[130 135],fs_meshPath);
 
[l1v2gMap,dist]= nearpoints([vertex'],double(grayNodes));  % This is the map from vertices to gray matter.
% We want this because we need a
                                     % single value at each mesh location
badLocsG=find(dist>9); % Indices into l1v2gMap of bad nodes (set to zero)

       
                                     
coordLocs=b(l1v2gMap);


% Now use the mapping function to extract
% data from the map
switch(lower(mapName))
    case('co')

        wFileVals=view.co{scanNum}(coordLocs)*scaleFactor;
    case('amp')
        wFileVals=view.amp{scanNum}(coordLocs);
    case('ph')
        wFileVals=view.ph{scanNum}(coordLocs)+phaseOffsetRad;
    case('map')
        wFileVals=view.map{scanNum}(coordLocs);
    case('complexamp') % Combination of amp and ph
        wFileValsAmp=view.amp{scanNum}(coordLocs);
        wFileValsPh=view.ph{scanNum}(coordLocs);
        wFileVals=wFileValsAmp.*exp(sqrt(-1)*wFileValsPh+phaseOffsetRad);

    case('complete') % This writes out the complex amp, the projected amp and the projected 'co'. Right now we use a projection phase of 6 seconds..
        wFileCo=view.co{scanNum}(coordLocs)*scaleFactor;
        wFileValsAmp=view.amp{scanNum}(coordLocs);
        wFileValsPh=view.ph{scanNum}(coordLocs)+phaseOffsetRad;
        wFileVals=wFileValsAmp.*exp(sqrt(-1)*wFileValsPh);
        
        wFileProjCo=wFileCo.*cos(wFileValsPh-projAngle);
        wFileProjCo(badLocsG)=1e-5;;
        wFileVals(badLocsG)=1e-20*(rand(1)-0.5+sqrt(-1)*(rand(1)-0.5)); 
        disp('**Bad locations?**');
        disp(length(badLocsG));
        

end



% Write out the w-file
% Finally - write it out using freesurfer_write_wfile(wFileList{1});
wFileName=[wFileName,'_',hemisphere,'_scan',int2str(scanNum)];

switch(lower(mapName))

    case('complexamp')
        % Write out the im and re parts separately
        disp('Writing complex w-files');
        outFileList{1}=[wFileName,'_re.w'];
        outFileList{2}=[wFileName,'_im.w'];
        freesurfer_write_wfile(outFileList{1},real(wFileVals));
        freesurfer_write_wfile(outFileList{2},imag(wFileVals));


    case('complete')
        outFileList{1}=[wFileName,'_re.w'];
        
        outFileList{2}=[wFileName,'_im.w'];
        outFileList{3}=[wFileName,'_projCo.w'];
        outFileList{4}=[wFileName,'_Co.w'];
        disp(outFileList{1});
        freesurfer_write_wfileFast(outFileList{1},real(wFileVals));
        freesurfer_write_wfileFast(outFileList{2},imag(wFileVals));
        freesurfer_write_wfileFast(outFileList{3},wFileProjCo);
        freesurfer_write_wfileFast(outFileList{4},wFileCo);





    otherwise

        disp('Writing w-file');
        outFileList{1}=[wFileName,'.w'];
        freesurfer_write_wfile(outFileList{1},wFileVals);

end








