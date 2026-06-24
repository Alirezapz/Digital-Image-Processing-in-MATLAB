# Digital Image Processing in MATLAB — DSP Lab Experiment

A self-contained MATLAB script covering core digital image processing techniques: histogram analysis & equalization, spatial-domain denoising (mean/median/FIR filters), the 2-D discrete wavelet transform, motion-blur simulation with Wiener deconvolution, and frequency-domain antialiasing/downsampling.

Built as part of the Digital Signal Processing laboratory course at Amirkabir University of Technology.

## Contents

- `EXP4_Image_Processing.m` — main script, organized into 5 independent sections
- `lena.bmp`, `Image02.jpg` — sample images used by the script
- `figures/` — example output figures (optional, see below)

## Topics Covered

| Section | Topic | Key functions used |
|---|---|---|
| 1 | Image fundamentals: I/O, histograms, equalization | `imread`, `imhist`, `histeq`, `im2double` |
| 2 | Denoising: Gaussian & salt-and-pepper noise | `imnoise`, `fspecial`, `imfilter`, `fir1`, `ftrans2`, custom median filter |
| 3 | 2-D Discrete Wavelet Transform | `dwt2`, `idwt2` (Haar / `db1`) |
| 4 | Motion blur & Wiener deconvolution | `fspecial('motion',...)`, `deconvwnr` |
| 5 | 2-D FFT, ideal low-pass filtering, antialiasing | `fft2`, `fftshift`, `downsample`, custom frequency-domain filter |

Two functions are implemented from scratch (not just wrapping built-ins), to demonstrate the underlying algorithms:

- **`my_median_filter(img, win_size)`** — manual sliding-window median filter with input validation and replicate-padded borders.
- **`FFT_LP_2D(input_image, cutoff_frequency)`** — ideal circular low-pass filter implemented directly via `fft2`/`fftshift`/`ifft2`.

## Requirements

- MATLAB R2016b or later (uses local functions inside a script file)
- Image Processing Toolbox
- Wavelet Toolbox (for `dwt2`/`idwt2`)
- Signal Processing Toolbox (for `fir1`, `ftrans2`, `freqz2`)

## Usage

```matlab
% 1. Clone the repo, or download the .m file + the two image files
% 2. Open MATLAB and set the Current Folder to the repo folder
%    (or run: cd('path/to/this/repo'))
% 3. Run the script
EXP4_Image_Processing
```

The script automatically locates its own folder and loads `lena.bmp` / `Image02.jpg` from there, so it runs correctly regardless of MATLAB's current working directory — no manual path editing needed.

All figures are generated and displayed as the script runs; a short text summary of each result is also printed to the command window.

## Example Results

| Salt & pepper noise removal (median filter) | Antialiasing before downsampling |
|---|---|
| <img width="1773" height="510" alt="median_filter_example" src="https://github.com/user-attachments/assets/c8bebc4d-0491-459f-b64f-be001df9d335" />| <img width="1451" height="526" alt="antialiasing_example" src="https://github.com/user-attachments/assets/5f29d71e-1fdb-4757-9853-47c5c0db9b4b" />|

*(see `figures/` for the full set of example outputs)*

## Notes on Design Choices

- **Replicate-padding in the custom median filter** vs. MATLAB's `medfilt2` (which zero-pads by default): the custom implementation avoids the slight bias zero-padding introduces near image borders.
- **NSR estimation for Wiener deconvolution** is computed from the *observed* (noisy/blurred) image's variance, not the clean original — matching how this would work in a real deblurring scenario where the original is unknown.
- **Antialiasing cutoff** is deliberately set below the new Nyquist frequency after downsampling (with a small safety margin), following the same principle as 1-D decimation theory.

## License

MIT — feel free to use, modify, and learn from this code.
