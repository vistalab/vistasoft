function udp_plotter_demo(lport)
% UDP_PLOTTER_DEMO - Opens a figure and starts to listen for UDP packages to plot.
% Syntax:
%   UDP_PLOTTER_DEMO
% or
%   UDP_PLOTTER_DEMO localport
%
% This script is a demo that listen for a UDP packet (default port 3333) and
% uses PLOT to dplay the sequence of doubles in the packet.
%
% (C) 2002 Peter Rydesaeter

% Add default argument
if nargin<1, lport=3333; end
% Write help message
disp ' ';
disp 'To send packages to be plotted use e.g.';
disp(sprintf('   Use:   udp_send_demo sin(0:0.1:6)  '));
disp 'or';
disp(sprintf('   Use:   udp_send_demo sin(0:0.1:6)  HOSTNAME'));
disp ' ';
disp 'To send a package to be plotted';
% Open figure window
fg=figure;
clf; axis; drawnow;
% Open  udpsocket and bind udp port adress to it.
udp=pnet('udpsocket',lport);
% Use timeout to not block forever, makes it possible to update resized window.
pnet(udp,'setreadtimeout',.1);
i=0;
try,
    while 1,
        stat=pnet(udp,'status');
        %if stat>=0 fprintf('Stat: %d\n', stat); end
        % Wait/Read udp packet to read buffer
        len=pnet(udp,'readpacket');
        %len=pnet(udp,'readpacket',[],'noblock');
        if len>0 fprintf('Len: %d\n', len); end

        if mod(i,500)==0 fprintf('%d\n',i); end
        i=i+1;
        if len>0,
            [ip,port]=pnet(udp,'gethost')
            % if packet larger then 1 byte then read maximum of 1000 doubles in network byte order
            data=pnet(udp,'read',1000,'double');
            figure(fg);
            % .... and plot doubles in axis.
            plot(data);
        end
        drawnow;
    end
catch,
    % On break or error close udpconnection and figure window.
    pnet('closeall');
    delete(fg);
    disp(lasterr);
end
% On break or error close udpconnection and figure window.
pnet(udp,'close');
delete(fg);
return;
