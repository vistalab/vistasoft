function E = dtiNewDataOntoEmbeddingVectors2(S, ar, br, pinvAbr, L, UT, nvec)

%Two-shot technique. Useful when input affinities matrix is not positive
%definite (commonly used here gaussian-transformed euclidian distances are always nonegative
%definite, hence use NewDataOntoEmbeddingVectors). 

%Nystrom approximation for normalized cuts from Fowlkes 2004 paper
%Input: unnormalize affinity matrices A of size nxn and B of size nxm
%Finds nvec embedding vectors for n+m fibers. 
%Other output; d1, pinvAbr, V, L -- user to embed new fiberrs into the same
%space. see function NewDataOntoEmbeddingVectors

%ER 03/2008
%ATTENTION: 
%NORMALIZATION IS NOT PROPER HERE. 
%TODO fix normalization similarly to how it is done in
%NewDataOntoEmbeddingVectors.m -- or do not use at all. 


%ER 03/2008
n=size(ar, 1);
m=size(S, 2);
if(n~=size(S, 1))
    display(['S should be nxm']);
    return;
end


d1=(ar*n+br*m)./(m+n);
d2=(sum(S', 2)+m*S'*pinvAbr)./(m+n); %d2 is 1xm// Should be (n*.sum(B', 2)./n+m.*B'*pinvAbr)./(m+n);
dhat=sqrt(1./[d1; d2]); %dhat is m+n by 1


%%%A=A.*(dhat(1:n)*dhat(1:n)');
S=S.*(dhat(1:n)*dhat(n+(1:m))');

%^^^ THESE MATRICES ARE NORMALIZED BY THE SQUARE ROOT OF ROW/COL sums!!!

%%[U, L, UT]=svd(A);
%^^these are not orthogonal so need to be orthogonalized

UbarT=[UT pinv(L)*UT*S];

Z=UbarT'*sqrt(L);

clear UT L S; 
[F, SGM, FT]=svd(Z'*Z);

clear FT; 

V=Z*F*pinv(sqrt(SGM)); 

%It is shown that W (mx of weights) is diagonalized by V and L: W=V*L*V^{T}; V is mxn; L is nxn
%below: coomputing new feature vectors (embedding vectors) from the
%eigenvector matrix.

%
for i=2:nvec+1
    E(:, i-1)=V(:, i)./V(:, 1); %Pervy vector -- edinitsy!
   % E(:, i-1)=V(:, i)./sqrt(dhat); %Pervy vector -- edinitsy!
end
%U*Lambda^{-1} basis vectors for embedding space