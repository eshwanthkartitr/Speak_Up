import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Create the DataFrame from the data
data = {
    'epoch': [1, 5, 10, 15, 20, 25, 30],
    'No Preprocessing': {
        'loss': [2.491368, 2.128137, 2.081101, 2.049871, 2.021986, 1.998126, 1.975821],
        'pesq': [1.110734, 1.102173, 1.112359, 1.175780, 1.116488, 1.101073, 1.093451],
        'stoi': [0.346368, 0.498465, 0.558566, 0.489353, 0.477006, 0.470012, 0.450168]
    },
    'MelSEGAN + VMD + VAD': {
        'loss': [2.584934, 2.233211, 2.177864, 2.136796, 2.102346, 2.073838, 2.046205],
        'pesq': [1.088980, 1.108260, 1.101254, 1.102191, 1.100971, 1.093437, 1.127178],
        'stoi': [0.438488, 0.400358, 0.447792, 0.450923, 0.424635, 0.499560, 0.454808]
    },
    'MelSEGAN + VMD + DTW': {
        'loss': [2.131643, 1.736059, 1.696551, 1.672895, 1.654387, 1.640318, 1.629985],
        'pesq': [1.099543, 1.079158, 1.092555, 1.144524, 1.097848, 1.075867, 1.091959],
        'stoi': [0.595579, 0.597671, 0.614402, 0.640441, 0.627221, 0.616389, 0.616779]
    },
    'MelSEGAN + VMD + DTW + MAML': {
        'loss': [1.811897, 1.475650, 1.442068, 1.421961, 1.406229, 1.394270, 1.385487],
        'pesq': [1.319452, 1.294990, 1.311066, 1.373429, 1.317418, 1.291040, 1.310351],
        'stoi': [0.536021, 0.537904, 0.552962, 0.576397, 0.564499, 0.554750, 0.555101]
    },
    'MelSEGAN + VAD + VMD + MAML': {
        'loss': [1.938700, 1.674908, 1.633398, 1.602597, 1.576759, 1.555378, 1.534654],
        'pesq': [1.143429, 1.163673, 1.156317, 1.157301, 1.156020, 1.148109, 1.183537],
        'stoi': [0.306942, 0.280251, 0.313454, 0.315646, 0.297244, 0.349692, 0.318366]
    },
    'UNet + HiFigan + VMD + VAD': {
        'loss': [1.943267, 1.659947, 1.623259, 1.598899, 1.577149, 1.558538, 1.541140],
        'pesq': [1.277344, 1.267499, 1.279213, 1.352147, 1.283961, 1.266234, 1.257469],
        'stoi': [0.374077, 0.538342, 0.603251, 0.528501, 0.515166, 0.507613, 0.486181]
    },
    'UNet + HiFigan + VMD + DTW': {
        'loss': [1.793785, 1.532259, 1.498393, 1.475907, 1.455830, 1.438651, 1.422591],
        'pesq': [1.332881, 1.322608, 1.334831, 1.410936, 1.339786, 1.321288, 1.312141],
        'stoi': [0.387932, 0.558281, 0.625594, 0.548075, 0.534247, 0.526413, 0.504188]
    }
}

# Set the style for better visualization
plt.style.use('default')
plt.rcParams['figure.figsize'] = (15, 20)
plt.rcParams['axes.grid'] = True
plt.rcParams['grid.alpha'] = 0.3
plt.rcParams['font.size'] = 12
plt.rcParams['axes.titlesize'] = 14
plt.rcParams['axes.labelsize'] = 12
plt.rcParams['legend.fontsize'] = 10

# Create a figure with subplots
fig, axes = plt.subplots(3, 1, figsize=(15, 20))
fig.suptitle('Training Metrics Comparison', fontsize=16, y=0.95)

# Define colors and line styles
colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2']
line_styles = ['-', '-', '-', '-', '-', '--', '--']  # Dashed lines for UNet variants

metrics = ['loss', 'pesq', 'stoi']
titles = ['Training Loss', 'PESQ Score', 'STOI Score']
ylabels = ['Loss', 'PESQ', 'STOI']

for idx, (metric, title, ylabel) in enumerate(zip(metrics, titles, ylabels)):
    for i, (model, values) in enumerate(data.items()):
        if model != 'epoch':
            axes[idx].plot(data['epoch'], values[metric], 
                         label=model, 
                         linewidth=2, 
                         color=colors[i-1],
                         linestyle=line_styles[i-1])
    
    axes[idx].set_title(title, pad=15)
    axes[idx].set_xlabel('Epoch')
    axes[idx].set_ylabel(ylabel)
    axes[idx].grid(True)
    axes[idx].legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    axes[idx].set_xlim(0, 30)

# Adjust layout and display
plt.tight_layout()
plt.subplots_adjust(right=0.85, hspace=0.3)
plt.savefig('training_metrics_comparison.png', dpi=300, bbox_inches='tight')
plt.show()

# Print summary statistics
print("\nFinal Metrics (at Epoch 30):")
print("-" * 80)
print(f"{'Model':<30} {'Loss':>10} {'PESQ':>10} {'STOI':>10}")
print("-" * 80)
for model, values in data.items():
    if model != 'epoch':
        print(f"{model:<30} {values['loss'][-1]:>10.3f} {values['pesq'][-1]:>10.3f} {values['stoi'][-1]:>10.3f}")
print("-" * 80) 