function distmsr=intercurve_dist_pointwise(curves1, curves2, samegroupflag)

%A helper function that calculates average distance in same length-matched
%pairwise pairs of curves. 
%curves are 3xNxncurves, samegroupflag=1 means the sets of curves are same, which
%allows a shortcut with computing only 1/2 of the distance matrix.
%This function is used by InterFiberDistances and
%compute_interfiber_distances_multires 
%Elena Rykhlevskaia Jan 2008 SCSNL

if ~isequal(size(curves1,2), size(curves2,2))
    display('Curves must be resampled to the same number of nodes');
return
end

distmsr=zeros(size(curves1, 3), size(curves2, 3));

%CASE WHERE THE GROUPS OF FIBERS ARE NOT EQUIVALENT
if (samegroupflag==0)
    
stepsize=50; 
fprintf(1, ['Computing distances for fibers (out of ' num2str(size(curves1, 3)) '): ']);
for group_of_fibers=1:stepsize:size(curves1, 3)
    
    fprintf(1, [num2str(group_of_fibers) ' to ' num2str(min(group_of_fibers+stepsize-1, size(curves1, 3))) ' ... ']);
  
  
    for i=group_of_fibers:min(group_of_fibers+stepsize-1, size(curves1, 3))
        for j=1:size(curves2, 3) 

            curve1=curves1(:, :, i); 
            curve2=curves2(:, :, j);
            curve2flipped=fliplr(curve2); 

            distmsr(i, j)=min(mean(sqrt((curve1(1, :)-curve2(1, :)).^2+(curve1(2, :)-curve2(2, :)).^2+(curve1(3, :)-curve2(3, :)).^2)), mean(sqrt((curve1(1, :)-curve2flipped(1, :)).^2+(curve1(2, :)-curve2flipped(2, :)).^2+(curve1(3, :)-curve2flipped(3, :)).^2))); 
        end

    end
end
fprintf(1, '\n');

else


%A SHORTCUT-CASE, where the two fibergroups supplied are the same. 
    for i=1:size(curves1, 3)
       for j=i:size(curves2, 3) %creates a low triangular matrix

        curve1=curves1(:, :, i); 
        curve2=curves2(:, :, j);
        curve2flipped=fliplr(curve2); 

        distmsr(i, j)=min(mean(sqrt((curve1(1, :)-curve2(1, :)).^2+(curve1(2, :)-curve2(2, :)).^2+(curve1(3, :)-curve2(3, :)).^2)), mean(sqrt((curve1(1, :)-curve2flipped(1, :)).^2+(curve1(2, :)-curve2flipped(2, :)).^2+(curve1(3, :)-curve2flipped(3, :)).^2)));
       end
display(['i=' num2str(i)]);
    end

distmsr=distmsr+distmsr'- diag(diag(distmsr)); %To make a full matrix    
end

