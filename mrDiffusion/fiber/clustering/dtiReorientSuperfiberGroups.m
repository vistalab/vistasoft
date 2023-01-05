function [SuperFibersGroup, IDsOfFlipped, startCoords, endCoords]=dtiReorientSuperfiberGroups(SuperFibersGroup)

%Given a set of superfiber groups across the participants, checks that all start points and all end points are
%grouped respectively. Flip some groups if needed. Returned all the
%superfibers (including the reoriented ones) and a vector with "1" for
%groups which had to be reoriented (first node -> last)

%Input: 1xX array of SuperFibersGroup
%ER wrote it 08/10/2009
numsubjects=length(SuperFibersGroup);
IDsOfFlipped=[];
for s=1:numsubjects
numNodes(s)=size(SuperFibersGroup(s).fibers{1}, 2);
end

if length(unique(numNodes))>1
    error ('need to have the same number of nodes in each superfibergroup'); 
end

curves=zeros(3, unique(numNodes), numsubjects); 
for i=1:numsubjects
    curves(:, :, i)=SuperFibersGroup(i).fibers{1};
end

%Check that the all the starting points and all the end points are grouped.
%Flip the fibers whose end point groups with the starting points of the
%other. 
T = clusterdata([squeeze(curves(:, 1, :))'; squeeze(curves(:, end, :))'], 'maxclust', 2);
Tstart=T(1:end/2); Tend=T(end/2+1:end); 

%Take first and last points in every fibers and cluster together. The two
%clouds should be quite separate for a tract with distinct termination
%ROIs. Looking at the labels for the start points, keep fibers
%corresponding to classlabel=1 intact. Swap the node order for the fibers
%corresponding to classlabel=2; 
if ~(sum(Tstart==2)==numsubjects | sum(Tstart==1)==numsubjects)
curves(:, :, Tstart==2)=flipdim(curves(:, :, Tstart==2), 2); 
display(['Flipped ' num2str(sum(Tstart==2)) ' superfibers of ' num2str(numsubjects)]); 
IDsOfFlipped=Tstart==2;
end

startCoords=zeros(3, 1); 
endCoords=zeros(3, 1); 

for i=1:numsubjects
SuperFibersGroup(i).fibers{1}= curves(:, :, i);
startCoords=startCoords+SuperFibersGroup(i).fibers{1}(:, 1); 
endCoords=endCoords+SuperFibersGroup(i).fibers{1}(:, end); 
end

startCoords=startCoords./numsubjects;
endCoords=endCoords./numsubjects;

