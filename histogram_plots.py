
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
plt.style.use('seaborn-white')
data1 = pd.read_csv('condition15_corr_wholebrain_ICC.csv')
data2 = pd.read_csv('condition18_corr_wholebrain_ICC.csv')
data3 = pd.read_csv('condition1_corr_wholebrain_ICC.csv')

params = {'mathtext.default': 'regular' }          

plt.rcParams.update(params)

kwargs = dict(histtype='stepfilled', alpha=0.7, bins=60)

plt.ylabel('Counts', fontweight='bold')
plt.xlabel('ICC', fontweight='bold')

plt.hist(data1, **kwargs,color ='gold')
plt.hist(data2, **kwargs,color ='darkkhaki')
plt.hist(data3, **kwargs,color ='beige');

plt.tick_params(axis='y', labelsize=11)
plt.tick_params(axis='x', labelsize=11)

plt.show()
