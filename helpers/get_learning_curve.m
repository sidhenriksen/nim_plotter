

function [ps,LLTrains,LLCvs] = get_learning_curve(NimCell,nExc,nInh)

K = 5;
ps = linspace(0.1,0.95,10);
LLCvs = zeros(K,length(ps));
LLTrains= zeros(K,length(ps));


for j = 1:length(ps)
    optStruct.pTrain = ps(j);
    for i = 1:K
        [NimModel,LLCv,LLTrain] = fit_NimModel(NimCell,nExc,nInh,optStruct);
        LLCvs(i,j) = LLCv;
        LLTrains(i,j) = LLTrain;
    end
    
end

end