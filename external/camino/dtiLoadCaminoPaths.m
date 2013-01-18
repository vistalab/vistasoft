function camPaths = dtiLoadCaminoPaths(filename, xform, bEndOnly)
%
% camPaths = dtiLoadCaminoPaths(filename)
%
% Loads fiber pathways from a Camino .Bfloat file. 
% 
% Notes: Pathways are assumed to be stored in the following Camino format:
% [<N>, <seed point index>, <x_1>, <y_1>, <z_1>,...,<x_numPoints>, <y_N>,
% <z_N>, <N>,...,<z_N>]
%  
% 
% HISTORY:
% 2007.09.07 Written by Anthony Sherbondy
% 2010.04.19 AJS made the code much faster by removing function calls and
% preallocating cell array.

% %% Endpoints only?
% if ieNotDefined('bEndOnly')
%     bEndOnly = 0;
% end

%% Open file and read all raw data in
fid = fopen(filename,'rb','b');
rawPaths = fread(fid,'float'); fclose(fid);

%% Create pathway structure 
camPaths.statHeader(1).agg_name = 'Length';
camPaths.pathwayInfo = [];
camPaths.pathways = {};

%% First read off all pathway sizes
buffer_size = length(rawPaths);
v_num_points = nan(buffer_size,1);
v_sptr = zeros(buffer_size,1);
sPtr = 1;
pp = 1;
while sPtr < buffer_size
    v_num_points(pp) = rawPaths(sPtr);
    v_sptr(pp) = (sPtr);
    sPtr = sPtr+3*v_num_points(pp)+2;
    pp = pp + 1;
end

%% Get acutal number of pathways represented in buffers
v_sptr = v_sptr(~isnan(v_num_points) & v_num_points>=3);
v_num_points = v_num_points(~isnan(v_num_points) & v_num_points>=3);

%% Now lets go and read all the pathways
camPaths.pathways = cell(numel(v_num_points),1);
%pct_step = 10;
%pct = pct_step;
%step = floor(length(v_num_points)/(100/pct_step));
for pp=1:length(v_num_points)
    sPtr = v_sptr(pp);
    numPoints = v_num_points(pp);
    camPaths.pathways{pp,1} = reshape(rawPaths(sPtr+2:sPtr+1+3*numPoints),3,numPoints);
%     if pp > step * pct
%         pct = floor(pp / step);
%         fprintf(1,'\n%3d percent file processed...', pct);
%         pct = pct + pct_step;
%     end
end

return;

