function this = loadStatisticsHeader(this,fid,numstats)

this.pathway_statistic_headers = [];
for s = 1:numstats
    is_luminance_encoding = fread(fid,1,'char');
    is_computed_per_point = fread(fid,1,'char');
    is_viewable_stat = fread(fid,1,'char');
    agg_name = fread(fid,255,'char');
    local_name = fread(fid,255,'char');
    uid = fread(fid,1,'uint');
    this = addStatisticHeader(this,agg_name,local_name,is_luminance_encoding, is_computed_per_point, is_viewable_stat, s);
    % Read garbage at end for word alignment
    garb_size = getStatisticsHeaderSizeWordAligned(this) - getStatisticsHeaderSize(this);
    foo = fread(fid,garb_size,'char');
end