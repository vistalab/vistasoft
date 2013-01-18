function Es=dtiNewDataOntoEmbeddingVectors(A, S, embbasis, nvec)

%One-Shot Tecnique -- applies only when input affinities matrix is
%nonnegative definite. 

%Project new data onto Embedding Vectors estimated by
%ApproximateEmbeddingVectors(A, B, nvec)
%Nystrom approximation for normalized cuts from Fowlkes 2004 paper
%//application to novel data proposed by ODonell 2006
%Input: embedding space and row/column sums from training data. 
%Finds nvec embedding vectors; S is the new matrix size nxt. 
 [n t]=size(S);
 
if size(A,1)~=n
    display('S should be n by m');
    return;
end

%d1=(ar*n+br*t)./(t+n);
%d2=(sum(S', 2)+t*S'*pinvAbr)./(t+n); %d2 is 1xm// Should be (n*.sum(B', 2)./n+m.*B'*pinvAbr)./(m+n);
%dhat=sqrt(1./[d1; d2]); %dhat is m+n by 1

br=sum(S, 2)./t; 
ar=sum(A, 2)./n; 
d1=(ar*n+br*t)./(t+n);
pinvAbr=pinv(A)*br; %this is A^{-1}b_r required to compute row sums of affinities, d2
d2=(sum(S', 2)+t.*S'*pinvAbr)./(t+n); %d2 is 1xm// Should be (n*.sum(B', 2)./n+m.*B'*pinvAbr)./(m+n);
dhat=sqrt(1./[d1; d2]); %dhat is m+n by 1

S=S.*(dhat(1:n)*dhat(n+(1:t))');


%After scaling S eigenvectors are estimated using Nystrom method:
Vs=[S']*embbasis;

for i=2:nvec+1
   % Es(:, i-1)=Vs(:, i)./Vs(:, 1); %Pervy vector -- edinitsy!
    Es(:, i-1)=Vs(:, i)./dhat(n+(1:t)); %Pervy vector -- edinitsy!
end
