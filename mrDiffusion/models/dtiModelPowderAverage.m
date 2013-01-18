function D = dtiModelPowderAverage(Vf, Vc, Vu, d_r, d_a, d_u, d_c)
%
% D = dtiModelPowderAverage(Vf, Vc, Vu, d_r, d_a, d_u, d_c)
%
% Vf: Volume fraction of fibers
% Vc: Volume fraction for csf
% Vu: Volume fraction for gray matter or glia
% d_r: radial diffusivity of WM
% d_a: axial diffusivity of WM
% d_u: diffusivity of GM/glia
% d_c: diffusivity of CSF
%
% See: Basser & Jones (2002). Diffusion-tensor MRI: theory, experimental
% design and data analysis - a technical review. NMR Biomed 15:456-467.
%
% For all scalar inputs, D is returned as a 3x3 tensor. If any parameter is
% an array, then D will be returned as a nx6 array of [Dxx Dyy Dzz Dxy
% Dxz Dyz] terms. The covariance terms are always zeros for this model, but
% they are inlcuded to make it wasy to call mrDiffusion tensor processing
% functions. E.g., you can pass the output directly into dtiComputeFA.
%
%
% HISTORY:
% 2009.07.01 RFD wrote it.
% 

if(~exist('Vc','var')||isempty(Vc))
    % Volume fraction for csf
    Vc = 0.0;
end
if(~exist('Vu','var')||isempty(Vu))
    % Volume fraction for gray matter or glia
    Vu = 0.0;
end
if(~exist('d_r','var')||isempty(d_r))
    % radial diffusivity of WM
    d_r = 0.275;
end
if(~exist('d_a','var')||isempty(d_a))
    % axial diffusivity of WM
    d_a = 2.0;
end
if(~exist('d_u','var')||isempty(d_u))
    % diffusivity of GM/glia
    d_u = 0.85;
end
if(~exist('d_c','var')||isempty(d_c))
    % diffusivity of CSF
    d_c = 3.1;
end

% Volume fractions for each of the fibers
%Vf = [0.7, 0.3, 0.0];

f_dir = [1 0 0; 0 1 0; 0 0 1];
% fiber directions are expected in theta, phi angles
[f_th,f_ph] = cart2sph(f_dir(:,1), f_dir(:,2), f_dir(:,3));

nFibers = size(Vf,2);
% Build the diffusion tensor for each fiber
for(j=1:nFibers)
    % Generate the eigenvectors corresponding to the fiber direction
    f = zeros(3);
    % first eignevector is simply the fiber direction
    [f(1,1),f(1,2),f(1,3)] = sph2cart(f_th(j),f_ph(j),1);
    % other two are the perpendiculars. We get z by rotating phi by pi/2
    [f(3,1),f(3,2),f(3,3)] = sph2cart(f_th(j),f_ph(j)+pi/2,1);
    % the final perpendicular is the normal to the plane of the other two
    f(2,:) = cross(f(1,:),f(3,:));
    % Now compose the expected diffusion tensor for this fiber:
    Df{j} = f*diag([d_a d_r d_r])*f';
end

b = 0.8;
q = [1 1 0; 0 1 1; 1 0 1; -1 1 0; 0 -1 1; 1 0 -1]; 

S0 = 1.0;

% Make directions unit vectors
q = q./repmat(sqrt(sum(q.^2,2)),1,3);

nDir = size(q,1);

scale = S0./(Vc + Vu + sum(Vf,2));
for(k=1:nDir)
    f_a = 0;
    for(j=1:nFibers)
        f_a = f_a + Vf(j) * exp(-b*q(k,:)*Df{j}*q(k,:)');
    end
    Shat(k) = scale * (Vc*exp(-b*d_c) + Vu*exp(-b*d_u) + f_a);
end


% Fit the Stejskal-Tanner equation: S(b) = S(0) exp(-b ADC),
% where S(b) is the image acquired at non-zero b-value, and S(0) is
% the image acquired at b=0. Thus, we can find ADC with the
% following:
%   ADC = -1/b * log( S(b) / S(0)
% But, to avoid divide-by-zero, we need to add a small offset to
% S(0). We also need to add a small offset to avoid log(0).
offset = 1e-12;
logS0 = mean(log(S0+offset));
logDw = log(Shat+offset);

% Compute the diffusion tensor D using a least-squares fit.
B = -b.*[q(:,1).^2 q(:,2).^2 q(:,3).^2 2*q(:,1).*q(:,2) 2*q(:,1).*q(:,3) 2*q(:,2).*q(:,3)];
% The signal atenutaion for one direction (i) is:  log(A_i/A_b0) = -TRACE(B_i*D)
% Therefore, to solve for D: D = inv(B)*log(A_b/A_b0)
coef = pinv(B)*(logDw-logS0)';
%D = [coef(1) coef(4) coef(5); coef(4) coef(2) coef(6); coef(5) coef(6) coef(3)];
D = coef';
% [vec,val] = eig(D);
% val = diag(val);
% md = mean(val);
% fa = sqrt(3/2).*(sqrt(sum((val-md).^2,1))./norm(val))

return

