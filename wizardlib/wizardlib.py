
import platform
import torch
import os


def getPlatform():
    plt = platform.system()
    if plt=='Darwin':
        return 'mac'
    return plt

def hasGPU(plt:str):
    if plt == 'mac':
        return torch.backends.mps.is_available()
    return torch.cuda.is_available()
    
def getDevice(plt:str):
    if plt == 'mac':
        return torch.device('mps')
    return torch.device('cuda')

def disableTokenizerParallelization():
    os.environ["TOKENIZERS_PARALLELISM"] = "false"

def disableWarnings() :
    import warnings
    warnings.filterwarnings("ignore", category=UserWarning, module="transformers.utils.generic")
    warnings.filterwarnings("ignore", category=UserWarning, module="trl.trainer.ppo_config")
    warnings.filterwarnings("ignore", message="torch.utils.checkpoint: please pass in use_reentrant=True or use_reentrant=False explicitly")
