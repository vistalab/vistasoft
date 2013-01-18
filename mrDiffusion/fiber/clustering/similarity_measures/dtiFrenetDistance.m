function distmsr=dtiFrenetDistance(curves1, curves2, samegroupflag)

%Computes distance between curves using frenet framework: curve matching
%method from Bakircioglu et al., HBM 6:329-333 (1998)

%Usage:
%dtiFrenetDistances(fibergroup1, fibergroup2, npoints)
%dtiFrenetDistances(fibergroup, npoints)

%ER 2008 04/2008 SCSNL

%1. Checks
if ~((samegroupflag==0)||(samegroupflag==1))
display('Same group flag should be 1 or zero');
    return;
end

if ~isequal(size(curves1,2), size(curves2,2))
    display('Curves must be resampled to the same number of nodes');
return
end


if (samegroupflag==1)&&~isequal(size(curves1,3), size(curves2,3))
    display('Are you sure your curves1 and curves2 are equivalent? curves2 will be ignored');
end

nfibers1=size(curves1, 3); 



%actually if same group flag == 1 then curves2 is ignored

%2. Compute frenet representations for the curves
for i=1:nfibers1
[T(:, :, i),N(:, :, i),B(:, :,i ),v1(:, i),k1(:, i),t1(:, i)] = frenetAll(curves1(1, :, i),curves1(2, :, i),curves1(3, :, i));
end

if samegroupflag==0
nfibers2=size(curves2, 3);
    for i=1:nfibers2
[T(:, :, i),N(:, :, i),B(:, :,i ),v2(:, i),k2(:, i),t2(:, i)] = frenetAll(curves2(1, :, i),curves2(2, :, i),curves2(3, :, i));
end
else
    nfibers2=size(curves1, 3);
end


distmsr=zeros(nfibers1, nfibers2);

%CASE WHERE THE GROUPS OF FIBERS ARE NOT EQUIVALENT
if (samegroupflag==0)
display('2 different fiber groups');
    for i=1:nfibers1
        for j=1:nfibers2

            distmsr(i, j)=sum(3.*(k1(:, i).*v1(:, i)-k2(:, j).*v2(:, j)).^2+(t1(:, i).*v1(:, i)-t2(:, j).*v2(:, j)).^2);
        end
      end
elseif (samegroupflag==1)
display('2 equivalent fiber groups');
%A SHORTCUT-CASE, where the two fibergroups supplied are the same. 

          for i=1:nfibers1
        for j=i:nfibers2
            distmsr(i, j)=sum(3.*(k1(:, i).*v1(:, i)-k1(:, j).*v1(:, j)).^2+(t1(:, i).*v1(:, i)-t1(:, j).*v1(:, j)).^2);
        end
          end

distmsr=distmsr+distmsr'- diag(diag(distmsr)); %To make a full matrix    
end


    