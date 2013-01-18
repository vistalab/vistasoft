function saveStatisticsHeader(this,fid)
% Saves statistics into a pathway database (PDB) file
%
%  saveStatisticsHeader(this,fid)
%
%
% There were no comments at all when I opened it.  Presumbly this is
% Sherbondy stuff. (BW)
%
% Stanford Vista Team

numstats = length( this.pathway_statistic_headers );

for s = 1:numstats
    statH = this.pathway_statistic_headers(s);
    fwrite(fid,statH.is_luminance_encoding,'int');
    fwrite(fid,statH.is_computed_per_point,'int');
    fwrite(fid,statH.is_viewable_stat,'int');
    
    numchars = length( statH.aggregate_name );
    for c = 1:min([numchars 255-1])
        fwrite(fid,statH.aggregate_name(c),'uchar');
    end
    fwrite(fid,char(0),'uchar');
    for c = min([numchars+2 255+1]):255
        fwrite(fid,'g','uchar');
    end
    
    numchars = length( statH.local_name );
    for c = 1:min([numchars 255-1])
        fwrite(fid,statH.local_name(c),'uchar');
    end
    fwrite(fid,char(0),'uchar');
    for c = min([numchars+2 255+1]):255
        fwrite(fid,'g','uchar');
    end
    
    % Must write UID so that it starts word aligned
    fwrite(fid,['g' 'g'],'uchar');
    
    fwrite(fid,statH.unique_id,'int');
    
    % Write garbage at end for word alignment
    %garb_size = getStatisticsHeaderSizeWordAligned(this) - getStatisticsHeaderSize(this);
    %garbV = zeros(1,garb_size);
    %fwrite(fid,garbV,'char');
end
 