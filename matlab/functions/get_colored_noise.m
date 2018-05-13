function [ noise_mat, h_mat ] = get_colored_noise( L, M, N, params )
% Generate a matrix of colored noise samples

% Calc/Unpack Parameters 
L_M = L+M-1;
fstart = params.fstart;
fstop = params.fstop;
    
% Config Parameters 
w = 10;                 % Wind speed, m/s
s = 0.0;                  % Shipping activity [0,1]
Nfft = 256;             % Number of FFTs    
Nfilt = 100;            % Order of FIR filter
Nfreq = 10000;          % Number of points in PSD 




f = linspace(fstart,fstop,Nfreq);%FIXME
bw = fstop-fstart;

% Noise models, according to M. Stojanovic
Nw = 50+7.5*sqrt(w)+20*log10(f./1000)-40*log10((f./1000)+0.4);              % Wind
Ns = 40+20*(s-0.5) + 26*log10(f./1000) - 60*log10((f./1000)+0.3);           % Shipping
Nt = 17-30*log10(f./1000);                                  
Nth = -15+20*log10(f./1000);
Navg = 50-18*log10(f./1000);
Nsum = Nw+Nt+Nth;
Nsum = Navg;


% Generate the noise filter 


% Run AWGN through the filter (sum) 
x = (randn(L_M+Nfilt,N)+1j*randn(L_M+Nfilt,N))./sqrt(2);  %FIXME

% Sum
x_comb=x.*10^((max(Nsum)-1.5)/10);     %Change amplitude of noise to max value
[hd,nln_norm] = gen_filter_from_psd(Nsum,f,Nfilt,fstart,fstop);
y_comb=filter(hd.Numerator,1,x_comb);         %Must discard the first Nfilt/2 samples of the filter
y_comb=y_comb(Nfilt/2+1:Nfilt/2+L_M,:);
noise_mat = y_comb;

if (0)
    % Wind
    x_wind=x.*10^((max(Nw)-1.5)/10);     %Change amplitude of noise to max value
    [hd_wind,~] = gen_filter_from_psd(Nw,f,Nfilt,fstart,fstop);
    y_wind=filter(hd_wind,x_wind);         %Must discard the first Nfilt/2 samples of the filter
    y_wind=y_wind(Nfilt/2+1:Nfilt/2+L_M,:);

    % Ship
    x_ship=x.*10^((max(Ns)-1.5)/10);     %Change amplitude of noise to max value
    [hd_ship,~] = gen_filter_from_psd(Ns,f,Nfilt,fstart,fstop);
    y_ship=filter(hd_ship,x_ship);         %Must discard the first Nfilt/2 samples of the filter
    y_ship=y_ship(Nfilt/2+1:Nfilt/2+L_M,:);

    % Turb
    x_turb=x.*10^((max(Nt)-1.5)/10);     %Change amplitude of noise to max value
    [hd_turb,~] = gen_filter_from_psd(Nt,f,Nfilt,fstart,fstop);
    y_turb=filter(hd_turb,x_turb);         %Must discard the first Nfilt/2 samples of the filter
    y_turb=y_turb(Nfilt/2+1:Nfilt/2+L_M,:);

    % Therm
    x_therm=x.*10^((max(Nth)-1.5)/10);     %Change amplitude of noise to max value
    [hd_therm,~] = gen_filter_from_psd(Nth,f,Nfilt,fstart,fstop);
    y_therm=filter(hd_therm,x_therm);         %Must discard the first Nfilt/2 samples of the filter
    y_therm=y_therm(Nfilt/2+1:Nfilt/2+L_M,:);
    noise_mat = y_wind+y_ship+y_turb+y_therm;
end



% Create filter matrix
taps_vec = hd.numerator;
energy_taps = taps_vec.*20^(Nsum(1)/10);
h_mat = toeplitz([energy_taps],[energy_taps(1),zeros(1,L_M-1)]);



if (params.plotPsd)
    
%     % Use MATLAB's periodigram function to gen the PSD
%     yvec = reshape(noise_mat,numel(noise_mat),[]);
%     figure;periodogram(yvec,rectwin(length(yvec)),length(yvec));
    
    % Get the response of the filter we designed 
    [filt_resp,~]=freqz(hd,Nfreq);
    filt_db = 10*log10(abs(filt_resp));
    
    % Get PSDs
    [Sy_dbHz,fx] = calc_psd(noise_mat,Nfft,bw);
    [Sx_dbHz,~] = calc_psd(x_comb,Nfft,bw);
    fx = fx+fstart;

    
    % This figure compares the actual filter response to the target filter
    % response. 
    figure;
    plot(f,nln_norm,'LineWidth',2)
    hold on
    plot(f,filt_db,'r')
    title('Target filter response');
    ylabel('Attenuation (dB)')
    legend('Target','Actual')
    
    % This figure compares the acutal PSD of the filtered noise samples to
    % the target PSD. 
    figure;
    plot(fx,Sx_dbHz,'LineWidth',2)
    hold on
    plot(fx,Sy_dbHz,'g')
    plot(f,Nsum,'r')
    title('PSD of Filtered Noise')
    legend('Filter Input (AWGN)', 'Filter Output (Colored)', 'Target')
    ylabel('dB re uPa per Hz')
    
    
    
end



end

