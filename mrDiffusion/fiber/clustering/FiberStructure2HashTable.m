function hashvalues=FiberStructure2HashTable(fibergroup)

%In goes Nx1 cell structure with fibers, each fiber is an 3xFibLength array. 
%Output is an Nx1 cell structure with stings that are hash values of these fibers (strings of xcoords|ycoords|zcoords).
%To be used for identifying unique fibers. 
%Coordinates are rounded to the closes integer

%ER 2007 SCSNL

for cellId=1:size(fibergroup, 1)
    %% Resample to 10
    fibergroup{cellId}=dtiFiberResample(fibergroup{cellId}, 10); 
    %%
    t3=num2str(round(fibergroup{cellId}./10));
    hashvalues(cellId)=cellstr([t3(1, :) t3(2, :) t3(3, :)]); %That's a string; so we get an array of strings, and the coordinates are now in cantimiters. 
cellId
end %cellId

%then use un=unique(hashvalues)