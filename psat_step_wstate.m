function [state_n, reward, PQ_store, PV_store, Pl_store, Ind_store] = psat_step_wstate(casename_idx, fault_idx, PQ_store_old, PV_store_old, Pl_store_old, Ind_store_old, ~)
%psat_step_wstate 启动psat针对对应样本的结合故障集的仿真程序,初始状态基于给定的state进行计算
%   fault_idx: 故障集合的索引
%   计算对应仿真初始场景在预设故障下的稳定性，返回对应的状态
%   故障集的录入形式基于预先设定的故障信息索引，需要提前设定好故障信息
% 记录相对文件夹位置
clc
clear Ind PQ PV Pl Ind_store PQ_store PV_store Pl_store
currentFolder = pwd;
if nargin==0
    casename_idx = 0;
    fault_idx = 1;
end
cd('..');
% initialize PSAT
initpsat
% do not reload data file
clpsat.readfile = 0;
% 改变文件夹
cd(currentFolder);
cd("data")
% define case
casename = strcat('d_039_fault_mdl_idx',num2str(casename_idx));
rng('default')
% load case and caluclate
runpsat(casename,'data')
runpsat('pf')

% 定义减载的母线和其他特征量
global Ind PQ PV Pl Ind_store PQ_store PV_store Pl_store
global LoadsheddingBus LoadsheddingBusIdx

% 改变状态与重新潮流
% clear PQ
PQ = remove(PQ,1,'all');
PQ.store = [];
PV.store = PV_store_old;
Pl_store_old(:,11) = 0;
Pl.store = Pl_store_old;
Pl.con = Pl_store_old;
Ind.store = Ind_store_old;
runpsat('pf')

% 更新
PQ_store = PQ.store;
PV_store = PV.store;
Pl_store = Pl.con;
Ind_store = Ind.con;
Ind_store(:,end) = Ind.u;
LoadsheddingBusIdx = [4,7,18];

% search bus
LoadsheddingBus = [];
for i = 1:length(Pl_store(:,1))
    if ismember(Pl_store(i,1),LoadsheddingBusIdx)
        LoadsheddingBus = [LoadsheddingBus, i];
    end
end

% define fault settings
fault_set = [3,4,5,6,7,8,12,15,16,17,18];

% define results
reward = 1;

% calculating for power space
index_fault_set = fault_set(fault_idx);             % 故障编号

% loading pert file
pertfile = 'pert_control.m';
runpsat(pertfile,currentFolder,'pert')

% loading fault
Fault.store(1) = index_fault_set;       % 故障的位置

% run pf
runpsat('pf') 
% run psat time domain
runpsat('td') 

% init time series
r = Varout.vars;
plot(Varout.t,r(:,290+LoadsheddingBusIdx));
grid on
time_series = 0:0.02:10;                            % 记录对应的时间序列特性
% 准备插值恢复电压序列
voltage_series = zeros(Bus.n,length(time_series));  % 提取对应的电压序列特性
% get original voltage
voltages_origin = Varout.vars(:, (DAE.n + Bus.n + 1):(DAE.n + 2*Bus.n));
time = Varout.t;
% interpret
for idx_bus = 1:Bus.n
    voltage_series(idx_bus,:) = ...
        interp1(time',voltages_origin(:,idx_bus)',time_series,'linear');
end
voltage_series(isnan(voltage_series)) = 0;  % bus,num
voltcheck = voltage_series(:,end-5:end);   % 获取后5个点的数据
if min(voltcheck,[],'all')<=0.8
    reward = -1;
end

% 整理状态(假设到达下一个稳态)
% 状态定义为各个节点和电动机的功率注入，以及电动机的滑差
voltages = DAE.y(1+Bus.n:2*Bus.n);
state_n = [voltages; Bus.Pl - Bus.Pg; Bus.Ql - Bus.Qg];
% 滑差计算
Ind_slip_idx = Ind.slip; 
Slip_val = Varout.vars(:,Ind_slip_idx);
state_n = [state_n; Slip_val(end,:)'];

clear Ind_store PQ_store PV_store Pl_store
PQ_store = PQ.store;
PV_store = PV.store;
Pl_store = Pl.con;
Ind_store = Ind.con;
Ind_store(:,end) = Ind.u;

closepsat
% 改变文件夹
cd(currentFolder);
end
% end