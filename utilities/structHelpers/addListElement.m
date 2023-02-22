function newList = addListElement(list,newElement)
%
% function newList = addListElement(list,newElement)
%
%AUTHOR:  Wandell
%DATE:    01.03.01
%PURPOSE:
%  Add a string to a cell array
%

newList = list;
l = size(list,1);
newList{l+1} = newElement;

return;