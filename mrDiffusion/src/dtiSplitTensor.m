function [eigVec, eigVal] = dtiSplitTensor(tensor)
% Derive eigenvector and eigenvalues from the volume of tensor data 
%
% [eigVec, eigVal] = dtiSplitTensor(tensor)
% 
% The input tensor array is in XxYxZx6xN format 
% The order of the value in the 4th dimension is [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz])
% 
% The routine returns a XxYxZx3x3xN volume of eigVec 
% and                 a the XxYxZx3xN volume of eigVal arrays
% 
% X,Y,Z are positions in the volume
% N is the number of subjects.
%
% SEE ALSO: dtiRebuildTensor
%
% HISTORY:
% 2003.12.08 ASH (armins@stanford.edu) Wrote it.
% 2004.02.03 DTM (merget@cs.stanford.edu) Sort eigVal from high to low
% 2004.02.17 ASH: added extra dimension for subjects
% 2005.01.06 ASH: truly added extra dimension for subjects
%
% The code is implemented in the mex file dtiSplitTensor.c. If you don't
% have a that file compiled for you system, then the (very slow) code below
% will be executed.  In one test, the following code ran in 2.85 minutes,
% and the compiled version ran in about 11 seconds.
%
% (c) Stanford VISTA Team 2003

disp('This function is mexified for speed- compile dtiSplitTensor.c.');

sz = size(tensor);
if (length(sz)<5),
    sz =[sz, 1];
end

% vec = zeros([sz(1:3), 3, 3, sz(5)]);
% val = zeros([sz(1:3), 3, sz(5)]);

h = mrvWaitbar(0, 'Computing tensors...');
for(x=1:sz(1))
    for(y=1:sz(2))
        for(z=1:sz(3))
            for(j=1:sz(5))
                D = [tensor(x, y, z, 1, j), tensor(x, y, z, 4, j), tensor(x, y, z, 5, j);
                     tensor(x, y, z, 4, j), tensor(x, y, z, 2, j), tensor(x, y, z, 6, j);
                     tensor(x, y, z, 5, j), tensor(x, y, z, 6, j), tensor(x, y, z, 3, j)];
                [vec, val] = eig(D);
                [val2, order] = sort(-diag(val));
                eigVec(x, y, z, :, :, j) = vec(:, order);
                eigVal(x, y, z, :, j) = -val2;
            end
        end
    end
    mrvWaitbar(x/sz(1),h);
end
close(h);

return;