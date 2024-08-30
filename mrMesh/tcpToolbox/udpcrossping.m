function udpcrossping(servermode, hostname, port)

count = 0;

% Open  udpsocket and bind udp port adress to it.
udp=pnet('udpsocket', port);

% Act as server or client?
if servermode
    % Server waits for echo-requests and then responds with his system
    % time:

    % Use timeout to not block forever, makes it possible to update resized window.
        while count < 1000
            % Wait/Read udp packet to read buffer
            len=pnet(udp,'readpacket');

            if len>0,
                % if packet larger then 1 byte then read maximum of 1 doubles in network byte order
                data=pnet(udp,'read',1,'double');
                %figure(fg);
                % .... and plot doubles in axis.
                %plot(data);
            end
            
            % Send reply:
            pnet(udp,'write', GetSecs);                % Write system time to write buffer
%            [ip,rport]=pnet(udp, 'gethost');
            pnet(udp,'writepacket', hostname, port);   % Send buffer as UDP packet
            
            % Increment count:
            count = count + 1;
        end

else
    % Client sends request, waits for answer, times roundtrip:
    localtime=zeros(1,1000);
    remotetime=zeros(1,1000);
    
    for i=1:1000
        % Send local time:
        pnet(udp,'write', GetSecs);                % Write system time to write buffer
        tpresend=GetSecs;
        pnet(udp,'writepacket', hostname, port);   % Send buffer as UDP packet
        tpostsend=GetSecs;
        tsent = (tpresend + tpostsend)/2;
        
        % Wait for response:
        len=pnet(udp,'readpacket');
        tpostreceive = GetSecs;
        
        roundtriptime = tpostreceive - tsent;
        
        if len>0,
            % if packet larger then 1 byte then read maximum of 1 doubles in network byte order
            remotetimesample=pnet(udp,'read',1,'double');
            %figure(fg);
            % .... and plot doubles in axis.
            %plot(data);
        end
        
        localtime(i)=tsent + 0.5 * roundtriptime;
        remotetime(i)=remotetimesample;
    end
end

% Close udp connection.
pnet(udp,'close');

if ~servermode
    % Absolute values:
    plot(localtime, remotetime);
    % Realtive values:
    figure;
    baseline = min(localtime, remotetime);
    plot(localtime - baseline, remotetime - baseline);
    
end

% End.
return;
