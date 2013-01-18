function this = subsasgn(this,index,val)
% SUBSASGN Define index assignment for DTIPathway objects

switch index(1).type
    case '()'
        if length(index)== 1
            this(index(1).subs{:}) = val;
        else
            this(index(1).subs{:}) = subsasgn( this(index(1).subs{:}),index(2:end),val );
        end
    case '.'
        switch index(1).subs
            case 'pathways'
                if length(index)== 1
                    this.pathways = val;
                else
                    switch index(2).type
                        case '()'
                            if( length(index) == 2 )
                                this.pathways(index(2).subs{:}) = val;
                            else
                                switch index(3).type
                                    case '.'
                                        switch index(3).subs
                                            case 'path_stat_vector'
                                                if length(index) == 3
                                                    this.pathways(index(2).subs{:}).path_stat_vector = val;
                                                else
                                                    switch index(4).type
                                                        case '()'
                                                            this.pathways(index(2).subs{:}).path_stat_vector(index(4).subs{:}) = val;
                                                    end
                                                end
                                        end
                                end
                            end
                    end
                end
            case 'mm_scale'
                if length(index)== 1
                    this.mm_scale = val;
                else
                    switch index(2).type
                        case '()'
                            this.mm_scale(index(2).subs{:}) = val;
                    end
                end
            case 'scene_dim'
                if length(index)== 1
                    this.scene_dim = val;
                else
                    switch index(2).type
                        case '()'
                            this.scene_dim(index(2).subs{:}) = val;
                    end
                end
            case 'ACPC'
                if length(index)== 1
                    this.ACPC = val;
                else
                    switch index(2).type
                        case '()'
                            this.ACPC(index(2).subs{:}) = val;
                    end
                end
            case 'pathway_statistic_headers'
                if length(index)== 1
                    this.pathway_statistic_headers = val;
                else
                    switch index(2).type
                        case '()'
                            this.pathway_statistic_headers(index(2).subs{:}) = val;
                    end
                end

            otherwise
                error('Invalid field name')
        end
end