function [newX]=rigidPerimeterSmooth(N,P,X,X_zero,nIteration)
% [newX]=rigidPerimeterSmooth(N,P,X,X_zero,nIteration)
% PURPOSE
% Smooth out the unfolded mesh by averaging internal points while keeping
% external points fixed
% Author: Wade
% Date 06/16/03
% Make a connection matrix containing both the perimeter points (X_zero)
% and the original internal points (X) based on the connection matrices N
% and P
% N is nInternalPoints squared and is the connection matrix for the
% internal points.
% P is nInternalPoints by nPerimeterPoints and gives the connections
% between the two groups
N=sparse(N);
P=sparse(P);


nInternalPoints=length(X);
nPerimPoints=length(X_zero);
nConInternal=nnz(N);
nConPerimeter=nnz(P);
% keyboard
% newN=spalloc(nInternalPoints+nPerimPoints,nInternalPoints+nPerimPoints,nConInternal+nConPerimeter);
% newN=sparse([],[],[],nInternalPoints+nPerimPoints,nInternalPoints+nPerimPoints,0);

disp('allocated');

newN=[N,P];
endSparse=sparse([],[],[],nPerimPoints,nPerimPoints,0);
belowSection=[P',endSparse];
newN=[newN;belowSection];

% newN(nInternalPoints+1:end,:)=P';
% newN(:,nInternalPoints+1:end)=P;

newX=[X;X_zero];
    
    for t=1:nIteration
        newX(:,1)=connectionBasedSmooth(newN,newX(:,1));
        newX(:,2)=connectionBasedSmooth(newN,newX(:,2));
        % Reset the perimeter points 'cos they shoudn't change
        newX(nInternalPoints+1:end,:)=X_zero;
    end
    
    newX=newX(1:nInternalPoints,:);
    