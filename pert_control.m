function pert_control(t)
global Ind PQ PV Pl Ind_store PQ_store PV_store Pl_store
global LoadsheddingBus LoadsheddingBusIdx
LoadSheddingAmount = [0.2;0.2;0.2;];
LoadsheddingInd = cell(length(LoadsheddingBusIdx),1);
for i = 1:length(Ind_store(:,1))
    for j = 1:length(LoadsheddingBusIdx)
        if ismember(Ind_store(i,1),LoadsheddingBusIdx(j))
            % 需要加一个判断的逻辑
            LoadsheddingInd{j} = [LoadsheddingInd{j}, i];
        end
    end
end
if (t > 1.40)      % criterion
    % actions for control
% Pl.con(LoadsheddingBus,[5:10]) = [0.8;0.8;0.8].*Pl_store(LoadsheddingBus,[5:10]);      % cut load precentage
    for i = 1:length(LoadSheddingAmount)
        Ind.dat(LoadsheddingInd{i},1) = LoadSheddingAmount(i).*Ind_store(LoadsheddingInd{i},15);             % cut ind precentage
        Ind.con(LoadsheddingInd{i},15) = LoadSheddingAmount(i).*Ind_store(LoadsheddingInd{i},15);            % cut ind precentage
    end
else
    % action
    
end
end