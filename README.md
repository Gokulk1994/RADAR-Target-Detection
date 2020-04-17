# RADAR-Target-Generation and Detection

## Udacity Sensor Fusion Nanodegree

### Goal

The main goal of this project is Generation and Detection of a target. 

Detecion includes both Range and Velocity estimation using FFT and CFAR thresholding techniques in MATLAB.

### Specification of RADAR

- Frequency of operation = 77GHz
- Max Range = 200m
- Range Resolution = 1 m
- Max Velocity = 100 m/s

### Calculated FMCW  Waveform Parameters

- Bandwidth :150000000.000000
- Chirp Time:0.000007
- Slope     :20454545454545.453125

### 2D CFAR Process

- Choose the number of Train and Guard cells. These cells around the Cell under test(CUT) forms a 2D matrix.
- Slide across the complete matrix around a CUT. 
- Leave a margin for Training and Guard cells from both the edges.
- For every CUT, sum the signal level within all the corresponding training cells. 
- Aggregation of Signal values is possible only if the values are converted from logarithmic to linear using db2pow function.
- Average the summed values for all of the training cells and convert it back to logarithmic using pow2db.
- Add an offset to it to determine the final threshold.
- Compare the signal value of CUT against this threshold.
- if CUT is greater than threshold, assign signal value as 1 else 0 
- Set CFAR values at both edges where a margin is created initially as 0

### Selection of Training, Guard cells and offset


Number of Guard Cells in both dimensions around the Cell under test (CUT) for accurate estimation
- #Guard cells in Range Dimension Gr = 4
- #Guard Cells in Doppler Dimension Gd = 4

Number of Training Cells in both the dimensions around the Guard Cells.
- #Training cells in Range Dimension   Tr = 10
- #Training Cells in Doppler Dimension Td = 8

offset the threshold by SNR value in dB
- offset = 6

### Steps taken to suppress the non-thresholded cells at the edges

As a margin is created from the edges during 2D CFAR process, the output will be smaller than the Range Doppler map (RDM).
Hence few cells will not be thresholded. Inorder to ensure output from CFAR to be of same size **Zero Padding** from edges till the start of the margin should be done.

In this implementation a new array is created with initial value as 0 to store the CFAR value, which ensures the cells outside the margins has zero signal value by default.

### Output Images

#### 1. Output of FFT
![FFT Output](/images/FFTOutput.png)

#### 2. Output of Range FFT
![Range FFT](/images/RangeFFT.png)

#### 3. Range Doppler Map
![RDM](/images/RDM.png)

#### 4. CFAR Output
![CFAR](/images/CFAR.png)





