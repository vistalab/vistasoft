function dt6 = dtiMEGFitTensor(X,dat)
% Entropy-regularized tensor fitting. Intead of using MEG, use Matlab's
% optimizer to minimize the objective function explicitly
% X is the gradient matrix for LLS with rows of form 
%[1, -b*gx^2, -b*gy^2, -b*gz^2, -2b*gx*gy, -2b*gx*gz, -2b*gy*gz]
% dat presumably has logs of signals - log(Si/S0)
N = size(X,1); % Number of gradients and signals
eta = 0.0012; % Regularization constant, presumably needs to be smaller for noisier data
eps = 1E-8; % small value to add to avoid logs of zeros
x0 = [1 0 0 1 0 1]; % Starting value for optimization
X1 = X(:,2:end);
options = optimset;
options = optimset(options, 'Display', 'off', 'GradObj', 'off', 'LargeScale', 'off');
x = fminunc(@(x) entr_obj(x, X1, dat, eta, eps), x0, options);
R = [x(1) x(2) x(3); 0 x(4) x(5); 0 0 x(6)];
D = R'*R+eps*eye(3);
%norm(D)
dt6 = [D(1,1) D(2,2) D(3,3) D(1,2) D(1,3) D(2,3)];
return

function res = entr_obj(x, X, dat, eta, eps)
    R = [x(1) x(2) x(3); 0 x(4) x(5); 0 0 x(6)];
    W = R'*R+eps*eye(3);
    W0 = eye(3); % Prior
    ee = trace(W*(logm(W) - logm(W0)))-trace(W)+trace(W0);
    d = [W(1,1); W(2,2); W(3,3); W(1,2); W(1,3); W(2,3)];
    shat = X*d;
    SE = sum((shat-dat).^2); % Sum of squared errors
    res = real(ee+eta*SE);
return
