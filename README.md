# FMCW mmWave Radar DSP using BGT60TR13C

This project focuses on Digital Signal Processing (DSP) using the Infineon BGT60TR13C and MATLAB to understand how FMCW radar detects human motion, velocity, range, and angle. The project processes raw radar ADC data and converts it into meaningful radar information using FFT-based signal processing techniques. The implementation is designed in a simple and beginner-friendly way to understand practical mmWave radar DSP.

Two different radar datasets are used in this project. In the first dataset, a person stands static at around 30° angle from the radar for studying Direction of Arrival (DOA) estimation and range response. In the second dataset, the same person walks parallel to the radar for Doppler and motion analysis. By comparing both datasets, the radar response for static and moving targets can be clearly observed.

The MATLAB implementation starts with loading raw radar data and separating signals from the three receiver antennas. Hilbert Transform is used to generate the complex radar signal required for FMCW processing. The signal then passes through Range FFT for distance estimation and Doppler FFT for velocity estimation. These outputs are combined to generate the Range-Doppler Map for motion visualization.

For angle estimation, the project uses the MUSIC algorithm with a 3-element Uniform Linear Array (ULA). The covariance matrix is generated from the detected target bin, and the MUSIC spectrum is used to estimate the Direction of Arrival (DOA) of the target.

The project generates several radar visualization plots including:
- Range Profile
- Range-Doppler Map
- MUSIC DOA Spectrum

Overall, this project serves as a beginner-friendly implementation for learning FMCW radar DSP concepts such as Range FFT, Doppler FFT, beamforming, DOA estimation, target detection, and radar visualization using real mmWave radar data from the BGT60TR13C sensor.
