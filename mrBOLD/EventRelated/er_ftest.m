function p = er_ftest(dof1, dof2, F, dof2max)
%
% p = er_ftest(dof1, dof2, F, <dof2max>)
%
% Computes p-value given F-value. p and F can be vectors.
% dof1 = dof of numerator (Number of Rows in RM)
% dof2 = dof of denominator (DOF)
%
% Ref: Numerical Rec in C, pg 229.
%
% ras, 05/05; based on Ftest in fs-fast code.

if(nargin ~= 3 & nargin ~= 4)
    msg = 'Usage: p = FTest(dof1, dof2, F, <dof2max>)';  
    error(msg);
    return;
end

if(length(dof1) > 1)
    error('dof1 must be a scalar');
end
if(length(dof2) > 1)  
    error('dof2 must be a scalar');
end

if(nargin == 4) dof2 = min(dof2,dof2max); end


z = dof2./(dof2 + dof1 * F);


% 08/05/04: temp debug stuff, b/c of a funny session
if any(z(:) < 0 | z(:) > 1 | isnan(z(:))) | ~isreal(z)
    fprintf('any < 0?: %i \n',any(z(:) < 0))
    fprintf('any > 1?: %i \n',any(z(:) > 1))
    fprintf('Isnan?: %i \n',any(isnan(z(:))))
    fprintf('~Isreal?: %i \n',~isreal(z))
    z = 0.5 * ones(size(z)); % temp hack so that betainc doesn't fail
end
% fprintf('DEBUG: Z ranges from %f to %f \n',min(z(:)),max(z(:)));

p = betainc(z, dof2/2, dof1/2);

return;


