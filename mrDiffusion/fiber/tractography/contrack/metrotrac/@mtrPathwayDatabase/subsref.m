function b = subsref(this,index)
% SUBSREF Define field name indexing for DTIPathwayDatabase objects

switch index(1).type
    case '.'
        switch index(1).subs
            case 'pathways'
                if length(index)== 1
                    b = this.pathways;
                else
                    % Pass this call to the one for DTIPathway
                    b = subsref(this.pathways,index(2:end));
                end
            case 'pathwaysCoords'
                if length(index)== 1
                    b = this.pathwaysCoords;
                else
                    % Pass this call
                    b = subsref(this.pathwaysCoords,index(2:end));
                end
            case 'pathway_statistic_headers'
                if length(index)== 1
                    b = this.pathway_statistic_headers;
                else
                    % Pass this call to the one for DTIPathway
                    b = subsref(this.pathway_statistic_headers,index(2:end));
                end
            case 'mm_scale'
                if length(index)== 1
                    b = this.mm_scale;
                else
                    % Pass this call to the one for DTIPathway
                    b = subsref(this.mm_scale,index(2:end));
                end
            case 'scene_dim'
                if length(index)== 1
                    b = this.scene_dim;
                else
                    % Pass this call to the one for DTIPathway
                    b = subsref(this.scene_dim,index(2:end));
                end
            case 'ACPC'
                if length(index)== 1
                    b = this.ACPC;
                else
                    % Pass this call to the one for DTIPathway
                    b = subsref(this.ACPC,index(2:end));
                end
        end

end