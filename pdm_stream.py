import sounddevice as sd
import time
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import lfilter, firwin
from scipy import signal
import librosa

def pdm(x):
    n = len(x)
    y = np.zeros(n)
    error = np.zeros(n+1)
    for i in range(n):
        y[i] = 1 if x[i] >= error[i] else -1
        error[i+1] = y[i] - x[i] + error[i]
    return y, error[0:n]

sampling_rate = 2500000
print("load test wav file")
y, sr = librosa.load("CantinaBand3.wav", sr=44200, mono=1)
wav_lenght = int(y.size/sr)
fig, ax = plt.subplots(nrows=2, sharex=True)
librosa.display.waveshow(y, sr=sr, ax=ax[0])
ax[0].set(title='Envelope view,44200Hz sample rate, mono')
ax[0].label_outer()

print("interpolate it to 2.5Mhz sampling rate")
t = np.linspace(0,wav_lenght, 44200*wav_lenght)
tt = np.linspace(0, wav_lenght, sampling_rate*3)
yy = np.interp(tt, t, y)
ax[1].set(title='Resample to 2.5MHz')
librosa.display.waveshow(yy, sr=sampling_rate, ax=ax[1])
pdm_sig, error = (pdm(yy))

f = open("pdm.txt", "w")
for x in pdm_sig:
    if (x == -1):
      f.writelines('-1' + "\n")
    else:
      f.writelines('1' + "\n")
f.close()

plt.show()
