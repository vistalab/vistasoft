function model = glmOmnibus(model, units);
% 
% model = glmOmnibus(model, [units]);
%
% Compute the 'omnibus' contrast for a GLM -- an F test of the significance
% of all experimental conditions against baseline -- appending the results
% to a GLM model struct. 
% 
% model: struct produced by the glm function.
%
% units: 'F' or 'p', specifies the units to return for each voxel. [Default
% 'p', p-value associated w/ the F distribution.]
%
% Appends a model.omnibus field, containing the results of the contrast
% for each voxel, as well as an omnibus_units field, specifying the units
% used.
%
% For details see Burock and Dale, "Estimation and Detection of 
% Event-Related fMRI Signals with Temporally Correlated Noise: A 
% Statistically Efficient and Unbiased Approach", HBM, 2001.
%
% ras, 01/04/2006.
if ieNotDefined('units'), units = 'p'; end



% Omnibus Significance Test %  (from er_selxavg)
R = eye(model.nh, Navgs_tot);
q = R*hhat;
if model.nh > 1
    qsum = sum(q); % To get a sign %
else
    qsum = q;
end

if (model.nh == 1)
    Fnum = inv(R * model.C * R') * (q.^2) ;  %'
else
    Fnum = sum(q .* (inv(R*model.C*R') * q));  %'
end

Fden = model.nh * (eres_std.^2);
ind = find(Fden == 0);
Fden(ind) = 10^10;
F = sign(qsum) .* Fnum ./ Fden;

if (~isempty(fomnibusstem))
    fname = sprintf('%s_%03d.mat',fomnibusstem,slice);
    tmp = reshape(F,[nrows ncols]);
    er_svtfile(tmp,fname,override);
end

if isequal(lower(units), 'p')
    % convert to p-value, looking it up for the associated F distribution:
    % This will have [J, n-K] degrees of freedom, where J is the number
    % of rows in our restriction matrix R, and n and K are the # of rows
    % and columns in the design matrix X, respectively.
    p = sign(F) .* er_ftest(model.nh, model.dof, abs(F));
    
    % this prevents values from becoming infinite -- but I'm not
    % sure why p(indz) is set to 1 rather than s
    indz = find(p==0);
    p(indz) = 1;
    p = sign(p).*(-log10(abs(p)));

    omnibus(1:nrows, 1:ncols, slice) = reshape(p, [nrows ncols]);
end
