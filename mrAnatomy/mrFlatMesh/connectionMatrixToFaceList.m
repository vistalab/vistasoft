function faceList=connectionMatrixToFaceList(conmat)
% faceList=connectionMatrixToFaceList(conmat)
% PURPOSE: Returns a list of triangular faces in a connection matrix
%
% Wade 062703
%

[ny,nx]=size(conmat);
if (ny~=nx)
    error('Connection matrix must be square');
end

for i=1:ny
    i;
    % Loop down the connection matrix rows
    % Find the non zero elems in each row 'i'.
    [nzi]=find(conmat(i,:));
    % Make a mini conmat
    m_conmat=conmat(nzi,nzi);
    % Do a check : sums of columns should be ==2 if things are triangular
   
    sumCols=sum(m_conmat);
    if sum(sumCols<2)
        disp(i);
         sumCols=sum(m_conmat)
        error('Found some non-triangular bits');
    end
end

