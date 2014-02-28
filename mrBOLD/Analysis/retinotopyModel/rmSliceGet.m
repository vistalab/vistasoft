function tmp = rmSliceGet(model,slice,id)
% rmSliceGet - extract slice from model struct and place it
% into temporary struct, also convert to single here.
%
% tmp = rmSliceGet(model,slice,id);
%
% 2008/01 SOD: extracted from rmGridFit.

if ~exist('model','var') || isempty(model), error('Need model'); end
if ~exist('slice','var') || isempty(slice), slice = 1;           end
if ~exist('id','var') || isempty(id),       id = 1:numel(model); end

% loop over models
tmp = cell(numel(id),1);
for n=id,
    f = {'x0','y0','s','x02','y02','s2','s_major','s_minor','s_theta','rss','rss2','rawrss','rawrss2', 'exponent'};

    % for all models
    tmp{n}.desc = rmGet(model{n},'desc');
    tmp{n}.df   = single(rmGet(model{n},'dfglm'));
    for fn = 1:numel(f),
        val    = rmGet(model{n},f{fn});
        if ~isempty(val),
            % switch on the number of dimensions, since inplane data has 
            % diff dimensionality than other views
            switch length(size(val)) 
                case 3 % presumably means INPLANE view, where slice is the third dimension
                    temp = single(val(:,:,slice));
                    tmp{n}.(f{fn}) = temp(:)';
                otherwise % otherwise slice is the first dimensions
                    tmp{n}.(f{fn}) = single(val(slice,:));                    
            end
        end;
    end;

    % put all beta values in one matrix
    val      = rmGet(model{n},'b');
    switch length(size(val)) % switch on the number of dimensions, since inplane data has diff dimesnsionality than other views
        case 4 % 4 dimensions means Inplane model: 
               %  3 dimensions of coords, and one dimension of beta values.
               %  Hence the dims are x, y, slice, betas. We want to make a
               %  matrix of betas for one slice. This matrix be 2-D, with
               %  one dimension indexing the x and y values (hence
               %  length x * y), and the other dimension representing the
               %  beta values (hence length size(val, 4))
            nbetas = size(val,4);
            nvoxelsPerSlice = size(val,2)*size(val,1);
            tmp{n}.b = zeros(nbetas,nvoxelsPerSlice,'single');
            for fn = 1:nbetas,
                temp  = single(val(:,:,slice,fn));
                tmp{n}.b(fn,:) = temp(:);
            end;
        otherwise
            tmp{n}.b = zeros(size(val,3),size(val,2),'single');
            for fn = 1:size(val,3),
                tmp{n}.b(fn,:) = single(val(slice,:,fn));
            end;
    end
end;

return;
