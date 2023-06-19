function [state, PQ_store, PV_store, Pl_store, Ind_store] = psat_getstate(casename_idx)
%psat_getstate 获取电力系统的初始化状态信息
%   此处提供详细说明
% 记录相对文件夹位置
currentFolder = pwd;
if nargin==0
    casename_idx = 1;
end
cd('..');
% initialize PSAT
initpsat
% do not reload data file
clpsat.readfile = 0;
cd(currentFolder);
cd("data")
% define case
casename = strcat('d_039_fault_mdl_idx',num2str(casename_idx));
rng('default')
% load case and caluclate
runpsat(casename,'data')
runpsat('pf')
PQ_store = PQ.con;
PV_store = PV.con;
Pl_store = Pl.con;
Ind_store = Ind.con;

% 状态定义为各个节点和电动机的功率注入，以及电动机的滑差
voltages = DAE.y(1+Bus.n:2*Bus.n);
state = [voltages; Bus.Pl - Bus.Pg; Bus.Ql - Bus.Qg];
bus_n = Bus.n;
line_n = Line.n;

% 时序仿真初始化滑差
runpsat('td')
Ind_slip_idx = Ind.slip; 
Slip_val = Varout.vars(:,Ind_slip_idx);
state = [state; Slip_val(1,:)'];

closepsat
cd(currentFolder);
end