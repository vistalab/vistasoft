function this = addStatistic(this,agg_name,local_name, ile, icpp, ivs, uid,val,valarray)

if( exist( 'ile','var' ) )
    this = addStatisticHeader(this,agg_name,local_name, ile, icpp, ivs, uid);
else
    this = addStatisticHeader(this,agg_name,local_name, ile, icpp, ivs, uid);
end

npaths = length( this.pathways );
for p = 1:npaths
    if( exist('val','var') )
        if( isempty( this.pathways(p).path_stat_vector ) )
            this.pathways(p).path_stat_vector = val(p);
            this.pathways(p).point_stat_array = valarray(p,:);
        else
            this.pathways(p).path_stat_vector(end+1) = val(p);
            this.pathways(p).point_stat_array(end+1,:) = valarray(p,:);
        end
    else
        if( isempty( this.pathways(p).path_stat_vector ) )
            this.pathways(p).path_stat_vector = zeros( size(this.pathways(p).path_stat_vector) );
            this.pathways(p).point_stat_array = zeros( size(this.pathways(p).point_stat_array) );
        else
            this.pathways(p).path_stat_vector(end+1) = zeros( size(this.pathways(p).path_stat_vector) );
            this.pathways(p).point_stat_array(end+1,:) = zeros( size(this.pathways(p).point_stat_array) );
        end
    end
end
