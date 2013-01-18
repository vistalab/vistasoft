function hdrString = dumpIfileHeader2Cell(iFileName)

 [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = GE_readHeader(iFileName);
 
 % for now, we just dump the im_hdr
 
 fn = fieldnames(im_hdr);
 hdrString = '';
 for i=1:length(fn)
     h = [fn{i}, '='];
     eval(['val = im_hdr.',fn{i},';']);
     if(length(val)>1)
         % hack to find strings
         if(findstr('name',fn{i}))
             h = [h, sprintf('%s', char(val(:)'))];
         else
            h = [h, sprintf('%d,', val(:)')];
            % chop the trailing comma
            h = h(1:end-1);
        end
     else
         hdrString{i}= [h,sprintf('%d', val)];
     end
     %hdrString{i} = [hdrString{i}, '\n'];
 end
 