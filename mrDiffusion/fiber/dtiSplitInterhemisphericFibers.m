function [fg, fgRemains, fgLeft, fgRight]=dtiSplitInterhemisphericFibers(fg, dt, maxZ)
%Split fibers that cross between hemispheres below a certain z-coordinate.
%
%   fg=dtiSplitInterhemisphericFibers(fg, dt, [Z=-10])
%
% Due to tractography artifacts, whole brain tractography often produces
% fibers which connect homologous motor cortices, crossing between
% hemispheres at the pons level. This is anatomically implausible: these
% fibers mostl likely cross at the pons level, connecting spinal tract and
% contralateral moter cortex. This function splits interhemisperic fibers,
% sparing (dep. on option chosen) either CC, or ACPC & above. Note:
% cerebellar fibers WILL be split as well. Too bad.
%
% Input parameters: 
% fg      - fiber group structure
% dt      - dt6 (tensor) data structure
% maxZ    - (a) maxZ=-10 (default) will split fibers, cutting them by a
%           saggital plane 10 mm below acpc line.  We assume that no
%           interhemispheric fiber should connect below ACPC line. Fornix &
%           CC are comissures located above. Provide your own maxZ (the
%           most superior z coordinate of the cutting midsaggital plane)
%           otherwise. (b) maxZ='AllButCC' allows splitting every
%           interhemispheric fiber except callosal.
%
% Example: 
% Split intehemispheric fibers below ACPC
%   dt=dtiLoadDt6(dtFileName);
%   fg = dtiLoadFibers(fgFileName);
%   fg=dtiSplitInterhemisphericFibers(fg, dt, 0]);
%
% (c) Vistalab

%HISTORY:
% 08/2009: ER & LMP   wrote it
% 08/24/2009 ER: drop fibers of 1 node long. 

if notDefined('maxZ')
    maxZ=-10;
end

if isnumeric(maxZ) && (maxZ<dt.bb(1, 3) ||maxZ>dt.bb(2, 3))|| (~isnumeric(maxZ) && ~strcmp(maxZ, 'AllButCC'))
    error(['The most superior point Z for cutting should be between ' num2str(dt.bb(1, 3)) ' and ' num2str(dt.bb(2, 3)) ' or "AllButCC"']);
end

if notDefined('dt')
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select dt6 file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    dt = fullfile(p,f);
end

midSagThresh = 5;
fg=dtiCleanFibers(fg);
fgname=fg.name;

if isnumeric(maxZ)
    
   fprintf(1, 'dtiSplitInterhemisphericFibers: Splitting every fiber below Z=%s \n', num2str(maxZ)); 
   % Bounding Box = dt.bb  x = [-80 0]; y = [-120 90]; z = [-60 90];
    x = [0];
    y = [dt.bb(1, 2):dt.bb(2, 2)];
    z = [dt.bb(1, 3): maxZ];
    
    [X,Y,Z] = meshgrid(x, y, z);
    roiCoords = [X(:), Y(:), Z(:)];
    roi = dtiNewRoi('MidSaggitalBelowACPC', 'b', roiCoords);
    
    [fgToChop,contentiousFibers, keep] = dtiIntersectFibersWithRoi([], {'and'}, [], roi, fg);
    fgRemains = dtiNewFiberGroup([fg.name 'Remains']); fgRemains.fibers=fg.fibers(~keep);
    if isfield(fg, 'subgroup') && ~isempty(fg.subgroup)
        fgRemains.subgroup=fg.subgroup(~keep);
    end
    
    fgRight = dtiNewFiberGroup([fg.name '_ChoppedR']);
    fgLeft = dtiNewFiberGroup([fg.name '_ChoppedL']);
        clear fg;
    
%emptyleft=0; 
%emptyright=0; 
    
    keepRightID=[];keepLeftID=[];
    for i=1:size(fgToChop.fibers)
        pointsRight=(fgToChop.fibers{i}(1, :)>midSagThresh);
        pointsLeft=(fgToChop.fibers{i}(1, :)<-midSagThresh);
        RightChunk{1}=fgToChop.fibers{i}(:, pointsRight);
        if ~isempty(RightChunk{1})
            fgRight.fibers= [fgRight.fibers(:);RightChunk] ; %Right chunk
            keepRightID=[keepRightID; i];
 %       else emptyright=emptyright+1; 
        end
        LeftChunk{1}=fgToChop.fibers{i}(:,  pointsLeft);
        
        if ~isempty(LeftChunk{1})
            fgLeft.fibers = [fgLeft.fibers(:); LeftChunk]; %Left chunk
            keepLeftID=[keepLeftID; i];
 %       else emptyleft=emptyleft+1; 
        end
    end
      if isfield(fgToChop, 'subgroupNames') && ~isempty(fgToChop.subgroupNames)
    fgLeft.subgroupNames=fgToChop.subgroupNames;
    fgRight.subgroupNames=fgToChop.subgroupNames;
      end
    if isfield(fgToChop, 'subgroup') && ~isempty(fgToChop.subgroup)
    fgLeft.subgroup=fgToChop.subgroup(keepLeftID);
    fgRight.subgroup=fgToChop.subgroup(keepRightID);
    end
    
%    emptyleft
%    emptyright
else
    
    % Code that LMP wrote to take a fiber group, remove callosal fibers, split
    % the remaining groups, then merge the two groups to create one set that
    % is cut down the mid-line but retains the callosal fibers.
    %Limitation: assumes CC is the only interhemispheric connection
    fprintf(1, 'Splitting every fiber except in the CC \n');
    
    ccCoords = dtiFindCallosum(dt.dt6,dt.b0,dt.xformToAcpc);
    ccRoi = dtiNewRoi('CC','c',ccCoords);
    ccRoi = dtiRoiClean(ccRoi, 3, {'dilate'});
    
    fgRemains = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
    fgToChop= dtiIntersectFibersWithRoi([], {'not'}, [], ccRoi, fg);
    clear fg;
    fgRight = dtiClipFiberGroup(fgToChop, [-80 midSagThresh],[],[]);
    fgLeft = dtiClipFiberGroup(fgToChop, [-midSagThresh 80],[],[]);
    
end


fg = dtiMergeFiberGroups(fgRight,fgLeft,fgname);
fg = dtiMergeFiberGroups(fg,fgRemains,fgname);
fgRemains.name  = [fgname '_NoChop'];
fgLeft.name  = [fgname '_L'];
fgRight.name  = [fgname '_R'];
fg.name=[fgname '_BilaterallySplit'];

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%dtiWriteFibersPdb(newFg,[],newFg.name);

%fgToChop.name=['allConnectingGM_withCST_Mori_ToChop'];
%dtiWriteFiberGroup(fgRemains,fgRemains.name);
%dtiWriteFiberGroup(newFgLeft,newFgLeft.name);
%dtiWriteFiberGroup(newFgRight,newFgRight.name);
%dtiWriteFiberGroup(fgToChop,fgToChop.name);
