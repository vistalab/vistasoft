function distanceSquared =  InterfiberMassCenterDistances(fibergroup1, varargin)
%Usage examples
%function distanceSquared =  InterfiberMassCenterDistances(fibergroup1, fibergroup2)
%function distanceSquared =  InterfiberMassCenterDistances(fibergroup1)

%Compute interfiber distances among fibers in 2 sets of fibers (or with
%itself, if only one set of fibers is supplied). Full matrix is outputted. 

nfibers1=size(fibergroup1, 1);
firstmoments2=[]; %Later will check if this got updated that means we have 2 distinct fiber groups supplied, otherwise we can just populate curves2 from curves1

if (nargin > 1) 
     fibergroup2=varargin{1};
     nfibers2=size(fibergroup2, 1); 
     samegroupflag=0;
          
    %0. Find first moment in Fiber Group 2 
    firstmoments2=zeros(nfibers2, 3); 
    for i=1:nfibers2
            firstmoments2(i, :)=mean(fibergroup2{i}');
    end
         display('First moments for fiber grp 2 computed');

else %Second fiber grp is not supplied
     samegroupflag=1;
end


firstmoments1=zeros(nfibers1, 3); 
%1. Resample fibers in Fiberr Group 1 using splines
for i=1:nfibers1
   firstmoments1(i, :)=mean(fibergroup1{i}');
end
display('First moments for fiber grp 1 computed');


%save('splines.mat')
if isempty(firstmoments2) %Apparently curves2 did not get populated from the params supplied with command string
    firstmoments2=firstmoments1; 
end



%2. Compute distance
distanceSquared=single(zeros(size(firstmoments1, 1), size(firstmoments2, 1)));


%CASE WHERE THE GROUPS OF FIBERS ARE NOT EQUIVALENT
if (samegroupflag==0)

    for i=1:size(firstmoments1, 1)
       for j=1:size(firstmoments2, 1)
    distanceSquared(i, j)=sum((firstmoments1(i, :)-firstmoments2(j, :)).^2);
    %squares are ommited from distance computation to save computing time

    end

    end
else
%A SHORTCUT-CASE, where the two fibergroups supplied are the same. 

    for i=1:size(firstmoments1, 1)
       for j=i:size(firstmoments2, 1)
    distanceSquared(i, j)=sum((firstmoments1(i, :)-firstmoments2(j, :)).^2);
    %squares are ommited from distance computation to save computing time

    end

    end
distanceSquared=distanceSquared+distanceSquared'; %this is because we only computed upper portion of this symmetric similarity matrix, but we need to output full matrix. 
end
%This takes x10 times less than the pairwise_dist procedure yet the results produce pretty much the same (up to the scaling) similarity matrix!
