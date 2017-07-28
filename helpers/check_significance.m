function [P,V] = check_significance(NimCell);

    RUNCORR=1;  
    RUNDUR = 30;
    MINTIME = 0.2;

    
    stim = NimCell.stim; spiketimes = NimCell.spiketimes;
    times = NimCell.times; 
    duration = NimCell.duration;
    
    
    nLags = 15;
    nPix = size(NimCell.stim,2);
    
    dt = 0.01;
    params_stim = NIM.create_stim_params([nLags,nPix],'stim_dt',dt);
    NimCell.params_stim = params_stim;
              
    dxs = round(NimCell.dxs,3);
    corrs = NimCell.correlation;        
    Robs = histc(NimCell.spiketimes,(0:(length(NimCell.stim)-1))*NimCell.params_stim.dt);

    dx_values = unique(dxs(~isnan(dxs)));
    dx_values = dx_values(abs(dx_values) < 1e3);
            
        
    step = 15;
    
    
    
    
    spike_counts = cell(1,length(dx_values));
            
    tc = zeros(1,length(dx_values));



    for j = 1:length(dx_values);                                
        current_frames = find(...
               (dx_values(j) == dxs) ...
            .* (corrs==RUNCORR) ...
            .* (times >= MINTIME) ...
            .* (duration==RUNDUR));
        
        %if dur == 30
        %    current_frames = current_frames(1:3:end);
        %    
        %elseif dur == 750
        %    current_frames = current_frames(1:75:end);
        %end

        resps = zeros(length(current_frames),step);        

        for k = 1:length(current_frames);
            start = current_frames(k);
            stop = min([current_frames(k)+step-1,length(dxs)]);

            R = zeros(1,step);


            R(1:length(start:stop)) = Robs(start:stop);


            resps(k,:) = R;

        end

        spike_counts{j} = resps;
        tc(j) = mean(sum(resps));

    end   
    
    ns = arrayfun(@(x)sum(NimCell.dxs(duration==RUNDUR)==x),dx_values);
    spike_counts = spike_counts(ns > 0);
    dx_values = dx_values(ns > 0);
    
    
    if isempty(tc);
        P = 0;
        V = NaN;
    else
        N = 1e3;

        p = 0.01;
        
        
        t0 = 1;
        t1 = 3:6;
        myvars = zeros(N,2);
        
        
        t = (0:step-1)*dt;
        
        plot_stuff = 0;
        
        
        if plot_stuff
            figure(); 
            subplot(1,2,1);
            hold on;
        end
        

        Ms = zeros(length(dx_values),step);
        for j = 1:length(dx_values);
            M = mean(spike_counts{j});
            Ms(j,:) = M;
            if plot_stuff
                plot(t,M,'linewidth',2);
            end
        end
        if plot_stuff
            subplot(1,2,2);
            plot(t,var(Ms,[],1),'k -','linewidth',2);
        end
        
        V = var(Ms,[],1);
         
         for k = 1:N;
             bstrap_resp = zeros(length(dx_values),step);            
             for j = 1:length(dx_values);
                 resps = spike_counts{j};
                 K = size(resps,1);
                 
                 idx = randi(K,K,1);
                 
                 bstrap_resp(j,:) = mean(resps(idx,:),1);
             end
             myvars(k,1) = var(bstrap_resp(:,t0),[],1);
             myvars(k,2) = mean(var(bstrap_resp(:,t1),[],1),2);                        
         end
        
        
    
         lower_t0 = quantile(myvars(:,1),p);
         upper_t0 = quantile(myvars(:,1),1-p);
         
         lower_t1 = quantile(myvars(:,2),p);
         upper_t1 = quantile(myvars(:,2),1-p);
         mean_t1 = mean(myvars(:,2));
       
        P = (lower_t0 > upper_t1) || (lower_t1 > upper_t0);
        %P = (upper_t0 < mean_t1);
    end
end

