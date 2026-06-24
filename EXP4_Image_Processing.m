%% DSP Lab - Experiment 4 (Image Processing)
% Sections: 1) basics/histograms  2) denoising  3) wavelets
%           4) motion blur + Wiener  5) antialiasing/downsampling
%
% Images needed in the same folder: lena.bmp, Image02.jpg
% (handout also mentions Image03.png/Image04.png/glass.tif but those
% weren't provided, so lena/Image02 get reused across sections - see
% comments below for which image goes where)

clear; clc; close all;

%% ---- Section 1: basics, histogram, equalization ----

img_lena = imread('lena.bmp');   % uint8 by default

figure; imshow(img_lena);
title('Original Lena');
% (no colorbar here - doesn't mean anything on an RGB image)

disp(class(img_lena));
disp(size(img_lena));

% handout calls this "double2im" but the actual function is im2double
img_lena_d = im2double(img_lena);

if size(img_lena,3) == 3
    img_gray = rgb2gray(img_lena);
else
    img_gray = img_lena;
end

figure;
subplot(1,2,1); imshow(img_lena); title('RGB');
subplot(1,2,2); imshow(img_gray); title('Grayscale');

% histogram
figure;
imhist(img_gray);
title('Histogram - Lena (grayscale)');
xlabel('intensity'); ylabel('count');

fprintf('mean = %.2f, std = %.2f\n', mean(double(img_gray(:))), std(double(img_gray(:))));

% histeq: remaps intensities so the cumulative histogram is roughly
% a straight line -> flattens out the histogram, boosts contrast.
% useful on images where the dynamic range isn't being used well
% (classic case: x-rays, foggy/hazy photos, anything low-contrast)
img_eq = histeq(img_gray);

figure;
subplot(1,2,1); imshow(img_gray); title('Before');
subplot(1,2,2); imshow(img_eq);   title('After histeq');

figure;
subplot(1,2,1); imhist(img_gray); title('Histogram before');
subplot(1,2,2); imhist(img_eq);   title('Histogram after');

% Why isn't the equalized histogram flat? Because we're working with
% integers (0-255), not continuous values. The "perfectly uniform"
% result is a continuous-domain result. With discrete levels you get
% a stair-step CDF - some input levels get merged into the same output
% bin (gaps in the histogram), others get dumped into one bin because
% of rounding (spikes). So you get *approximately* uniform, not exact.


%% ---- Section 2: denoising ----

img02 = imread('Image02.jpg');
if size(img02,3) == 3
    img02 = rgb2gray(img02);
end
img02 = im2double(img02);

figure; imshow(img02); title('Image02 original');

% --- gaussian noise, sigma = 0.2 ---
img02_g = imnoise(img02, 'gaussian', 0, 0.2^2);

figure;
subplot(1,2,1); imshow(img02);   title('Original');
subplot(1,2,2); imshow(img02_g); title('+ Gaussian noise (\sigma=0.2)');

% 3x3 mean filter
k3 = fspecial('average', [3 3]);
img02_m3 = imfilter(img02_g, k3, 'replicate');

figure;
subplot(1,3,1); imshow(img02_g);  title('Noisy');
subplot(1,3,2); imshow(img02_m3); title('Mean 3x3');

% Averaging N=9 roughly independent noise samples cuts the noise
% variance by ~9x (1/N scaling for iid noise). Trade-off is you're
% also averaging across whatever edges happen to fall in the window,
% so you lose sharpness.

% 5x5 for comparison - more averaging = more noise reduction
% (1/K^2 roughly) but proportionally more blur too. Classic trade-off,
% no free lunch here.
k5 = fspecial('average', [5 5]);
img02_m5 = imfilter(img02_g, k5, 'replicate');

figure;
subplot(1,3,1); imshow(img02_g);  title('Noisy');
subplot(1,3,2); imshow(img02_m3); title('Mean 3x3');
subplot(1,3,3); imshow(img02_m5); title('Mean 5x5 - more blur');

% --- salt & pepper, p = 0.1 ---
img02_sp = imnoise(img02, 'salt & pepper', 0.1);

figure;
subplot(1,2,1); imshow(img02);    title('Original');
subplot(1,2,2); imshow(img02_sp); title('Salt & pepper p=0.1');

img02_sp_m3 = imfilter(img02_sp, k3, 'replicate');
figure;
subplot(1,2,1); imshow(img02_sp);    title('S&P noisy');
subplot(1,2,2); imshow(img02_sp_m3); title('After 3x3 mean - not great');

% mean filter basically smears the salt/pepper spikes into a halo
% instead of removing them - since the bad pixels are 0 or 1 (extreme
% values), they drag the local average way off no matter how small
% their fraction of the window is. linear filters just aren't the
% right tool for impulse noise.

% --- 1D FIR -> 2D via ftrans2, compare freq responses ---
h1 = fir1(20, 0.5);            % order 20, cutoff at 0.5 (Nyquist=1)
h2 = ftrans2(h1);               % McClellan transform -> circularly symmetric 2D filter

figure;
freqz(h1, 1, 512);             % freqz draws its own layout, give it its own figure

[H2, fx, fy] = freqz2(h2, 64, 64);
figure;
mesh(fx, fy, abs(H2));
xlabel('f_x / \pi'); ylabel('f_y / \pi'); zlabel('|H|');
title('2D FIR response (from ftrans2)');

img02_g_fir = imfilter(img02_g, h2, 'replicate');
img02_sp_fir = imfilter(img02_sp, h2, 'replicate');

figure;
subplot(1,3,1); imshow(img02_g);      title('Noisy');
subplot(1,3,2); imshow(img02_m3);     title('Mean 3x3');
subplot(1,3,3); imshow(img02_g_fir);  title('2D FIR');

figure;
subplot(1,3,1); imshow(img02_sp);     title('S&P noisy');
subplot(1,3,2); imshow(img02_sp_m3);  title('Mean 3x3');
subplot(1,3,3); imshow(img02_sp_fir); title('2D FIR');

% the FIR filter has a sharper cutoff than the boxy mean filter so it
% keeps a bit more mid-frequency detail, but it's still linear/lowpass
% so it has the exact same problem with salt & pepper as the mean
% filter - just blurs the spikes in a slightly different shape.

% --- custom median filter (see my_median_filter at bottom of file) ---
img02_sp_med  = my_median_filter(img02_sp, 3);
img02_sp_med2 = medfilt2(img02_sp, [3 3]);   % compare vs built-in

figure;
subplot(1,4,1); imshow(img02);        title('Original');
subplot(1,4,2); imshow(img02_sp);     title('S&P noisy');
subplot(1,4,3); imshow(img02_sp_med); title('My median filter');
subplot(1,4,4); imshow(img02_sp_med2);title('medfilt2');

d = max(abs(img02_sp_med(:) - img02_sp_med2(:)));
fprintf('max diff vs medfilt2 = %.6f\n', d);
% they match in the interior. small differences can show up near the
% border because medfilt2 zero-pads by default and mine replicates -
% replicate is arguably the better choice there, zero padding biases
% the median toward darker values right at the edge.
%
% why median works on S&P: it's a robust statistic. as long as less
% than half the window is corrupted, the salt/pepper values get pushed
% to the ends of the sorted list and never picked - so the noise gets
% rejected outright instead of just averaged down like with a mean
% filter.

img02_g_med = medfilt2(img02_g, [3 3]);

figure;
subplot(2,3,1); imshow(img02_g);      title('Gaussian noisy');
subplot(2,3,2); imshow(img02_m3);     title('Mean 3x3');
subplot(2,3,3); imshow(img02_g_med);  title('Median 3x3');
subplot(2,3,4); imshow(img02_sp);     title('S&P noisy');
subplot(2,3,5); imshow(img02_sp_m3);  title('Mean 3x3');
subplot(2,3,6); imshow(img02_sp_med2);title('Median 3x3');

% mean = linear, always blurs an edge a bit even with zero noise
% present, because it just averages whatever's in the window.
% median = nonlinear, reproduces a clean step edge almost exactly
% since the median of a mostly-one-sided window equals that side's
% value. better edge preservation, basically.
%
% median's downsides: slower (needs a sort per pixel), eats small
% thin features if the window is bigger than them, and can leave
% blocky/staircase-y edges on smooth diagonals since it only ever
% outputs a value that was already in the window (no interpolation).


%% ---- Section 3: 2D wavelet transform ----

img_w = im2double(rgb2gray(imread('lena.bmp')));

[cA, cH, cV, cD] = dwt2(img_w, 'db1');   % db1 = Haar, simplest case

figure;
subplot(2,2,1); imshow(mat2gray(cA)); title('cA - approx (LL)');
subplot(2,2,2); imshow(mat2gray(cH)); title('cH - horiz detail (LH)');
subplot(2,2,3); imshow(mat2gray(cV)); title('cV - vert detail (HL)');
subplot(2,2,4); imshow(mat2gray(cD)); title('cD - diag detail (HH)');

% cA: lowpass both directions -> smoothed half-size version of the image
% cH: lowpass rows, highpass cols -> lights up on HORIZONTAL edges
% cV: highpass rows, lowpass cols -> lights up on VERTICAL edges
% cD: highpass both -> diagonal stuff + texture + noise
% each subband is ~half the size in each dim because of the downsample
% by 2 after filtering.
fprintf('original %dx%d, subband %dx%d\n', size(img_w,1), size(img_w,2), size(cA,1), size(cA,2));

% Highlighting horizontal edges: cH already does this by construction,
% so two options -
%  (1) zero out everything except cH and reconstruct -> pure edge map
%  (2) boost cH before reconstructing, keep the rest -> enhancement
%      that's actually more useful in practice than (1)
cA0 = zeros(size(cA)); cV0 = zeros(size(cV)); cD0 = zeros(size(cD));
img_h_only = idwt2(cA0, cH, cV0, cD0, 'db1');

gain = 4;
img_h_boost = idwt2(cA, gain*cH, cV, cD, 'db1');
img_h_boost = mat2gray(img_h_boost);

figure;
subplot(2,2,1); imshow(img_w);               title('Original');
subplot(2,2,2); imshow(mat2gray(cH));        title('cH');
subplot(2,2,3); imshow(mat2gray(img_h_only));title('Reconstructed from cH only');
subplot(2,2,4); imshow(img_h_boost);         title('cH boosted x4');


%% ---- Section 4: motion blur + Wiener deconvolution ----

img04 = im2double(imread('Image02.jpg'));
if size(img04,3) == 3
    img04 = rgb2gray(img04);
end

psf = fspecial('motion', 15, 20);   % 15px, 20 deg
img04_b = imfilter(img04, psf, 'conv', 'circular');
% circular boundary to match what deconvwnr assumes later

figure;
subplot(1,2,1); imshow(img04);   title('Original');
subplot(1,2,2); imshow(img04_b); title('Motion blurred');

% restore with Wiener, no noise added yet - try a few NSR values
img04_w0   = deconvwnr(img04_b, psf, 0);      % NSR=0 -> pure inverse filter
img04_w001 = deconvwnr(img04_b, psf, 0.001);
img04_w01  = deconvwnr(img04_b, psf, 0.01);

figure;
subplot(2,2,1); imshow(img04_b);    title('Blurred');
subplot(2,2,2); imshow(img04_w0);   title('NSR=0');
subplot(2,2,3); imshow(img04_w001); title('NSR=0.001');
subplot(2,2,4); imshow(img04_w01);  title('NSR=0.01');

% since there's actually no noise here, NSR=0 (= straight inverse
% filtering) gives essentially perfect recovery. Bumping NSR up from
% there just makes the filter more conservative for no reason, so the
% result gets progressively softer than it needs to be.

% now add noise and redo it - this is the more realistic case
noise_var = 10 / 255^2;     % "variance 10" on 0-255 scale -> normalize
img04_bn = imnoise(img04_b, 'gaussian', 0, noise_var);

figure;
subplot(1,3,1); imshow(img04);   title('Original');
subplot(1,3,2); imshow(img04_b); title('Blurred');
subplot(1,3,3); imshow(img04_bn);title('Blurred + noisy');

% estimate NSR from the *observed* image (not the clean original,
% which you wouldn't actually have access to in a real situation)
nsr_est = noise_var / var(img04_bn(:));
fprintf('estimated NSR = %.5f\n', nsr_est);

img04_r0   = deconvwnr(img04_bn, psf, 0);
img04_rest = deconvwnr(img04_bn, psf, nsr_est);
img04_rhi  = deconvwnr(img04_bn, psf, 0.05);

figure;
subplot(2,2,1); imshow(img04_bn);   title('Blurred+noisy (input)');
subplot(2,2,2); imshow(img04_r0);   title('NSR=0 - blows up');
subplot(2,2,3); imshow(img04_rest); title(sprintf('NSR=%.4f (estimated)', nsr_est));
subplot(2,2,4); imshow(img04_rhi);  title('NSR=0.05 - over-smoothed');

% NSR=0 with real noise present is a disaster - the inverse filter has
% huge gain wherever |H(f)| is small (motion-blur PSFs have deep nulls
% in their spectrum), and that's exactly where noise dominates the
% signal, so you mostly just amplify noise instead of recovering
% anything. The estimated NSR gives the best balance; going too high
% over-smooths and leaves blur behind that didn't need to be there.


%% ---- Section 5: antialiasing / downsampling ----

I = im2double(rgb2gray(imread('lena.bmp')));

figure; imshow(I); title('Original');

F = fftshift(fft2(I));
logmag = log(1 + abs(F));
ph = angle(F);

figure;
subplot(1,2,1); imshow(logmag, []); title('log|FFT|'); colormap(gca,'hot'); colorbar;
subplot(1,2,2); imshow(ph, []);     title('phase');    colormap(gca,'hsv'); colorbar;

% fft2 puts DC at (1,1) and wraps around at the edges (periodic, by
% construction of the DFT). fftshift just rolls the array so DC lands
% in the middle - matches how everyone actually wants to look at a
% spectrum, low freq in the center, Nyquist out at the edges/corners.

% ideal circular lowpass, see FFT_LP_2D() at the bottom
I_lp1 = FFT_LP_2D(I, 0.3*pi);
I_lp2 = FFT_LP_2D(I, 0.1*pi);

figure;
subplot(1,3,1); imshow(I);     title('Original');
subplot(1,3,2); imshow(I_lp1); title('cutoff 0.3\pi');
subplot(1,3,3); imshow(I_lp2); title('cutoff 0.1\pi');

% lower cutoff = more blur, obviously (throwing away more spectrum).
% also worth noting: there's visible ringing near edges because an
% ideal brick-wall filter has a sinc-ish impulse response in the
% spatial domain - sharp cutoff in frequency = slow decay + ripples
% in space, can't have one without the other.

% downsample by 2, no filtering first
I_ds = downsample(downsample(I,2).', 2).';

% same thing but lowpass first, cutoff below the new Nyquist (pi/2)
% with a bit of margin since the filter isn't perfectly ideal
I_pre = FFT_LP_2D(I, 0.4*pi);
I_ds_aa = downsample(downsample(I_pre,2).', 2).';

figure;
subplot(1,3,1); imshow(I);       title('Original');
subplot(1,3,2); imshow(I_ds);    title('Downsampled, no filtering');
subplot(1,3,3); imshow(I_ds_aa); title('Downsampled, with AA filter');

% the no-filter version shows aliasing pretty clearly in the textured
% hair region - jagged/moire-ish pattern that isn't actually in the
% original. classic case of high frequencies folding back into the
% baseband because we didn't respect the new (halved) Nyquist rate
% before throwing samples away. filtering first fixes it, same as in
% 1D - decimate only after lowpass filtering below the new Nyquist.

Fo  = log(1+abs(fftshift(fft2(I))));
Fds = log(1+abs(fftshift(fft2(I_ds))));
Flp = log(1+abs(fftshift(fft2(I_pre))));
Fdsa= log(1+abs(fftshift(fft2(I_ds_aa))));

figure;
subplot(2,2,1); imshow(Fo,[]);   title('Original spectrum');
subplot(2,2,2); imshow(Fds,[]);  title('Downsampled (no AA)');
subplot(2,2,3); imshow(Flp,[]);  title('After AA filter');
subplot(2,2,4); imshow(Fdsa,[]); title('Downsampled (with AA)');

fprintf('done.\n');


%% ===== local functions (must go at the end in a script file) =====

function out = my_median_filter(img, win_size)
% MY_MEDIAN_FILTER  manual 2D median filter, no medfilt2 used.
%   out = my_median_filter(img, win_size)
%   win_size must be an odd positive integer.

    if win_size <= 0 || win_size ~= round(win_size)
        error('win_size must be a positive integer');
    end
    if mod(win_size, 2) == 0
        error('win_size must be odd');
    end

    cls = class(img);
    img = double(img);
    [r, c] = size(img);
    half = (win_size-1)/2;

    padded = padarray(img, [half half], 'replicate');
    out = zeros(r, c);

    for i = 1:r
        for j = 1:c
            win = padded(i:i+win_size-1, j:j+win_size-1);
            out(i,j) = median(win(:));
        end
    end

    if strcmp(cls, 'uint8')
        out = uint8(out);
    elseif strcmp(cls, 'uint16')
        out = uint16(out);
    end
    % otherwise leave as double
end


function out = FFT_LP_2D(img, cutoff)
% FFT_LP_2D  ideal circular lowpass filter in the frequency domain.
%   out = FFT_LP_2D(img, cutoff)   cutoff in rad, range [0, pi]
%
% Builds a circular mask centered on the shifted spectrum: 1 inside
% radius cutoff/pi (normalized to Nyquist along the shorter image
% dimension), 0 outside. Exact/isotropic for square images.

    if cutoff < 0 || cutoff > pi
        error('cutoff must be in [0, pi]');
    end

    img = im2double(img);
    [M, N] = size(img);

    [u, v] = meshgrid(-floor(N/2):ceil(N/2)-1, -floor(M/2):ceil(M/2)-1);
    D = sqrt(u.^2 + v.^2) / (min(M,N)/2);
    H = double(D <= cutoff/pi);

    Fs = fftshift(fft2(img));
    out = real(ifft2(ifftshift(H .* Fs)));
end
