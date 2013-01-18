function [E, ar, br, pinvAbr, L, UT]=dtiApproximateEmbeddingVectors2(A, B, nvec)
%Two-shot technique. Use if affinities are not positive definite (otherwise
%use dtiApproximateEmbeddingVectors/NewDataOntoEmbeddingVectors for single shor calculations)

%Nystrom approximation for normalized cuts from Fowlkes 2004 paper
%Input: unnormalize affinity matrices A of size nxn and B of size nxm
%Finds nvec embedding vectors for n+m fibers. 
%Other output; ar, br, pinvAbr (Expected)), UT, L -- used to embed new fiberrs into the same
%space using function NewDataOntoEmbeddingVectors2. Note that the variables
%returned by this function can not be immediately used in
%NewDataOntoEmbeddingVectors2 for they are not properly scaled
%(NewDataOntoEmbeddingVectors2 needs to be fixed). Scaling is correct for
%dtiApproximateEmbeddingVectors/NewDataOntoEmbeddingVectors which should be
%used if you have euclidian distances transformed into affinities using
%gaussian  kernel. 

%make sure the mx is symmetric


%ER 03/2008
n=size(A, 1);
m=size(B, 2);
if(n~=size(B, 1))
    display(['B should be nxm']);
    return;
end

br=sum(B, 2)./m; 
ar=sum(A, 2)./n; 
d1=(ar*n+br*m)./(m+n);
%d1=sum([A B], 2)./(m+n); %this is a_r+b_r, row sum of A and B, 1xn

pinvAbr=pinv(A)*br; %this is A^{-1}b_r required to compute row sums of affinities, d2
d2=(sum(B', 2)+m*B'*pinvAbr)./(m+n); %d2 is 1xm// Should be (n*.sum(B', 2)./n+m.*B'*pinvAbr)./(m+n);
dhat=sqrt(1./[d1; d2]); %dhat is m+n by 1

A=A.*(dhat(1:n)*dhat(1:n)');
B=B.*(dhat(1:n)*dhat(n+(1:m))');
%^^^ THESE MATRICES ARE NORMALIZED BY THE SQUARE ROOT OF ROW/COL sums!!!

[U, L, UT]=svd(A);
%^^these are not orthogonal so need to be orthogonalized

UbarT=[UT pinv(L)*UT*B];

Z=UbarT'*sqrt(L);

[F, SGM, FT]=svd(Z'*Z);

clear FT; 

V=Z*F*pinv(sqrt(SGM)); 

%It is shown that W (mx of weights) is diagonalized by V and L: W=V*L*V^{T}; V is mxn; L is nxn
%below: coomputing new feature vectors (embedding vectors) from the
%eigenvector matrix.

%
for i=2:nvec+1
    E(:, i-1)=V(:, i)./V(:, 1); %Pervy vector -- edinitsy!
%    E(:, i-1)=V(:, i)./sqrt(dhat); %Pervy vector -- edinitsy!
end
%U*Lambda^{-1} basis vectors for embedding space