function [str]=fiberToStr3(fg, xformToAcPc, xform)
% Converts fibers to strings
% 
%   [str]=fiberToStr3(fg, xformToAcPc, xform)
%
% Developer notes
% Layout
% NS = # stats
% NF = # fibers
% NP = # points for a fiber
% 
% fg
% 	params<1x NS>
% 		icpp
% 		stat<1 x NF>
% 		//Used as {1,i}
% 		
% 	fibers<NF x 1>
% 		<3 x NP>//Raw fibers
% 		//To concat use		cat(2,fg.fibers{:})
% 		
% 	pathwayInfo<1 x NF>
% 		point_stat_array<NS x NP>
% 		//To concat use		cat(2,fg.pathwayInfo.point_stat_array);
%%         
%

if(~exist('xformToAcPc','var')), xformToAcPc = eye(4); end

if(exist('xform','var') && ~isempty(xform) && (isstruct(xform) || ~all(all(xform==eye(4)))))
    fg = dtiXformFiberCoords(fg, xform);
    xformToAcPc = xformToAcPc*inv(xform);
end

version = 3;

% Create blank database for finding some of the sizes to write out
pdb = mtrPathwayDatabase();

% PDB structure will have stat header info, but fg will retain the actual
% statistics per path to record
valid_stats=[];
numstats=0;
for ff=1:length(fg.params)
    if isfield(fg.params{ff},'agg') && isfield(fg.params{ff},'lname') && isfield(fg.params{ff},'ile')
        % FGs that did not have statistics added using dtiCreateQuenchStats
        % will not have these fields (agg, lname, ile, icpp, ivs, uid) and
        % this will fail.
        pdb = addStatisticHeader(pdb,fg.params{ff}.agg,fg.params{ff}.lname, fg.params{ff}.ile, fg.params{ff}.icpp, fg.params{ff}.ivs, fg.params{ff}.uid);
        valid_stats(numstats+1) = ff;
        numstats = numstats + 1;
    else
        disp('fiberToStr3: Stats not created with dtiCreateQuenchStats ... skipping addStatisticHeader.'); 
    end
end
numalgs = 0;
numpaths = length(fg.fibers);

% Redo offset
offset = 4*4 + 16*8 + numstats * getStatisticsHeaderSize(pdb) + numalgs * getAlgorithmsHeaderSize(pdb); % 4 uint, 16 doubles

% fiberToStrMex(fg, pdb, offset, 'asde', xformToAcPc);

% Preallocated array
MAX_SIZE = 50000000;

% Save as string
str = zeros(1,MAX_SIZE,'uint8');
i = 1;
int32size   = size(typecast(int32(0),'uint8'),2);

str(1:4) = typecast( uint32(offset),'uint8'); i=i+int32size;
temp = typecast( xformToAcPc(:)','uint8');
str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);

str(i:i+3)=typecast( uint32(numstats),'uint8'); i=i+int32size;

temp = saveStatisticsHeaderToString(pdb);
str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);

str(i:i+3)=typecast( uint32(numalgs),'uint8'); i=i+int32size;
str(i:i+3)=typecast( uint32(version),'uint8'); i=i+int32size;
str(i:i+3)=typecast( uint32(numpaths),'uint8'); i=i+int32size;

% Version 3 starts here

% Save number of points per fiber
points_per_fiber = ones(numpaths,1);
for as = 1:numpaths
    points_per_fiber(as) = length(fg.fibers{as});
end
temp = typecast( int32( points_per_fiber )','uint8');
str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);


%% Save the fibers
combined_fibers = cat(2,fg.fibers{:});
fiber_vector = reshape(combined_fibers, 1, []);
temp = typecast( double( fiber_vector ),'uint8');
str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);

% Save per fiber stat
for as = 1:numstats
    temp = typecast( double(fg.params{valid_stats(as)}.stat),'uint8');
    temp = temp(:)';  % Enforce row.  It once broke because some wrote a stat out as a column.
    str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);
end

%% Save per point stat
for as = 1:numstats
    if( pdb.pathway_statistic_headers(as).is_computed_per_point )
        if ~exist( 'combined_per_point_stat', 'var')
            if isempty(fg.pathwayInfo), combined_per_point_stats = zeros(numstats,1);
            else
                combined_per_point_stats = cat(2,fg.pathwayInfo.point_stat_array);
            end
        end
        temp = typecast( double( combined_per_point_stats(as,:)),'uint8');
        str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);
    end
end 

% What's this?
if i < MAX_SIZE,  str(i:MAX_SIZE)=[]; end

end