function [T, DISTR, df, Ybar, S] = symNormalTest2(TEST_TYPE, Ybar1, S1, n1, Ybar2, S2, n2, COV_TYPE, COV_DIFF)

% Two-sample tests for symmetric matrices.
%
%   [T, DISTR, df, Ybar, S] = symNormalTest2(TEST_TYPE, Ybar1, S1, n1, Ybar2, [S2], [n2], [COV_TYPE], [COV_DIFF])
%
% Input:
%   TEST_TYPE   Controls the type of test (assuming equal variances
%               between the two groups):
%                   'full': H0: both groups have the same mean tensors.
%                   'val' : H0: both groups have the same eigenvalues,
%                           with possibly different unknown eigenvectors.
%                   'vec' : H0: both groups have the same eigenvectors,
%                           with common unknown eigenvalues.
%   Ybar1, Ybar2  pxpx[sz] arrays of mean matrices for each group
%   S1, S2        qxqx[sz] arrays of covariance matrices for each group, q=p(p+1)/2
%                      (default S2 = 0)
%   n1, n2        Number of subjects in each group (default n2 = 1).
%   COV_TYPE      Type of covariance: 'spherical', 'orth-inv' or 'full' (default).
%   COV_DIFF      Assume different covariances: 1 (yes - default) or 0 (no)
% Output:
%   T           [sz] array of test statistics
%   DISTR       'f' or 'gamma'
%   df          2x1 degrees of freedom of F, or 2x[sz] parameters of Gamma (nu/2, 2a)
%   Ybar        pxpx[sz] array of pooled mean matrices
%   S           qxqx[sz] array of pooled covariance matrices
%
% E.g.:
%   [Ybar1, S1, n1] = symNormalStats(Y(:,:,g1));
%   [Ybar2, S2, n2] = symNormalStats(Y(:,:,g2));
%   [T, DISTR, df] = symNormalTest2('vec', Ybar1, S1, n1, Ybar2, S2, n2);
%
% Copyright by Armin Schwartzman, 2009

% HISTORY:
%   2008.12.30 ASH (armins@hsph.harvard.edu) wrote it.
%

% Check inputs
if ~exist('S2'),
    S2 = 0;
end
if ~exist('n2'),
    n2 = 1;
end
if (size(Ybar1,1) ~= size(Ybar1,2) | size(S1,1) ~= size(S1,2) | ...
    size(Ybar2,1) ~= size(Ybar2,2) | size(S2,1) ~= size(S2,2)),
    error('Wrong input format');
end
if (size(Ybar1,1) ~= size(Ybar2,1) | size(S1,1) ~= size(S2,1)),
    error('Wrong input format');
end
if ~exist('COV_TYPE'), COV_TYPE = 'full'; end
if (~strmatch(COV_TYPE,'spherical') & ~strmatch(COV_TYPE,'rot-inv') & ~strmatch(COV_TYPE,'full')),
    error('Only spherical, rot-inv and full covariance types supported.')
end
if ~exist('COV_DIFF'), COV_DIFF = 1; end

% Constants
n = n1 + n2;
p = size(Ybar1, 1);
q = size(S1, 1);
if (q ~= p*(p+1)/2),
    error('Wrong input format');
end

% Pooled mean and covariance
Ybar = (n1*Ybar1 + n2*Ybar2)/n;
S = ((n1-1)*S1 + (n2-1)*S2)/(n-2);

% Test type
switch TEST_TYPE,
    case 'full',
        d = permute(vecd(Ybar1 - Ybar2), [1 ndims(Ybar1)+1 2:ndims(Ybar1)]);
        switch COV_TYPE,
        case 'spherical',
            T = n1*n2/n * ndfun('mult', permute(d, [2 1 3:ndims(d)]), d);
            DISTR = 'f';
            if COV_DIFF,
                error('Full test, different spherical cov., not implemented.')
            end
            s2 = S(1,1,:);
            df = [q; q*(n-2)];
            T = df(2)/df(1) * T./(q*(n-2)*s2);
        case 'orth-inv',
            error('Full test, orth-inv cov., not implemented.')
        case 'full',
            if COV_DIFF,
                S = S1/n1 + S2/n2;
                Sinv = ndfun('inv', S);
                T = ndfun('mult', permute(d, [2 1 3:ndims(d)]), ndfun('mult', Sinv, d));
                Sinv1 = ndfun('mult', Sinv, ndfun('mult', S1/n1, Sinv));
                T1 = ndfun('mult', permute(d, [2 1 3:ndims(d)]), ndfun('mult', Sinv1, d));
                Sinv2 = ndfun('mult', Sinv, ndfun('mult', S2/n2, Sinv));
                T2 = ndfun('mult', permute(d, [2 1 3:ndims(d)]), ndfun('mult', Sinv2, d));
                m = 1./((T1./T).^2/(n1-1) + (T2./T).^2/(n2-1));
                df(2,:) = m-q+1; df(1,:) = q;
                DISTR = 'f';
                T = (m-q+1)./(q*m) .* T;
                df = shiftdim(df);
            else
                Sinv = ndfun('inv', S);
                T = n1*n2/n * ndfun('mult', permute(d, [2 1 3:ndims(d)]), ndfun('mult', Sinv, d));
                df = [q; n-q-1];
                DISTR = 'f';
                T = df(2)./df(1) .* T./(n-2);
            end
        end
        
    case 'val',
        [V1,L1] = ndSymEig(Ybar1); % [V1,L1] = ndfunm('eig', Ybar1);
        [V2,L2] = ndSymEig(Ybar2); % [V2,L2] = ndfunm('eig', Ybar2);
        T = n1*n2/n * sum(sum((L1 - L2).^2, 1), 2);
        switch COV_TYPE,
        case 'spherical',
            DISTR = 'f';
            if COV_DIFF,
                error('Eigval test, different spherical cov., not implemented.')
            end
            s2 = S(1,1,:);
            df = [p; q*(n-2)];
            T = df(2)/df(1) * T./(q*(n-2)*s2);
        case 'orth-inv',
            error('Full test, orth-inv cov., not implemented.')
        case 'full',
            Omega = 0;
            for i=1:p,
                W = cat(1, v(i,i,V1), -v(i,i,V2));
                Omega = Omega + ndfun('mult', W, permute(W, [2 1 3:ndims(W)]));
            end
            Omega = (n1*n2)/n * Omega;
            SS = zeros(size(Omega));  % (2q)x(2q)x[]
            if COV_DIFF,
                SS(1:q,1:q,:) = S1(1:q,1:q,:)/n1; SS(q+1:2*q,q+1:2*q,:) = S2(1:q,1:q,:)/n2;
            else
                SS(1:q,1:q,:) = S(1:q,1:q,:)/n1; SS(q+1:2*q,q+1:2*q,:) = S(1:q,1:q,:)/n2;
            end
            [a,nu] = chi2approx(SS, Omega);
            DISTR = 'gamma';
            df = cat(1, nu/2, 2*a);  % shape parameter, scale parameter
        end

    case 'vec',
        [V1,L1] = ndSymEig(Ybar1); % [V1,L1] = ndfunm('eig', Ybar1);
        [V2,L2] = ndSymEig(Ybar2); % [V2,L2] = ndfunm('eig', Ybar2);
        T = 2*n1*n2/n * (sum(sum(L1.*L2, 1), 2) - sum(sum(Ybar1.*Ybar2, 1), 2));
        switch COV_TYPE,
        case 'spherical',
            DISTR = 'f';
            if COV_DIFF,
                error('Eigvec test, different spherical cov., not implemented.')
            end
            s2 = S(1,1,:);
            df = [q-p; q*(n-2)];
            T = df(2)/df(1) * T./(q*(n-2)*s2);
        case 'orth-inv',
            error('Eigvec test, orth-inv cov., not implemented.')
        case 'full',
            Omega = 0;
            for i=1:p,
                for j=1:p,
                    W = omega(i,j,n1,n2,V1,V2);
                    Omega = Omega + ndfun('mult', W, permute(W, [2 1 3:ndims(W)]));
                end
            end
            Omega = (n1*n2)/n * Omega;
            SS = zeros(size(Omega));  % (2q)x(2q)x[]
            if COV_DIFF,
                SS(1:q,1:q,:) = S1(1:q,1:q,:)/n1; SS(q+1:2*q,q+1:2*q,:) = S2(1:q,1:q,:)/n2;
            else
                SS(1:q,1:q,:) = S(1:q,1:q,:)/n1; SS(q+1:2*q,q+1:2*q,:) = S(1:q,1:q,:)/n2;
            end
            [a,nu] = chi2approx(SS, Omega);
            DISTR = 'gamma';
            df = cat(1, nu/2, 2*a);  % shape parameter, scale parameter
        end
end

% Adjust output
T = shiftdim(T, 2);

end


%------------------------------------------------------------------------
% Auxiliary functions

function v = v(i,j,U)
    Ui = zeros(size(U));
    Ui(:,1,:) = U(:,i,:);
    Uj = zeros(size(U));
    Uj(1,:,:) = U(:,j,:);
    v = ndfun('mult', Ui, Uj);
    v = vecd((v + permute(v, [2 1 3:ndims(v)]))/2);
    v = permute(v, [1 ndims(v)+1 2:ndims(v)]);
end

function W = omega(i,j,n1,n2,U1,U2)
    sz = size(U1);
    p = sz(1);
    v1 = v(j, i, permute(U1, [2 1 3:ndims(U1)]))/2;
    v2 = v(j, i, permute(U2, [2 1 3:ndims(U1)]))/2;
    b = zeros([p 1 sz(3:end)]);
    b(1:p,:) = (n1*v2(1:p,:) + n2*v1(1:p,:))/(n1+n2);
    Eji = zeros(size(U1)); Eji(j,i,:) = 1/2;  Eji(i,j,:) = 1/2;
    Eji = permute(vecd(Eji), [1 ndims(Eji)+1 2:ndims(Eji)]);
    w1 = Eji - ndfun('mult', B(U1), b);
    w2 = Eji - ndfun('mult', B(U2), b);
    W = cat(1, w1, -w2);
end

function B = B(U)
    sz = size(U);
    p = sz(1);
    q = p*(p+1)/2;
    B = zeros([q p sz(3:end)]);
    for i=1:p,
        vv = v(i,i,U);
        B(:,i,:) = vv(1:q,1,:);
    end
end

function [a,nu] = chi2approx(S,Q)
    SQ = ndfun('mult',S,Q);
    k1 = ndfunm('trace',SQ);
    k2 = ndfunm('trace',ndfun('mult',SQ,SQ));
    a = k2./k1; nu = k1.^2./k2;
end


%------------------------------------------------------------------------
% Debugging
% M = zeros(3);
% S = eye(6);
% Y = symNormalRnd(M, S, [100 4]);
% [Ybar1, S1, n1] = symNormalStats(Y(:,:,1:40,:), 'full');
% [Ybar2, S2, n2] = symNormalStats(Y(:,:,41:100,:), 'full');
% [T, DISTR, df, Ybar, S] = symNormalTest2('val', Ybar1, S1, n1, Ybar2, S2, n2)

