function outdt6 = dti3dStanford2dti3d(indt6)
% outdt6 = dti3dStanford2dti3d(indt6)
%
% (c) 2004 Matthias Bolten

outdt6 = indt6(:,:,:,[1 4 2 5 6 3]);
return;

% Old, slow code:
[m,n,o,c] = size(indt6);
outdt6 = zeros(m,n,o,c);

for i=1:m,
    for j=1:n,
        for k=1:o,
            outdt6(i,j,k,1) = indt6(i,j,k,1);
            outdt6(i,j,k,2) = indt6(i,j,k,4);
            outdt6(i,j,k,3) = indt6(i,j,k,2);
            outdt6(i,j,k,4) = indt6(i,j,k,5);
            outdt6(i,j,k,5) = indt6(i,j,k,6);
            outdt6(i,j,k,6) = indt6(i,j,k,3);
        end;
    end;
end;