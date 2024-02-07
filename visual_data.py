import sounddevice as sd
import time
import numpy as np
#from bitstring import BitArray
import matplotlib.pyplot as plt
from scipy.signal import lfilter, firwin

def read_file_plot(name_file):
 file1 = open(name_file, 'r')
 Lines = file1.readlines()

 count = 0
 a = []
 for line in Lines:
    count += 1
    print("Line{}: {}".format(count, line.strip()))
    #value = BitArray(bin=line).int
    value = int(line, 2)
    a.append(value)
    #print(value)

 #print(a)
 t = np.arange(len(a))
 plt.plot(t, a, label='input signal')
 #plt.step(1e9*t, y, label='pdm signal',  linewidth=2.0)
 #plt.step(1e9*t, error, label='error')
 plt.xlabel('Time (ns)')
 plt.legend()
 plt.show()

read_file_plot('output_results.txt')
read_file_plot('output_results_dec.txt')
