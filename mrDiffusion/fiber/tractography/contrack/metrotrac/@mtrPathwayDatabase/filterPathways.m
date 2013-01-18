function pdb_out = filterPathways(this,stat_index,value,type)
%Some uncommented Sherbondy code
%
%XXX type will specify >,<,== etc.
%
%
% Probably some Sherbondy thing.  No idea what it is.  Produces a hist()
% output, returns

pdb_out = mtrPathwayDatabase(this);
pdb_out.pathways = mtrPathwayStruct();

npaths = length(this.pathways);
count = 0;
valueV = zeros(1,npaths);

for p = 1:npaths
    curpath = this.pathways(p);
    if(curpath.path_stat_vector(stat_index) > value)        
        count = count+1;
        pdb_out.pathways(count) = curpath;
        valueV(count) = curpath.path_stat_vector(stat_index);
    end
end

hist(valueV)

return
