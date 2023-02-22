%
%   [nodes,edges] =  grow_gray(classData, numLayers, [voi], [layer0])
% 
%  GB 05/11/14
%
% This is the matlab transcription of the mrGray function that grows gray matter.
% It is a mex function that needs the auxiliairy files :
%     - gray.h
%     - gray.cpp
%     - mrGlobals.h
% 
% INPUTS :
%     - classData : should be the field "data" of a variable loaded from a class file
%     - numLayers : number of layers to grow the gray matter
%     - voi : array of six elements representing the volume of interest. It should be :
%                 [xmin xmax ymin ymax zmin zmax]
%             should be the field "header.voi" of a variable loaded from a class file
%     - layer0 : optional input argument. 
%                   - 0 : no white matter included in the gray graph
%                   - 1 : the white boundary included in the gray graph. 
%                         In this case, the layer number of the boundary will be 0. 
%                   - 2 : All the white matter fully connected is included
%                         in the gray graph
%
%             
% OUTPUTS :
%     - nodes : structure containing nodes of the gray matter
%     - edges : structure containing edges of the gray matter
%