function dtiSubgroupToCinch(parentFiberGroup, outCstFileName, indFileName, MoriGroups)

%dtiSubgroupToCinch(parentFiberGroupFileName, outCstFileName, [indFileName])
%Export fg.subgroup data into a CINCH state fule. 
%parentFiberGroupis overloaded: provide a fiber group or a filename. 
%(Optionally)
%Blue Matter solution points to fibers from the parent Fiber Group that are to be
%retained under volume constraints. %pid2pdb outputs indices of these
%fibers (starting from 0) into indFileName

%If MoriGroups==1 This function presumes subgroup labels 1-20 are from Mori Groups.
%If MoriGroups==0 or empty, subgroups with value >=8 will be all collapsed together. 
%FIXME: hopefully, CINCH/QUENCH will be able to handle >8 groups. 

%ER wrote it  09/2009
if isstruct(parentFiberGroup)
   fg=parentFiberGroup; clear parentFiberGroup;
else
   fg=dtiLoadFiberGroup(parentFiberGroup); 
end

if exist('indFileName', 'var') && ~isempty(indFileName)
fid=fopen(indFileName);
ind=textscan(fid, '%d');ind=ind{1}; fclose(fid);
else
    ind=(1:length(fg.fibers))-1; 
end

fgInds=zeros(size(fg.fibers)); 
if isfield(fg, 'subgroup')&&~isempty(fg.subgroup)
    if exist('MoriGroups', 'var')&&~isempty(MoriGroups)&&(MoriGroups==1)
    fgInds(ind+1)=dtiMoriSubgroupToState(fg.subgroup(ind+1)); %TrueSA solution are indices of fibers to keep. PLUS1!!! (those indices count from 0)
    else
               fg.subgroup(fg.subgroup>=8)=8;
               fgInds(ind+1)=fg.subgroup(ind+1);
    end
else
    fgInds(ind+1)=1; 
end
dtiCinchSaveFibersState(fgInds, outCstFileName);
return


function fgInds=dtiMoriSubgroupToState(subgroup)
%Since Cinch can only handle 8 fiber groups (plus 1 unclassified), 20 Mori
%Groups indices need to be collapsed bilaterally.
fgInds = subgroup;
    fgInds(fgInds==1|fgInds==2) = 1; %Anterior thalamic radiation
    fgInds(fgInds==3|fgInds==4) = 2; %Corticospinal tract
    fgInds(fgInds==5|fgInds==6|fgInds==7|fgInds==8) = 3; %Cingulum
    fgInds(fgInds==9|fgInds==10) = 4; %Corpus Callosum
    fgInds(fgInds==11|fgInds==12|fgInds==13|fgInds==14) = 5; %IFO/ILF
    fgInds(fgInds==15|fgInds==16|fgInds==19|fgInds==20) = 6; %SLF
    fgInds(fgInds==17|fgInds==18) = 7; %Uncinate
    
