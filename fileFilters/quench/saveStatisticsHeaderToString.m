function [str] = saveStatisticsHeaderToString(this)

numstats = length( this.pathway_statistic_headers );
int32size   = size(typecast(int32(0),'uint8'),2);
MAX_SIZE = (numstats+1)*(int32size*5+512);
i=1;
str = zeros(1,MAX_SIZE,'uint8');
for s = 1:numstats
    statH = this.pathway_statistic_headers(s);
    str(i:i+3)=typecast( int32(statH.is_luminance_encoding),'uint8'); i=i+int32size;
    str(i:i+3)=typecast( int32(statH.is_computed_per_point),'uint8'); i=i+int32size;
    str(i:i+3)=typecast( int32(statH.is_viewable_stat),'uint8'); i=i+int32size;
        
    % Save aggregate name
    numchars = length( statH.aggregate_name );
    str(i:i+numchars-1)=statH.aggregate_name; i=i+numchars;
    str(i)=0; i = i+1;
    for c = min([numchars+2 255+1]):255
        str(i)='g';
        i=i+1;
    end
    
    % Save local name
    numchars = length( statH.local_name );
    str(i:i+numchars-1)=statH.local_name; i=i+numchars;
    str(i)=0; i = i+1;
    for c = min([numchars+2 255+1]):255
        str(i)='g';
        i=i+1;
    end
    
    % Must write UID so that it starts word aligned
    str(i) = 'g';i=i+1;
    str(i) = 'g';i=i+1;
    
    str(i:i+3)=typecast( int32(statH.unique_id),'uint8'); i=i+int32size;
    
    % Write garbage at end for word alignment
    %garb_size = getStatisticsHeaderSizeWordAligned(this) - getStatisticsHeaderSize(this);
    %garbV = zeros(1,garb_size);
    %fwrite(fid,garbV,'char');
end
 
if(i < MAX_SIZE)
    str(i:MAX_SIZE)=[];
end
 
