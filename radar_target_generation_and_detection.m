clear all
clc;

%% Radar Specifications 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Frequency of operation = 77GHz
% Max Range = 200m
% Range Resolution = 1 m
% Max Velocity = 100 m/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%speed of light = 3e8
%% User Defined Range and Velocity of target
%Note : Velocity remains contant

targetRange    = 110; % Initial Position in metre
targetVelocity = -20; % Intial Velocity in m/s 

%% FMCW Waveform Generation

dres     = 1;                           % range resolution in m
c        = 3e8;                         % speed of light in m/s
maxRange = 200;                         % maximum range of the radar

Bsweep   = c / (2* dres);               % Bandwidth
Tchirp   = 5.5 * (2 * maxRange  / c);   % chirp time in sec
slope    = Bsweep / Tchirp;             % Slope of the FMCW

%Operating carrier frequency of Radar 
fc= 77e9;             %carrier freq in Hz
                                                          
%The number of chirps in one sequence. 
%Its ideal to have 2^ value for the ease of running the FFT for Doppler Estimation. 
Nd=128;                   % #of doppler cells OR #of sent periods % number of chirps

%The number of samples on each chirp. 
Nr=1024;                  %for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples


%Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx=zeros(1,length(t)); %transmitted signal
Rx=zeros(1,length(t)); %received signal
Mix = zeros(1,length(t)); %beat signal

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));


%% Signal generation and Moving Target simulation
% Running the radar scenario over the time. 

for i=1:length(t)         
    
    %For each time stamp update the Range of the Target for constant velocity.   
    r_t(i) = targetRange + targetVelocity * t(i);
    
    % Time delay calculation based on the range 
    td(i) = 2*r_t(i) / c;   % time = distance / speed of light - here distance is twice the range for Tx and Rx
    
    %For each time sample we need update the transmitted and
    %received signal. 
    Tx(i) = cos(2 * pi * ( fc * t(i)       + 0.5 * slope * t(i)^2));
    Rx(i) = cos(2 * pi * ( fc *(t(i)-td(i))+ 0.5 * slope *(t(i)-td(i))^2));
    

    %Now by mixing the Transmit and Receive generate the beat signal
    %This is done by element wise matrix multiplication of Transmit and Receiver Signal
    Mix(i) = Tx(i).*Rx(i);
    
end

%% RANGE MEASUREMENT

%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.

Mix=reshape(Mix,[Nr,Nd]);

% Length of the Signal
Length = Tchirp * Bsweep;

% FFT on the beat signal along the range bins dimension (Nr) and
%normalize.
signal_fft = fft(Mix,Nr);

% absolute value of FFT output
signal_fft = abs(signal_fft/Length);

% Output of FFT is double sided signal, but we are interested in only one side of the spectrum.
% Hence we throw out half of the samples.
signal_fft = signal_fft(1:(Length/2)+1);

% plot FFT output 
f = Bsweep*(0:(Length/2))/Length;
figure('Name','FFT Output')
plot(f,signal_fft)

%plotting the range
Range = (c * Tchirp * f) / (2 * Bsweep);
figure ('Name','Range from First FFT')

plot(Range,signal_fft)

axis ([0 200 0 0.25]);
%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map.You will implement CFAR on the generated RDM


% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift (sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions
doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);
figure,surf(doppler_axis,range_axis,RDM);

%% CFAR implementation

%Slide Window through the complete Range Doppler Map

%Select the number of Training Cells in both the dimensions.

Tr = 10;
Td = 8;

%Select the number of Guard Cells in both dimensions around the Cell under 
%test (CUT) for accurate estimation
Gr = 4;
Gd = 4;

% offset the threshold by SNR value in dB
offset = 6;

% New Array to store CFAR values
% If this is not used, then updated RDM CUT Cells value will impact the
% noise level calcualtion when we slide to next cells iteratively
CFAR = zeros(size(RDM));

% *%TODO* :
%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.

for i = (Tr + Gr + 1) : (Nr/2 - (Tr + Gr))
    for j = (Td + Gd + 1) : (Nd - (Td + Gd))
    
        %Create a vector to store noise_level for each iteration on training cells
        noise_level = zeros(1,1);
        % Use RDM[x,y] as the matrix from the output of 2D FFT for implementing CFAR
        % Compute sum of RDM in each training cell
        for p = i-(Tr+Gr): i+Tr+Gr
            for q = j-(Td+Gd):j+Td+Gd
                if ((abs(i-p) > Gr) || (abs(j-q) > Gd)) % ignore gaurd cells
                    noise_level = noise_level + db2pow(RDM(p,q));                    
                end                
            end
        end
        
        % Find the average Noise value and add offset
        threshold = pow2db(noise_level / (2*(Td+Gd+1)*2*(Tr+Gr+1)-(Gr*Gd)-1));
        threshold = threshold + offset;
        
        CUT = RDM(i,j);
        
        % Compare the test cell with the threshold
        % If above threshold, Set signal to 1 else 0
        if(CUT > threshold)     
            CFAR(i,j) = 1;
        else
            CFAR(i,j) = 0;
        end
        
    end
end


% *%TODO* :
% The process above will generate a thresholded block, which is smaller 
%than the Range Doppler Map as the CUT cannot be located at the edges of
%matrix. Hence,few cells will not be thresholded. To keep the map size same
% set those values to 0. 

% Implementer Notes: As a new CFAR array was created with Initial value as Zero this stpe is not necessary

%display the CFAR output using the Surf function like we did for Range Doppler Response output.
figure,surf(doppler_axis,range_axis,CFAR);
colorbar;


 
 