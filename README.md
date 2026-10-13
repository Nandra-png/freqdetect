# freqdetect

Flutter app that listens through the mic and reports the dominant frequency in real time. Built for a hackathon — the original idea was a tuner for keroncong instruments.

## What it does

Streams PCM from the microphone, runs a 1024-point FFT every frame, finds the strongest bin, and interpolates to Hz. Shows the spectrum as a live curve plus the peak frequency and nearest musical note.

## Accuracy

Tested against pure sine waves at 44100 Hz sample rate:

```
target  440 Hz   detected  440.6 Hz   error 0.6
target 1000 Hz   detected 1000.6 Hz   error 0.6
target  250 Hz   detected  249.4 Hz   error 0.6
silence          detected    0.0 Hz
```

0.6 Hz error is the bin width at this FFT size, and parabolic interpolation on the peak gets it under that.

## FFT

Written from scratch in `lib/services/fft.dart`. Radix-2 Cooley-Tukey, iterative, bit-reversal permutation up front. Hann window applied before the transform to cut spectral leakage. Output converted to dB and normalized to the peak so the plot auto-scales.

Peak detection skips the first two bins (DC and the low-frequency bin that DC leaks into) and picks the maximum. A quadratic fit across the peak and its neighbors gives sub-bin resolution.

## Running

```
flutter pub get
flutter run
```

Needs a device with a microphone. Windows desktop and Android both work.

## Notes

- sample rate is fixed at 44100, the stream is requested at that rate
- `record` package returns PCM16 little-endian, converted to float in `_keDouble`
- if the signal is below -60 dB the app reports 0 Hz instead of guessing
- note names use the standard MIDI mapping, A4 = 440 Hz

## What's missing

- no smoothing, so the readout jitters on noisy input
- no calibration for a reference pitch
- doesn't handle polyphonic input, only reports the strongest peak
- no recording or export
