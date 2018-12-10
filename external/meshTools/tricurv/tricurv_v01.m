function out=tricurv_v01(tri,p)
% Calculate principal curvatures and their directions on a triangular mesh
%
%    out = tricurv_v01(tri,p)
%
% Approximations of curvature are based on local (N=1) neighborhood
% elements and vertices. Note that calculations at vertices with few
% adjacent triangles, and hence few adjacent vertices, are expanded to a
% greater neighborhood.
%
% BW:  I edited this routine for speed.  It didn't pre-allocate many
% variables, and that slowed it down a fair bit.  It could still be speeded
% up.  Repmat is called a ton and is the slowest part.
%
% Reference:
% 1) Chen and Schmitt (1992) Intrinsic surface properties from surface
%    triangulation
% 2) Dong et al. (2005) Curvature estimation on triangular mesh,
%    JZUS
%
% This code makes use of routines: buildInverseTriangualtion.m & removeDO.m
% initially written by: David Gringas. He is gratefully acknowledged
%
% Input:        t <mx3> array of triangle indices into:
%               xyz <nx3> coordinates
% Output:       structure containing: Principal curvatures and directions,
%               Chen and Schmitt's coefficients, etc.
%
% Example:  See t_meshCurvature
%
%
% Version:      1
% JOK 030809

% I/O check:
if nargin~=2, error('Wrong # of inputs'); end
if nargout ~= 1
    error('Output is a structure, wrong designation!')
end
nt = size(tri);
if nt(2)~=3
    error('Triangle element matrix should be mx3!')
end
mp = size(p);
if mp(2)~=3, error('Vertices should be nx3!'); end

% 1) Compute vertex normals (weighted by distance)
nv = vertnorm_dw(tri,p);

% 2) Define neighborhoods and calculate weighted normals
% Average at vertices
itri = buildInverseTriangulation(tri);
nVertices = size(p,1);
a11 = zeros(nVertices,1);
a12 = a11; a13 = a11;  a22 = a11; a23 = a11;
a = a11; b = a11; c = a11;

wb = mrvWaitbar(0,'Computing curvature.');
for j=1:nVertices
    if ~mod(j,1000), wb = mrvWaitbar(j/nVertices,wb); end
    
    % Triangles adjacent to vertex j
    ind01=removeD0(itri(j,:));
    
    % Vertices of adjacent triangles
    ind02 = tri(ind01,:);ind02 = unique(ind02(:));
    
    if length(ind02)<5
        % Larger neighborhood for triangles with less than 5 unique
        % triangles
        for i=1:length(ind02)
            
            % Triangles adjacent to neighborhood vertices in ind02(i)
            indaux01 = removeD0(itri(ind02(i),:));
            
            % Vertices  of larger neighborhood
            indaux02 = tri(indaux01,:);
            indaux02 = unique(indaux02(:));
            ind02 = unique([ind02;indaux02]);
        end
    end
    
    % Define tangent vectors
    pdist = p(ind02,:) - repmat(p(j,:),length(ind02),1);
    aux01 = pdist - repmat(dot(pdist,nv(ind02,:),2),1,3).*nv(ind02,:);
    t = aux01./repmat(sqrt(sum(aux01.*aux01,2)),1,3);
    
    % Normal curvature
    kn = -dot(pdist,nv(ind02,:)- ...
        repmat(nv(j,:),length(ind02),1),2)./dot(pdist,pdist,2);
    [~,ind03] = max(kn);
    
    % Local principal directions
    out.e1(j,:) = t(ind03,:);
    aux02 = cross(out.e1(j,:),nv(j,:),2);
    out.e2(j,:) = aux02./repmat(sqrt(sum(aux02.*aux02,2)),1,3);
    
    % Chen and Schmitt: calculation of coefficients
    thetai = real(acos(dot(t,repmat(out.e1(j,:),length(ind02),1),2)));
    
    % Check for NaN
    thetai(isnan(thetai)) = 0; 
    
    % Can be set to zero as all coefficients contain a sin term and thus
    % are zero
    kn(isnan(kn))=0;
    
    % Intermediate terms.  I wonder if we could get away without them?
    a11(j,1) = sum((cos(thetai)).^2.*(sin(thetai)).^2,1);
    a12(j,1) = sum(cos(thetai).*(sin(thetai)).^3,1);
    a22(j,1) = sum((sin(thetai)).^4,1);
    a13(j,1) = sum((kn-kn(ind03)*(cos(thetai)).^2).*cos(thetai).*sin(thetai),1);
    a23(j,1) = sum((kn-kn(ind03)*(cos(thetai)).^2).*(sin(thetai)).^2,1);
    
    % coefficients used below for curvatures
    a(j,1) = kn(ind03);
    b(j,1) = (a13(j)*a22(j)-a23(j)*a12(j))/(a11(j)*a22(j)-a12(j)^2);
    c(j,1) = (a11(j)*a23(j)-a12(j)*a13(j))/(a11(j)*a22(j)-a12(j)^2);
end
delete(wb)

% Gaussian, mean normal, principal curvatures
aux03 = sort([.5*(a+c+sqrt((a-c).^2+4*b.^2)),.5*(a+c-sqrt((a-c).^2+4*b.^2))],2);
out.k1 = aux03(:,1);
out.k2 = aux03(:,2);
out.km = .5*(out.k1+out.k2);
out.kg = out.k1.*out.k2;

end % End tricurv_v01


%% Subfunctions
function invTRI = buildInverseTriangulation(TRI)
%
% If this could be speeded up, that would be good.

% Building the inverse triangulation, i.e. a link from node indexes to
% triangle indexes.
nbTri  = length(TRI);
nbNode = max(reshape(TRI,[],1));
comp   = zeros(nbNode,1);
invTRI = zeros(nbNode,8);

for i=1:nbTri
    for j=1:3
        index = TRI(i,j);
        comp(index) = comp(index) + 1;
        invTRI(index,comp(index)) = i;
    end
end
end % End buildInverseTriangulation

%%
function out=removeD0(x)
% Removing duplicate and null values
s = sort(x);
s1 = [0,s];
s2=[s,s(length(s))];
ds=(s1-s2);
out=s(logical(ds~=0));
end% End removeD0


%%
function nv=vertnorm_dw(tri,p)
% Function to compute normal vector of vertices comprising a triangular
% mesh. Based on trinormal and computeNormalVectorTriangulation.m by David
% Gringas
% Input:    tri mx3 <triangular index matrix>
%           p nx3 array of vertices
% Output:   nvec <nx3> array of normal vectors
% JOK230709
% Version: 1

% I/O check
% to be completed

% Construct vectors
v = [p(tri(:,3),1)-p(tri(:,1),1), p(tri(:,3),2)-p(tri(:,1),2), p(tri(:,3),3)-p(tri(:,1),3)];
w = [p(tri(:,2),1)-p(tri(:,1),1), p(tri(:,2),2)-p(tri(:,1),2), p(tri(:,2),3)-p(tri(:,1),3)];
% Calculate cross product
normvec = [v(:,2).*w(:,3)-v(:,3).*w(:,2), ...
    -(v(:,1).*w(:,3)-v(:,3).*w(:,1)), ...
    v(:,1).*w(:,2)-v(:,2).*w(:,1)];
% Normalize
lnvec = sqrt(sum(normvec.*normvec,2));
nvec = normvec ./ repmat(lnvec,1,3);

% Average at vertices
itri = buildInverseTriangulation(tri);

% These were unused
% nvecx=zeros(length(p),1);
% nvecy=zeros(length(p),1);
% nvecz=zeros(length(p),1);

nVertices = size(p,1);
nv = zeros(nVertices,3);
for j=1:nVertices
    % Find centroids and weight based on distance:
    ind01=removeD0(itri(j,:));
    cen=tricentroid(p,tri(ind01,:));
    nc=size(cen);
    distcen = cen - repmat(p(j,:),nc(1),1);
    w = 1./sqrt(sum(distcen.*distcen,2));
    nvecx=mean(w.*nvec(ind01,1));
    nvecy=mean(w.*nvec(ind01,2));
    nvecz=mean(w.*nvec(ind01,3));
    % Nomalize
    lnv = sqrt(nvecx^2+nvecy^2+nvecz^2);
    nv(j,:) = [nvecx/lnv,nvecy/lnv,nvecz/lnv];
end

end % End vertnorm

%%
function out = tricentroid(v,tri)
% Function to output the centroid of triangluar elements.
% Note that the output will be of length(tri)x3
% Input:    <v>     nx2 or 3: vertices referenced in tri
%           <tri>   mx3: triangle indices
% Version:      1
% JOK 300509

% I/O check
[nv,mv]=size(v);
[~,mt]=size(tri);
if mv==2,     v(:,3) = zeros(nv,1);
elseif mt~=3, tri=tri';
end

% This is probably fine.  Could be done as a matrix multiply
out(:,1) = 1/3*(v(tri(:,1),1)+v(tri(:,2),1)+v(tri(:,3),1));
out(:,2) = 1/3*(v(tri(:,1),2)+v(tri(:,2),2)+v(tri(:,3),2));
out(:,3) = 1/3*(v(tri(:,1),3)+v(tri(:,2),3)+v(tri(:,3),3));

end%tricentroid

%%