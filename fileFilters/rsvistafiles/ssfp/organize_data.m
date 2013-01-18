function [Raw_data Im_data] = organize_data(A, Frames)
% function [Raw_data Im_data] = organize_data(A, Frames);
%
%	Function reads selected data from a P-file
%
%
%	INPUT:
%		fname   = P file name.
%	    Frames  = Number of temporal frames collected
%
%	EXAMPLE:
%	  [R I] = organize_data('P00000.7',101);	% Read full p-file
%
%	Thomas S. John -- Feb 2009.
%
Frames_per_echo = 10; 

[RO PE Echo Slices_per_echo] = size(A);
Slices_per_frame = Slices_per_echo/Frames_per_echo;

C = zeros([PE Slices_per_frame]);
Raw_data = zeros([RO PE Slices_per_frame Frames]);
Im_data = zeros([RO PE Slices_per_frame Frames]);

% for m=1:Frames
%         
%         %Determine which echo the mth frame is stored in
%         echo = floor((m-1)/Frames_per_echo)+1;
%     for f = 1:Frames_per_echo
%         %Go to echo and sift out mth frame from it. Stored as B
%         B(:,:,:) = A(:,:,echo,(f-1)*Slices_per_frame+1:f*Slices_per_frame);
%         
%         %Raw_data(:,:,:,m) = ifftshift(ifftn(B));
%         %Do Z-FFT on slices of mth frame. Stored as D
%         for k=1:PE
%             C(:,:) = B(k,:,:);
%             Raw_data(k,:,:,m) = ifftcr(C);
%         end
%          
%     end
% end

for m=1:Echo

    for f=1:Frames_per_echo
        frame_no = (m-1)*Frames_per_echo + f;
        if (frame_no > Frames)
            break
        end
        %Go to echo and sift out each frame from it. Stored as B
        first_sl_pos = (f-1)*Slices_per_frame+1;
        last_sl_pos = f*Slices_per_frame;
        B(:,:,:) = A(:,:,m,first_sl_pos:last_sl_pos);

        for k=1:RO
            C(:,:) = B(k,:,:);
            Raw_data(k,:,:,frame_no) = ifftcr(C);
        end

    end

    if (frame_no > Frames)
        break
    end
    
end