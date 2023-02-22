%
% Converts fibers to strings
%% 
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
function [str]=fiberToStr(fg, xformToAcPc, xform)

if(~exist('xformToAcPc','var'))
    xformToAcPc = eye(4);
end

if(exist('xform','var') && ~isempty(xform) && (isstruct(xform) || ~all(all(xform==eye(4)))))
    fg = dtiXformFiberCoords(fg, xform);
    xformToAcPc = xformToAcPc*inv(xform);
end
version = 2;

% Create blank database for finding some of the sizes to write out
pdb = mtrPathwayDatabase();
% PDB structure will have stat header info, but fg will retain the actual
% statistics per path to record
valid_stats=[];
numstats=0;
for ff=1:length(fg.params)
    try
        pdb = addStatisticHeader(pdb,fg.params{ff}.agg,fg.params{ff}.lname, fg.params{ff}.ile, fg.params{ff}.icpp, fg.params{ff}.ivs, fg.params{ff}.uid);
        valid_stats(numstats+1) = ff;
        numstats = numstats + 1;
    catch err
        disp('Warning: Invalid param ... skipping');fg.params{ff}
        err;
    end
end
numalgs = 0;
numpaths = length(fg.fibers);

% Redo offset
offset = 4*4 + 16*8 + numstats * getStatisticsHeaderSize(pdb) + numalgs * getAlgorithmsHeaderSize(pdb); % 4 uint, 16 doubles

%fiberToStrMex(fg, pdb, offset, 'asde', xformToAcPc);
% Save as string
%preallocated array
MAX_SIZE = 50000000;
str = zeros(1,MAX_SIZE,'uint8');
i = 1;
int32size   = size(typecast(int32(0),'uint8'),2);
double32size = size(typecast(double(0.0),'uint8'),2);

str(1:4) = typecast( uint32(offset),'uint8'); i=i+int32size;
temp = typecast( xformToAcPc(:)','uint8');
str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);

str(i:i+3)=typecast( uint32(numstats),'uint8'); i=i+int32size;

temp = saveStatisticsHeaderToString(pdb);
str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);

str(i:i+3)=typecast( uint32(numalgs),'uint8'); i=i+int32size;
str(i:i+3)=typecast( uint32(version),'uint8'); i=i+int32size;
str(i:i+3)=typecast( uint32(numpaths),'uint8'); i=i+int32size;

for ff = 1:numpaths
    % Record current file position to write later
    fileOffsets(ff) = i-1;%size(str,2);
    
    path_offset = 3 * 4  + numstats*8; % 4 int, numstats double
    nn = size( fg.fibers{ff}, 2 );    
    str(i:i+3)=typecast( int32(path_offset),'uint8'); i=i+int32size;
    str(i:i+3)=typecast( int32(nn),'uint8'); i=i+int32size;
    str(i:i+3)=typecast( int32(0),'uint8'); i=i+int32size;
    str(i:i+3)=typecast( int32(1),'uint8'); i=i+int32size;
    % algo type HACK % seedpointindex HACK ???
    
    % Write stats per path
    for as = 1:numstats
        temp = typecast( double(fg.params{valid_stats(as)}.stat(ff)),'uint8');
        str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);
    end 
    
    % Writing path nodes
    pos = fg.fibers{ff};
    %pos = mrAnatXformCoords(xformFromAcpc, pos')';
    % Change from 1 based to 0 based positions in mm space
    %pos = pos - repmat([2,2,2]',1,size(pos,2));
        temp = typecast( double(pos(:))','uint8');
        str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);
    
    % Writing stats values per position
    for as = 1:numstats
        % Just write garbage as fiber groups can't handle per point stats
        if( pdb.pathway_statistic_headers(as).is_computed_per_point )
            %error('Cannot export fiber group with per point statistics!');
            temp = typecast( double(fg.pathwayInfo(ff).point_stat_array(as,:)),'uint8');
            str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);
        end
    end   
end
temp = typecast( uint64(fileOffsets),'uint8');
str(i:i+size(temp,2)-1)=temp; i = i+size(temp,2);
if(i < MAX_SIZE)
    str(i:MAX_SIZE)=[];
end

end