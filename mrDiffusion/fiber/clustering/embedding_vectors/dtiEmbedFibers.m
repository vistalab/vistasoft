function Es=dtiEmbedFibers(fgNewFile, atlasFile)

%Given a file with a fibergroup fgNewFile and a file with "atlas" (embedding space -- see below
%which params are included in the atlas),
%returns coordinates of the fibers from the fibergroup in the embedding
%space. 

%Atlas file atlasFile is 
%It is assumed that the file with the original Fiber Group from which embedded space was computed is located in the same directory. 
%The naming convention : Original fiber group file name: fgfilename;
%Atlas file name: [fgfilename 'EV' method].


%Params included in the atlas file: 
%1. 'E'(nxm): weights of n fibers on m first vectors of the embedded space
%2. 'A': the "core" matrix of distance measures which guided the estimation of the embedded space.
% And parameters pertained to this distance matrix: 'npoints',  'kernelsigma', 'method'
%3. 'embbasis' dimensionality AxA, used to project new fibers onto it.

%ER 04/10/2008

    %STRIP OFF EXTENSIONS and path IF THERE ARE ANY 

[pathstr, atlasFile] = fileparts(atlasFile); 
atlasFile=fullfile(pathstr, atlasFile); 

[pathstr, fgNewFile] = fileparts(fgNewFile); 
fgNewFile=fullfile(pathstr, fgNewFile); 
%%%%%%%%%%%%%%%%%%%%%%


%1. identify original fg file name.
[m s] = regexp(atlasFile, 'EV', 'match', 'start');
fgFileRef=atlasFile(1:s-1);

%2. Load atlas space/parameters
load(atlasFile);
nvec=size(E, 2); %(dimensionality of the embedded space)
NfibersInA=size(A, 1);

%3. Compute similarities between
%original core fiberset (which A is based on) and the new embedding fiberset
load(fgFileRef); 
Asubset.fibers=fg.fibers(1:NfibersInA);
load(fgNewFile);
fg.fibers=[Asubset.fibers; fg.fibers]; clear Asubset; 
[pathstr, fgFileRefName] = fileparts(fgFileRef);
ASfileName=[fgNewFile '+' fgFileRefName ];
save(ASfileName, 'fg', 'coordinateSpace', 'versionNum');

NoFibersTotal=size(fg.fibers, 1);  clear fg; 
%Compute distances for A with S. 
range1start=1; range2start=1+NfibersInA; range1end=NfibersInA; range2end=NoFibersTotal;
outfile=[ASfileName 'dist' num2str(range1start) 'to' num2str(range1end) 'vs' num2str(range2start) 'to' num2str(range2end) method];
%compute_interfiber_distances(ASfileName, npoints, method, range1start, range1end, range2start,  range2end, 1);

%4. Transform computed distance matrices into similarities and pass into
%embedding procedure. 

%%%%% ITERATIVELY EMBED PORTIONS OF NEW FIBERS ONTO OLD BASIS 

NSamples=min((NoFibersTotal-NfibersInA), NfibersInA*1);
maxlast= 0; 
Es=[];


while maxlast<(NoFibersTotal-NfibersInA)
display(['Embedding fibers ' num2str(maxlast+1) ' to ' num2str(min(maxlast+NSamples, NoFibersTotal-NfibersInA))]);  

load(outfile); 
affinities=dtiComputeAffinitiesFromDistances(distmsr, kernelsigma);	clear distmsr; 
clear fibergroup1 fibergroup2
S=affinities(1:NfibersInA, (maxlast+1):min(maxlast+NSamples, NoFibersTotal-NfibersInA));
clear affinities;

Es=[Es; dtiNewDataOntoEmbeddingVectors(A, S, embbasis, nvec)];
size(Es)
maxlast=maxlast+NSamples;
end