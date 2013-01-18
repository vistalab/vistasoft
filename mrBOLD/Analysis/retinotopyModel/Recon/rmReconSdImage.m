function images = rmReconSdImage(images)

    % Scales for the blurring-kernel
    %   a step-size of 0.0063 is optimal, but requires a lot of memory
    %
    scale = 0.5:0.1:1.5; % in degrees of visual field
    
    for imindex = 1:numel(images)
        
            disp(sprintf('[%s]: Image #%d',mfilename,imindex));
         
            % Initialize local vars
            [imageheight,imagewidth] = size(images(imindex).grayscale); % Only works for square images atm
            
            diameter = imageheight;

            pxperdeg = imageheight / 18; % 18 depends on the visual field size, suitable for 7T only!
            scale = scale * pxperdeg;    
            diameterinc = diameter / length(scale);            
% 
%             % create circle-filters
%             for scindex = 1:length(scale)
%                 
%                 disp(sprintf('[%s]: Image #%d: creating circle-filters, scale = %d',mfilename,imindex,scale(scindex)));
%                 
%                 imblur(scindex) = blurImages(images(imindex).grayscale,scale(scindex));
% 
%                 imblur(scindex).circle = makecircle(diameter - (scindex * diameterinc) + diameterinc,imageheight);            
%             end    
                                
%             % calculate circle image for this position and each scale
%             for scindex = 1:length(scale)
% 
%                 disp(sprintf('[%s]: Image #%d: applying circle-filters, scale = %d',mfilename,imindex,scale(scindex)));
% 
%                 circleimage = zeros(imageheight,imageheight,'single');                    
%                 tmpimage = zeros(imageheight,imagewidth,'single');
% 
%                 circlemask = imblur(scindex).circle;
%                 tmpimage = circlemask .* imblur(scindex).sd;
%                 tmpimage = single(real(tmpimage));
% 
%                 if(scindex > 1)
%                    pos = tmpimage > 0;
%                    circleimage(pos) = tmpimage(pos);
%                 else
%                    circleimage = tmpimage; 
%                 end
% 
%             end    
            
            images(imindex).sdimage = circleimage;
            
            clear imblur
    end
    