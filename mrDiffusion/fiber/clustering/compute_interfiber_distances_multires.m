function distance = compute_interfiber_distances_multires(fgFile, maxDistanceOfInterest,  range1start, range1end, range2start,  range2end)
%Multiresolution approach: first approximation with mass_center distances,
%for the closest fibers pointwise average distance is computed.

%First we compute center-of-mass interfiber distances for fg.fibers structures in infile.mat 
%Then we threshold these distances to retain only those that are smaller
%than 20mm. For those interfiber parwise_dist distances are computed. 
%save distance matrix into outfile. Range1 ([Nfrst Nlasst]) and range2 specify groups of fibers among which the distances should be computed. 

%ER 12/2007 Range1/2start/end: supply as a string
%(e.g., '5') -- needed for later to pass bash string arguments, when
%working on the cluster. 

%02/2008 Revision: 
%1. Omit last 4 parameters if want to have the wholefile processed. 
%2. Resampling is no longer performed -- use
%ResampledFiberGroup=resampleFiberGroup(fg, numNodes) and save the
%resampled dataset as save('ResampledDataFile', 'fg', 'versionNum',
%'coordinateSpace')
%3. Added parameter maxDistanceOfInterest: fibers whos mass-center distance
%in mm exceeds this parameters will be considered "infinitely remote" (for the
%purpose off sparse matrix production). A typical value is 40 (in mm) for the first step, 500 for the last step. 

epsilon=.000000001; 

%Strip off the .mat extension if provided
if fgFile(length(fgFile)-3:length(fgFile))=='.mat'
    fgFile=fgFile(1:length(fgFile)-4); 
end
load(fgFile); 

method='multiresolution';

%Checking number of arguments: if 1, full range in file is used; if 5, arbitrary ranges for first and second fiber groups are allowed.  
if nargin==6
range1start=min(max(str2num(range1start), 1), size(fg.fibers, 1));
range2start=min(max(str2num(range2start), 1), size(fg.fibers, 1)) ;

range1end=max(min(str2num(range1end), size(fg.fibers, 1)), range1start);
range2end=max(min(str2num(range2end), size(fg.fibers, 1)), range2start) ;
samegroupflag=0;
    
else
    if nargin==2
    samegroupflag=1;
    range1start=1; range2start =1; %By default process full range. 
    range1end=size(fg.fibers, 1);
    range2end=size(fg.fibers, 1);
    else
        display('Wrong number of argument supplied'); 
    end
end


display(['Data: ' fgFile ]); 

display(['Distance metric: ' method ]); 
display(['Fibergroups analyzed: ' num2str(range1start) ' to ' num2str(range1end) ' and ' num2str(range2start) ' to ' num2str(range2end)]);


fibergroup1=fg.fibers(range1start:range1end);
fibergroup2=fg.fibers(range2start:range2end);    
clear fg; 

if (range1start==range2start&range1end==range2end)
    display('One fiber group found');

    samegroupflag=1;
    tic; distanceSquared = InterfiberMassCenterDistances(fibergroup1);  toc; 
 
else
    display('Two distinct fiber groups found');
    tic; distanceSquared =  InterfiberMassCenterDistances(fibergroup1, fibergroup2);  toc; 


end
display('Mass center distances computed');

%Thresholding distmsr and transform it into the sparse matrix: 
distanceSquared(distanceSquared(:)==0)=epsilon; %This is to keep actual zeros in the matrix, as the matrix entries corresponding to "larger-than-threshold" distances will be turned to zeros in the sparse matrix;
distanceSquared(distanceSquared>maxDistanceOfInterest^2)=0;  %Note that maxDistanceOfInterest has to be squared because distanceSquared returned by InterfiberMassCenterDistances is squared!
distanceSquared=sparse(double(distanceSquared)); 



%Form curve arrays from fg structure
nfibers1=size(fibergroup1, 1); 
nfibers2=size(fibergroup2, 1); 
npoints=  size(fibergroup1{1}, 2); 

curves1=zeros(3, npoints, nfibers1); 
%<s>Resample fibers in Fiberr Group 1 using splines</s>
%02/2008: Resampling no longer performed. Will complain if you have not
%resampled data apriori. 

for i=1:nfibers1
%   curves1(:, :, i)=dtiFiberResample(fibergroup1{i}, npoints);
   curves1(:, :, i)=fibergroup1{i};
end
if (samegroupflag==1)
    curves2=curves1; 
else
     curves2=zeros(3, npoints, nfibers1); 
    %<s>Resample fibers in Fiberr Group 2 using splines</s>
    %02/2008: Resampling no longer performed.
    
    for i=1:nfibers2
       %curves2(:, :, i)=dtiFiberResample(fibergroup2{i}, npoints);
       curves2(:, :, i)=fibergroup2{i};
    end

end
%display('Fibers resampled');

if(samegroupflag==1)
    distanceSquared=tril(distanceSquared); %If the matrix is symmetric, avoid extra computations
end

%Distances for the following pairs of fibers will be fine-tuned: 
[i1 j1]=find(distanceSquared~=0);
finetunedElementIndices=find(distanceSquared~=0);
    

%Computing interfiber distances (pointwise)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
distance=sparse(zeros(size(distanceSquared)));

tic; 
for pair=1:size(i1)
    
distance(i1(pair), j1(pair))=intercurve_dist_pointwise(curves1(:, :, i1(pair)), curves2(:, :, j1(pair)), samegroupflag);
%The new, more "precise" values replace those not precise. 
end
toc; %Wow, for 20% of fibers pairs still takes 5 times longer.
display(['Precise distances for pairs of fibers whose mass-center distance did not exceed ' num2str(maxDistanceOfInterest) 'mm computed']);

if(samegroupflag==1)
    distance=distance+distance'-triu(distance); %Since the matrix for "samegroup" case was symmetric, we need to repopulate the upper triangle.
end

% Remember: we have a sparse matrix representation where zeros mean
% "infinite distance" actually (and are not stored). So actual true zero distances should be  made a
% very small number. 
distance(nonzeros(finetunedElementIndices.*(distance(finetunedElementIndices)==0)))=epsilon;


outfile=[fgFile 'distances_multires' num2str(range1start) 'to' num2str(range1end) 'vs' num2str(range2start) 'to' num2str(range2end) '.mat'];
[pathstr, name, ext, versn] = fileparts(outfile) ;
if isempty(pathstr)
    pathstr=['.' filesep ];
end

mkdir(pathstr, 'multiresDistances');
outfilefull=fullfile(pathstr, 'multiresDistances', name);
save(outfilefull, 'distance', 'fibergroup1', 'fibergroup2', 'fgFile', 'range1start', 'range2start', 'range1end', 'range2end', 'method'); 

