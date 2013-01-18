function [E, embbasis]=dtiApproximateEmbeddingVectors(A, B, nvec)
%Nystrom approximation for normalized cuts from Fowlkes 2004 paper
%Input: unnormalize affinity matrices A of size nxn and B of size nxm
%Finds nvec embedding vectors for n+m fibers. 
%Other output; d1, pinvAbr, V, L -- user to embed new fiberrs into the same
%space. see function NewDataOntoEmbeddingVectors

%make sure the mx is symmetric


%ER 03/2008
n=size(A, 1);
m=size(B, 2);
if(n~=size(B, 1))
    display(['B should be nxm']);
    return;
end

%FOWLKES code -- Not sure what's wrong with his column/row sums
%d1=sum([A;B'], 1);
%d2=sum(B, 1)+sum(B', 1)*pinv(A)*B; 
%dhat=sqrt(1./[d1 d2])';
%A=A.*(dhat(1:n)*dhat(1:n)');
%B=B.*(dhat(1:n)*dhat(n+(1:m))');
%Asi=sqrtm(pinv(A));
%Q=A+Asi*B*B'*Asi;
%[U, L, T]=svd(Q);
%V=[A;B']*Asi*U*pinv(sqrt(L));
%for i=2:nvec+1
%    E(:, i-1)=V(:, i)./V(:, 1);
%end

%Modified code to return row/col sums required for applying spectral
%embedding to novel data 
%NOTE: THIS IS DIFFERENT FROM THEIR PAPER BUT I TTHINK IT IS RIGHT
%d1=sum([A B], 2); %this is a_r+b_r, row sum of A and B, 1xn
%pinvAbr=pinv(A)*sum(B, 2); %this is A^{-1}b_r required to compute row sums of affinities, d2
%d2=sum(B', 2)+B'*pinvAbr; %d2 is 1xm

br=sum(B, 2)./m; 
ar=sum(A, 2)./n; 
d1=(ar*n+br*m)./(m+n);
pinvAbr=pinv(A)*br; %this is A^{-1}b_r required to compute row sums of affinities, d2
d2=(sum(B', 2)+m.*B'*pinvAbr)./(m+n); %d2 is 1xm// Should be (n*.sum(B', 2)./n+m.*B'*pinvAbr)./(m+n);

dhat=sqrt(1./[d1; d2]); %dhat is m+n by 1

A=A.*(dhat(1:n)*dhat(1:n)');
B=B.*(dhat(1:n)*dhat(n+(1:m))');


Asi=real(sqrtm(pinv(A)));
Q=A+Asi*B*B'*Asi;
[U, L, T]=svd(Q);
clear Q T;
embbasis=Asi*U*pinv(sqrt(L));
V=[A;B']*embbasis;

clear Asi U;
%It is shown that W (mx of weights) is diagonalized by V and L: W=V*L*V^{T}; V is mxn; L is nxn
%below: coomputing new feature vectors (embedding vectors) from the
%eigenvector matrix.

%
for i=2:nvec+1
   % E(:, i-1)=V(:, i)./V(:, 1); %Pervy vector -- edinitsy!
    E(:, i-1)=V(:, i)./dhat; %Pervy vector -- edinitsy!
end
%U*Lambda^{-1} basis vectors for embedding space