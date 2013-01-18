function [Umin,Umax,Cmin,Cmax,Cmean,Cgauss,Normal] = compute_curvature(vertex,face,options)
% Compute principal curvature directions and values
%
%   [Umin,Umax,Cmin,Cmax,Cmean,Cgauss,Normal] = ...
%           compute_curvature(vertex,face,options);
%
%   Umin is the direction of minimum curvature
%   Umax is the direction of maximum curvature
%   Cmin is the minimum curvature
%   Cmax is the maximum curvature
%   Cmean=(Cmin+Cmax)/2
%   Cgauss=Cmin*Cmax
%   Normal is the normal to the surface
%
%   options.curvature_smoothing controls the size of the ring used for
%       averaging the curvature tensor.
%
%   The algorithm is detailed in 
%       David Cohen-Steiner and Jean-Marie Morvan. Restricted Delaunay
%       triangulations and normal cycle. In Proc. 19th Annual ACM Symposium
%       on Computational Geometry, pages 237-246, 2003.
%   and also in
%       Pierre Alliez, David Cohen-Steiner, Olivier Devillers, Bruno LeŽvy,
%       and Mathieu Desbrun. Anisotropic Polygonal Remeshing. ACM
%       Transactions on Graphics, 2003. Note: SIGGRAPH '2003 Conference
%       Proceedings
%
% Example:  See t_meshCurvature
%
%   Copyright (c) 2007 Gabriel Peyre


%% Programming Bug that bit me, too
%  From
%  http://www.mathworks.com/matlabcentral/fileexchange/5355-toolbox-graph
%
% Very useful, except for a bug in the compute_curvature function:
% 
% compute_curvature will generate an error on line 75 ("dp = sum(
% normal(:,E(:,1)) .* normal(:,E(:,2)), 1 );") for SOME surfaces. The error
% stems from E containing indices that are out of range which is caused by
% line 48 ("A = sparse(double(i),double(j),s,n,n);") where A's values
% eventually entirely make up the E matrix. The problem occurs when the i
% and j vectors create the same ordered pair twice in which case the sparse
% function adds the two s vector elements together for that matrix location
% resulting in a value that is too large to be used as an index on line 75.
% For example, if i = [1 1] and j = [2 2] and s = [3 4] then A(1,2) will
% equal 3 + 4 = 7.
% 
% The i and j vectors are created here: i = [face(1,:) face(2,:)
% face(3,:)]; j = [face(2,:) face(3,:) face(1,:)];
% 
% The fact that your code seems to depend on the order of the vertices in
% the faces matrix worries me because the curvature should be the same
% regardless of the order, obviously. To be fair, I don't completely
% understand how your code works so perhaps the way it is written it works
% out to not matter except that it does certainly matter when it results in
% an index out of bounds error as previously described.


%% Initialize and check variables 
orient = 1;

options.null = 0;
naver = getoptions(options, 'curvature_smoothing', 3);
verb = getoptions(options, 'verb', 1);

[vertex,face] = check_face_vertex(vertex,face);

n = size(vertex,2);
m = size(face,2);

%% associate each edge to a pair of faces
A = -triangulation2adjacency(face);

i = [face(1,:) face(2,:) face(3,:)];
j = [face(2,:) face(3,:) face(1,:)];
s = [1:m 1:m 1:m];
A = sparse(i,j,s,n,n); 

[i,j,s1] = find(A);     % direct link
[i,j,s2] = find(A');    % reverse link

I = find( (s1>0) + (s2>0) == 2 );

%% links edge->faces
E = [s1(I) s2(I)];
i = i(I); j = j(I);
% only directed edges
I = find(i<j);
E = E(I,:);
i = i(I); j = j(I);
ne = length(i); % number of directed edges

%% normalized edge
e = vertex(:,j) - vertex(:,i);
d = sqrt(sum(e.^2,1));
e = e ./ repmat(d,3,1);

% avoid too large numerics
d = d./mean(d);

% normals to faces
[tmp,normal] = compute_normal(vertex,face);

%% inner product of normals
dp = sum( normal(:,E(:,1)) .* normal(:,E(:,2)), 1 );
% angle un-signed
beta = acos(clamp(dp,-1,1));
% sign
cp = crossp( normal(:,E(:,1))', normal(:,E(:,2))' )';
si = orient * sign( sum( cp.*e,1 ) );
% angle signed
beta = beta .* si;
% tensors
T = zeros(3,3,ne);
for x=1:3
    for y=1:x
        T(x,y,:) = reshape( e(x,:).*e(y,:), 1,1,ne );
        T(y,x,:) = T(x,y,:);
    end
end
T = T.*repmat( reshape(d.*beta,1,1,ne), [3,3,1] );

%% do pooling on vertices
Tv = zeros(3,3,n);
w = zeros(1,1,n);
for k=1:ne
%    progressbar(k,ne);
    Tv(:,:,i(k)) = Tv(:,:,i(k)) + T(:,:,k);
    Tv(:,:,j(k)) = Tv(:,:,j(k)) + T(:,:,k);
    w(:,:,i(k)) = w(:,:,i(k)) + 1;
    w(:,:,j(k)) = w(:,:,j(k)) + 1;
end
w(w<eps) = 1;
Tv = Tv./repmat(w,[3,3,1]);

%% do averaging to smooth the field
options.niter_averaging = naver;
for x=1:3
    for y=1:3
        a = Tv(x,y,:);
        a = perform_mesh_smoothing(face,vertex,a(:),options);
        Tv(x,y,:) = reshape( a, 1,1,n );
    end
end

%% extract eigenvectors and eigenvalues
U = zeros(3,3,n);
D = zeros(3,n);
for k=1:n
    if verb==1
        progressbar(k,n);
    end
    [u,d] = eig(Tv(:,:,k));
    d = real(diag(d));
    % sort acording to [norma,min curv, max curv]
    [tmp,I] = sort(abs(d));    
    D(:,k) = d(I);
    U(:,:,k) = real(u(:,I));
end

Umin = squeeze(U(:,3,:));
Umax = squeeze(U(:,2,:));
Cmin = D(2,:)';
Cmax = D(3,:)';
Normal = squeeze(U(:,1,:));
Cmean = (Cmin+Cmax)/2;
Cgauss = Cmin.*Cmax;

% enforce that min<max
I = find(Cmin>Cmax);
Cmin1 = Cmin; Umin1 = Umin;
Cmin(I) = Cmax(I); Cmax(I) = Cmin1(I);
Umin(:,I) = Umax(:,I); Umax(:,I) = Umin1(:,I);

% try to re-orient the normals
normal = compute_normal(vertex,face);
s = sign( sum(Normal.*normal,1) ); 
Normal = Normal .* repmat(s, 3,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function z = crossp(x,y)
% x and y are (m,3) dimensional
z = x;
z(:,1) = x(:,2).*y(:,3) - x(:,3).*y(:,2);
z(:,2) = x(:,3).*y(:,1) - x(:,1).*y(:,3);
z(:,3) = x(:,1).*y(:,2) - x(:,2).*y(:,1);