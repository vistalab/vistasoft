function hdrString = dumpIfileHeader2Sting(iFileName)

 [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = GE_readHeader(iFileName);
 
 % for now, we just dump the im_hdr
 
 fn = fieldnames(im_hdr);
 hdrString = '';
 for i=1:length(fn)
     hdrString = [hdrString, fn{i}, '='];
     eval(['val = im_hdr.',fn{i},';']);
     if(length(val)>1)
         % hack to find strings
         if(findstr('name',fn{i}))
             hdrString = [hdrString, sprintf('%s', char(val(:)'))];
         else
            hdrString = [hdrString, sprintf('%d,', val(:)')];
            % chop the trailing comma
            hdrString = hdrString(1:end-1);
        end
     else
         hdrString = [hdrString, sprintf('%d', val)];
     end
     hdrString = [hdrString, '\n'];
 end
 