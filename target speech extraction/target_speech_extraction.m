close all 
clear all 
fclose('all');

[x1, Fs] = audioread('mixture1_set2.wav');
[x2, Fs] = audioread('mixture2_set2.wav');
[x3, Fs] = audioread('mixture3_set2.wav');

[phi,lags] = xcorr(x3, x1); % TDOA for mic1 and mic3

% Convert sample lags to time
time = lags / Fs;

d = 0.25;
c = 343;

max_tau = d/c; % maximun TODA

t = time/2;
zoomIndex = (t >= -max_tau) & (t <= max_tau);
[~, measured_tdoas] = findpeaks(phi(zoomIndex), t(zoomIndex));

figure(1)
plot(t,phi)
ylabel('cross-correlation')
xlabel('time (seconds)')
xlim([-max_tau, max_tau]);

format long
disp(measured_tdoas)

fft_size = 500;
Wbf = zeros(3,fft_size);
for bin = 0:1:fft_size/2-1
    w = Fs*bin*2*pi/fft_size;
    D_target = [1,exp(-sqrt(-1)*w*measured_tdoas(2)),exp(-sqrt(-1)*w*2*measured_tdoas(2))].';
% steering vertor of the target source

    D_noise1 = [1,exp(-sqrt(-1)*w*measured_tdoas(1)),exp(-sqrt(-1)*w*2*measured_tdoas(1))].';
    D_noise2 = [1,exp(-sqrt(-1)*w*measured_tdoas(3)),exp(-sqrt(-1)*w*2*measured_tdoas(3))].';
% steering vertor of the interferences

    R = D_noise1 * D_noise1' + D_noise2 * D_noise2';
%pseudo-coherence matrix

    regularization_value = 1.5e-2;
    R_regularized = R + regularization_value * eye(size(R));

    H = (inv(R_regularized)) * D_target / (D_target' * (inv(R_regularized)) * D_target);
    Wbf(:,bin+1) = H;
end

for bin = 1:1:fft_size/2
    Wbf(:,fft_size-bin+1) = conj(Wbf(:,bin));
end

v_sound= c;
fs = Fs;
mic_spacing = d;
N = 3;

% compute and plot beampattern at specific frequency
f_for_beampattern=1000.0; % Hz
bin_for_beampattern=1+round(f_for_beampattern/fs*fft_size);
nb_angles=3600;
beampattern=zeros(1,nb_angles);
for angle_index=0:1:nb_angles-1
    taus=(0:1:N-1)*mic_spacing/v_sound*cos(angle_index/nb_angles*2*pi);
    D_propag_freq=exp(-sqrt(-1)*2*pi*f_for_beampattern*taus).';
    beampattern(angle_index+1)=abs(Wbf(:,bin_for_beampattern)'*D_propag_freq).^2;
end

figure(2) % polar beampattern
angles_for_beampattern=[0:1:nb_angles-1,0]/nb_angles*360; % copy last entry for looping in polar plot
beampattern(nb_angles+1)=beampattern(1); % copy last entry for looping in polar plot
handles= polardb(angles_for_beampattern/180*pi, 10*log10(beampattern), -20, 'k-' );
beampattern=beampattern(1:end-1); % remove added last entry
set(handles, 'LineWidth', 2 );
s=sprintf('beampattern, f=%0.2f Hz',f_for_beampattern);
title(s); 

figure(3) % rectangular beampattern
angles_for_beampattern=(0:1:nb_angles-1)/nb_angles*360-180; % -180 to 180
plot(angles_for_beampattern, max(-100,fftshift(10*log10(beampattern)))); % from -180 to 180
grid on
grid minor
ax=axis;
axis([-180 180 -80 25]);
ylabel('mag. response (dB)')
xlabel('azimuth (degrees)')
s=sprintf('beampattern, f=%0.2f Hz',f_for_beampattern);
title(s); 

 m = -fft_size/2+1:1:fft_size/2;
 figure(4)
 subplot(3,1,1)
 plot(m,abs(fftshift(Wbf(1,:))));
 title('beamformer filter(mag frequency response) for mic#1')
 ylabel('magnitude response')
 xlabel('k')
 subplot(3,1,2)
 plot(m,abs(fftshift(Wbf(2,:))));
 title('beamformer filter(mag frequency response) for mic#2')
 ylabel('magnitude response')
 xlabel('k')
 subplot(3,1,3)
 plot(m,abs(fftshift(Wbf(1,:))));
 title('beamformer filter(mag frequency response) for mic#3')
 ylabel('magnitude response')
 xlabel('k')

Wbt = real(ifft(Wbf').');
Wbt(1,:) = fftshift(Wbt(1,:));
Wbt(2,:) = fftshift(Wbt(2,:));
Wbt(3,:) = fftshift(Wbt(3,:));
n = 0:1:fft_size-1;

 figure(5)
 subplot(3,1,1)
 plot(n/fs,Wbt(1,:));
 title('beamformer filter(impulse response) for mic#1')
 ylabel('amplitude')
 xlabel('time (seconds)')
 subplot(3,1,2)
 plot(n/fs,Wbt(2,:));
 title('beamformer filter(impulse response) for mic#2')
 ylabel('amplitude')
 xlabel('time (seconds)')
 subplot(3,1,3)
 plot(n/fs,Wbt(3,:));
 title('beamformer filter(impulse response) for mic#3')
 ylabel('amplitude')
 xlabel('time (seconds)')
 
 Yn = filter(Wbt(1,:),1,x1)+filter(Wbt(2,:),1,x2)+filter(Wbt(3,:),1,x3);%beamformer output
 Yn = Yn / max(abs(Yn)); %% Normalize to [-1, 1]
 audiowrite('beamformer_output.wav', Yn, Fs);

IS = 2;
Y = MMSESTSA85(Yn,fs,IS); % extracted signal after the post-filtering process
audiowrite('single_channel_speech_enhancement_output.wav', Y, Fs);

% Evaluate the performance of the "post-filtering part" using dataset#2
[S1, Fs] = audioread('source1_set2.wav');
[S2, Fs] = audioread('source2_set2.wav');
[S3, Fs] = audioread('source3_set2.wav');
sources = [S1,S2,S3].';
target_index = 2;
out = Y.';
M = 3;

cor=xcorr(out,sources(target_index,:),2*fft_size); 
[~,ind]=max(abs(cor));
lag=ind-(2*fft_size+1);
fprintf(1,'lag=%d\n',lag);
% align the signals
minlen=min(length(out),length(sources(target_index,:)));
out_tmp=out(lag+1:minlen);
sources_tmp=sources(:,1:minlen-lag);

[SDR,ISR,SIR,SAR,perm]=bss_eval_images([out_tmp;randn(M-1,length(out_tmp))],sources_tmp);
SDR=SDR(target_index);
fprintf('\n results with logmmsespu2 post-filtering\n')
display(SDR)
SIR=SIR(target_index);
display(SIR)