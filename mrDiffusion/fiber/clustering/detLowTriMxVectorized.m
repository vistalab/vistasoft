function [determinant, varcovmatrix] =detLowTriMxVectorized(vector)

%Calculates determinants of the 3 by 3 matrices which are vectorized after
%low-triangularization. 
%E.g., matrix=zeros(5); lowtriagvector=matrix([1:3 5:6 9])
%This function basically returns generalized variance for a matrix of
%var/cov describing XYZ vector: [varX covYX covZX varY covZY varZ]

%ER 02/2008 SCSNL

matrixrepresentation=zeros(3); 
matrixrepresentation([1:3 5:6 9])=vector; 
matrixrepresentation=matrixrepresentation+matrixrepresentation'-triu(matrixrepresentation); 

determinant=det(matrixrepresentation); 

varcovmatrix=matrixrepresentation; 
