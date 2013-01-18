function this = set(this,varargin)

% SET Set mutation properties to the specified values
% and return the updated object

propertyArgIn = varargin;
while length(propertyArgIn) >= 2,
    prop = propertyArgIn{1};
    val = propertyArgIn{2};
    propertyArgIn = propertyArgIn(3:end);
    switch prop
        case 'mm_scale'
            this.mm_scale = val;
        case 'scene_dim'
            this.scene_dim = val;
        case 'ACPC'
            this.ACPC = val;
    otherwise
        error('Invalid property')
    end
end