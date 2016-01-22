function model = rmSliceSet(model,tmp,slice)
% rmSliceSet - put slice info into model struct
% we convert back to double precision here.
%
% model = rmSliceSet(model,tmp,slice);
%
% 2008/01 SOD: extracted from rmGridFit.

% loop over models
for n=1:numel(model),
    % variables may have slightly different names
    ftmp   = {'x0','y0','s','x02','y02','s2','s_major','s_minor','s_theta','rss','rss2','rsspos','rssneg','rawrss','rawrss2', 'exponent'};

    % now get values from model and put in new slice values
    for fn = 1:numel(ftmp),
        % check whether data exists and has data in tmp structure
        if isfield(tmp{n},ftmp{fn}) && ~isempty(tmp{n}.(ftmp{fn}))
            % get data from model structure
            val = rmGet(model{n},ftmp{fn});
            % if no data in model structure make it (zeros)
            if isempty(val)
                val = zeros(size(rmGet(model{n},'x0')));
            end
            % now put data in model structure format
            switch length(size(val))
                case 3 % presumably means INPLANE view, where slice is the third dimension
                    data = reshape(double(tmp{n}.(ftmp{fn})), size(val,1), size(val,2));
                    val(:,:,slice) = data;
                otherwise
                    if size(val,2) == size(tmp{n}.(ftmp{fn}),2)
                        val(slice,:)  = double(tmp{n}.(ftmp{fn}));
                    elseif slice == 1 && size(val,2) ~= size(tmp{n}.(ftmp{fn}),2)
                        val = double(tmp{n}.(ftmp{fn}));
                    end
            end
            % save data in model
            model{n}      = rmSet(model{n},ftmp{fn},val);
        end
    end

    % other params
    if isfield(tmp{n},'df')
        model{n}       = rmSet(model{n},'dfglm',double(tmp{n}.df));
    end
    if isfield(tmp{n},'desc')
        model{n}       = rmSet(model{n},'desc',tmp{n}.desc);
    end

    % distribute beta values
    val = rmGet(model{n},'b');
    switch length(size(val)) 
        % switch on the number of dimensions, since inplane data has diff
        % dimesnsionality than other views
        case 4 % 4 dimensions means Inplane model:
            %  3 dimensions of coords, and one dimension of beta values.
            %  Hence the dims are x, y, slice, betas.
            nbetas = size(val,4);            
            %tmp{n}.b = zeros(nbetas,nvoxelsPerSlice,'single');
            for fn = 1:nbetas,
                data = reshape(double(tmp{n}.b(fn,:)), size(val,1), size(val,2));
                val(:,:,slice,fn) = data;
            end;
            
        otherwise            
            val = val(:,:,1:size(tmp{n}.b,1));
            for fn = 1:size(val,3),
                val(slice,:,fn) = double(tmp{n}.b(fn,:));
            end;
    end
    model{n} = rmSet(model{n},'b',val);
end;
return;
%-----------------------------------
