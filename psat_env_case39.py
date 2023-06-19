# -*- encoding: utf-8 -*-
'''
@File    :   psat_env_case39.py
@Time    :   2023/06/16 14:36:11
@Author  :   Thueea_bcb 
@Version :   1.0
@Contact :   thueea_bcb@outlook.com
@License :   (C)Copyright 2017-2022, Tsinghua Univ
@Desc    :   None
'''

# here put the import lib
from distutils.log import error
import matlab
import matlab.engine
import numpy as np
from array import array
import os

class psat_env_case39(object):
    def __init__(self, idx):
        # 初始化系统的路径和当前的案例
        self.currentFolder = os.getcwd()
        self.case_idx = idx 
        self.eng = matlab.engine.start_matlab()

        self.FaultSettingsPath = self.currentFolder + '\FaultSettings.txt'
        self.ActionPath = self.currentFolder + '\pert_control.m'
        self.DataFolderPath = self.currentFolder + '\data'

    def reset(self, idx):
        # 状态定义为各个节点和电动机的功率注入，以及电动机的滑差
        self.action = []
        # 清理掉pert文件的设置
        with open(self.ActionPath, 'r', encoding='utf-8') as f:
            control_data = f.readlines()\
        # 目前的切负荷还是按照比例走的，对应于电动机切多少
        for i in range(len(control_data)):
            if control_data[i].__contains__('Pl.con(LoadsheddingBus,[5:10])'):
                control_data[i] = '% Pl.con(LoadsheddingBus,[5:10]) = [0.8;0.8;0.8].*Pl_store(LoadsheddingBus,[5:10]);      % cut load precentage\n'
            elif control_data[i].__contains__('Ind_store(LoadsheddingBus,15)'):
                control_data[i] = '% Ind.dat(LoadsheddingBus,1) = [0.2;0.2;0.2;].*Ind_store(LoadsheddingBus,15);             % cut ind precentage\n'
            else:
                pass
        with open(self.ActionPath, 'w', encoding='utf-8') as f:
            f.writelines(control_data)
        self.case_idx = idx
        [state, PQstore, PVstore, Plstore, Indstore] = self.eng.psat_getstate(idx, nargout=5)
        self.state, self.PQstore, self.PVstore, self.Plstore, self.Indstore = state, PQstore, PVstore, Plstore, Indstore
        return state, PQstore, PVstore, Plstore, Indstore

    def step(self, action, FaultIndex):
        # 根据当前的应对策略和故障集进行仿真验证
        # 修改pert文件的设置
        self.action = action
        with open(self.ActionPath, 'r', encoding='utf-8') as f:
            control_data = f.readlines()
        # 目前的切负荷还是按照比例走的，对应于电动机切多少
        LoadsheddingBus = [4,7,18]
        str_act = '['
        for i in range(len(action)):
            str_act = str_act + str(1 - action[i]) +';'
        str_act = str_act + ']'
        for i in range(len(control_data)):
            if control_data[i].__contains__('LoadSheddingAmount = '):
                str_cl = 'LoadSheddingAmount = ' + str_act + ';\n'
                control_data[i] = str_cl
            else:
                pass
        with open(self.ActionPath, 'w', encoding='utf-8') as f:
            f.writelines(control_data)
        # ref: fault_set = [3,4,5,6,7,8,12,15,16,17,18] in case settings
        fault_set = [3,4,5,6,7,8,12,15,16,17,18]
        if FaultIndex > len(fault_set)+1:
            error('Input fault index exceeds limit!')
        # 写入pert文件
        [state_n, reward, PQstore, PVstore, Plstore, Indstore] = self.eng.psat_step(self.case_idx, FaultIndex, nargout=6) # nargout=2
        return state_n, reward, PQstore, PVstore, Plstore, Indstore

    def step_wstate(self, PQstore, PVstore, Plstore, Indstore, action, FaultIndex):
        # 根据当前的应对策略和故障集进行仿真验证
        error('经过验证需要更复杂的设置，目前暂未载入...')
        # 修改pert文件的设置
        self.action = action
        with open(self.ActionPath, 'r', encoding='utf-8') as f:
            control_data = f.readlines()
        # 目前的切负荷还是按照比例走的，对应于电动机切多少
        str_act = '['
        for i in range(len(action)):
            str_act = str_act + str(action[i]) +';'
        str_act = str_act + ']'
        for i in range(len(control_data)):
            if control_data[i].__contains__('LoadSheddingAmount = '):
                str_cl = 'LoadSheddingAmount = ' + str_act + ';\n'
                control_data[i] = str_cl
            else:
                pass
        with open(self.ActionPath, 'w', encoding='utf-8') as f:
            f.writelines(control_data)
        # ref: fault_set = [3,4,5,6,7,8,12,15,16,17,18] in case settings
        fault_set = [3,4,5,6,7,8,12,15,16,17,18]
        if FaultIndex > len(fault_set)+1:
            error('Input fault index exceeds limit!')
        # 写入pert文件
        [state_n, reward, PQstore, PVstore, Plstore, Indstore] = self.eng.psat_step_wstate(self.case_idx, FaultIndex, PQstore, PVstore, Plstore, Indstore, nargout=6) # nargout=2
        return state_n, reward, PQstore, PVstore, Plstore, Indstore

    def closepenv(self):
        self.eng.exit()

if __name__ == '__main__':
    # 建立环境
    env = psat_env_case39(idx=0)

    obs_val, PQstore, PVstore, Plstore, Indstore = env.reset(idx=1)
    action = [0.2,0.2,0.2]
    obs_val = np.array(obs_val._data)
    print(obs_val)

    obs_val_n, reward, PQstore, PVstore, Plstore, Indstore = env.step(action, FaultIndex=1)
    obs_val_n = np.array(obs_val_n._data)
    print(obs_val_n)

    obs_val_n, reward_n, PQstore_n, PVstore_n, Plstore_n, Indstore_n = env.step_wstate(PQstore, PVstore, Plstore, Indstore, action, FaultIndex=1)
    obs_val_n = np.array(obs_val_n._data)
    print(obs_val_n)

    env.closepenv()