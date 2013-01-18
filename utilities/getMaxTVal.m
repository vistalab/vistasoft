function maxTMap=getMaxTVal(numberOfTMaps,tMapRoot,tMapStartIndex)
% function maxTMap=getMapTVal(numberOfTMaps,tMapRoot)
% Finds the MAX of a set of T maps.
% Don't know what to do to make a retinotopy map...the best way, maybe
  % is to find the MAX of T maps of contrasts for each different phase

    if (~exist('tMapRoot','var'))
      tMapRoot='spmT_000'; % Can't have more than 9 different phases for
                           % now
    end
    
    if (~exist('tMapStartIndex','var'))
      tMapStartIndex=1; % 
                        
    end
    if (numberOfTMaps>8)
      error('Cannot have more than 8 TMaps at the moment');
    end
    
    
    % Load in the first one just to get the size
    firstMapVol=spm_vol([tMapRoot,int2str(tMapStartIndex)]);
    firstMap=spm_read_vols(firstMapVol);
    [x y z]=size(firstMap);
    counter=1;
    fprintf('\nSize is %d x %d x%d',x,y,z);


    
    % First TMap should be spm_T0001
    for thisTmap=1:(numberOfTMaps)
      fileName=[tMapRoot,int2str(thisTmap+tMapStartIndex-1)];
      
        mapVol(counter)=spm_vol(fileName);
        mapData(:,:,:,counter)=spm_read_vols(mapVol(counter));
        disp(thisTmap);
        counter=counter+1;
    end
    
    % Now for each plane we want to find the max
    maxTMap=max(mapData,[],4);
    