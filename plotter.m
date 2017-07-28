function plotter(dataDir)
    %
    % Author: Sid Henriksen (2016). Email: sid.henriksen@gmail.com.
    %
    
    if ~nargin
        dataDir = [];
    end
            
    setup_path();
    
    myFig = init_figure(dataDir);

    populate_plot(myFig,[],'AnticorrelatedSlope','Cell');

    set(gcf,'Color','White','windowbuttondownfcn',{@TC_callback});%,'windowkeypressfcn',{@keydown_callback});

end

function myFig = init_figure(dataDir)
    

  % this is a function that returns the menus packed in a single struct
    allMenus = generate_menus();
    
    myFig = allMenus.myFig; % this is the parent figure
        
    if isempty(dataDir)
        [cellData,modelData] = get_plotter_data(); 
    else
        [cellData,modelData] = get_plotter_data(dataDir); 
    end

    allData.cellData = cellData;
    allData.modelData = modelData;
    
    setappdata(myFig,'allData',allData);
    
    
    % Set the x and y axis data
    setappdata(myFig,'xdata','AnticorrelatedSlope');
    setappdata(myFig,'ydata','AnticorrelatedSlope');
    setappdata(myFig,'xCellOrModel','Model');
    setappdata(myFig,'yCellOrModel','Cell');
    setappdata(myFig,'EqualAxes',0);
    
    
end

function populate_plot(myMenu,evt,dataType,cellOrModel)
    % Function to populate the subplots of the main figure
    % This will take Base, which is the structure generated by
    % CurateCells.m, and a string as argument. The string should specify
    % what we're plotting on the relevant axis.
    myFig = gcf;
    
    ch = get(gcf,'Children'); 
            
    plotMenu = get(ch(1),'Children');
    
    xmainMenu = plotMenu(length(plotMenu));
    
    ymainMenu = plotMenu(length(plotMenu)-1);
    
    xmainChildren = get(xmainMenu,'Children');
    
    ymainChildren = get(ymainMenu,'Children');
    
    axchange = '';
    
    
    
    %% This bit works out whether the data should be plotted 
    % on the x-axis or the y-axis.
    
    myMenu = get(myMenu,'Parent');
    rootMenu = myMenu;

    menuData = get(rootMenu,'UserData');
    if strcmp(menuData,'x')

        setappdata(gcf,'xdata',dataType)
        setappdata(gcf,'xCellOrModel',cellOrModel);
        axchange = 'x';

    elseif strcmp(menuData,'y')
        setappdata(gcf,'ydata',dataType);
        setappdata(gcf,'yCellOrModel',cellOrModel);
        axchange = 'y';

    end

        
    
        
    %% Plot the data
    plot_data(myFig);
    
    %% Adjust the ticks appropriately
    if strcmp(axchange,'x')
        mainChildren = xmainChildren;
    elseif strcmp(axchange,'y')
        mainChildren = ymainChildren;
    end

    if ~strcmp(axchange,'')
        for k = 1:length(mainChildren)
            current = mainChildren(k);

            if isequal(current,evt.Source)
                current.Checked = 'on';
            else
                current.Checked = 'off';
            end
        end
    end        
    

    
end





function plot_data(myFig)
    % This is a function that actually plots the data in the highlighted
    % subplot. This function will take the figure data that has been set
    % elsewhere and will plot the correct thing. This is really lengthy.
    
    monkeys = {'jbe','lem'};
        
    figAppData = getappdata(myFig);        
    
    %allExptNames = figAppdata.cellData.exptlist;
                
    
    % If colours are not defined, define them. Otherwise just get them
    % from appdata
    if ~isfield(figAppData,'colors')
        myCols = [1,0,0;0,1,0;0,0,1;1,1,0;1,0,1;0,1,1;rand(20,3).^2];
        setappdata(gcf,'colors',myCols);    
    else
        myCols = figAppData.colors;
    end
    
    allData = figAppData.allData;    
    xCellOrModel = figAppData.xCellOrModel;
    yCellOrModel = figAppData.yCellOrModel;
    
    nCells = length(allData.cellData);
        
    cla;
    hold on;
    X = zeros(1,nCells);
    Y = zeros(1,nCells);
    
    xtype = getappdata(myFig,'xdata');
    ytype = getappdata(myFig,'ydata');
        
    for cell = 1:nCells
        
        % Leaving this out for now;
        %whichFile = strcmp(currentData(cell).filename,allExptNames);
        %currentColor = myCols(whichFile,:);
        currentColor = [0.8,0.1,0.1];

        currentMonkey = allData.cellData(cell).fileName(1:3);

        % We choose from a range of data types to plot;
        % This is really long, but simply chooses the correct values
        % to plot on the x and y axes.

        DDIKey = {'Cell',cell,[]};
        %currentDDI = compute_DDI_local(allData,DDIKey);
        currentDDI = 0.3;
        
        xKey = {xCellOrModel,cell,xtype};
        
        yKey = {yCellOrModel,cell,ytype};

        x = get_data(allData,xKey);

        y = get_data(allData,yKey);
                
        tcCell = allData.cellData(cell).spikeCount;
        
        tcModel = allData.modelData(cell).spikeCount;
        
        r = compute_r(tcCell,tcModel);
        
        if r^2 < 0.4
            continue
        end
        
        %% This is where we actually plot the data
        % Different shapes for jbe and lem

        if strcmp(currentMonkey,monkeys{1})
            markerStyle = 's';
        elseif strcmp(currentMonkey,monkeys{2})
            markerStyle = 'o';
        else
            markerStyle='^';
            currentColor=[0.2,0.2,0.8];
            currentDDI=0.65;
        end

        plot(x,y,'k','marker',markerStyle,'markersize',...
            round((1+currentDDI).^2*10),'markerfacecolor',currentColor);


        X(cell) = x;

        Y(cell) = y;
    
    end
    
    
    % gets axis label and limits
        
    % Set XYData!
    XYData.x = X;
    XYData.y = Y;
    
    [r,p] = corr(ascolumn(X),ascolumn(Y));
    setappdata(gca,'XYData',XYData);
    
    set_axis_props(myFig);
    
    title(sprintf('r=%.2f, p=%.3f',r,p),'fontsize',14);
    
    
end



function x = get_data(allData,key)
    cellOrModel = key{1};
    cellNumber = key{2};
    type = key{3};
    
    if strcmp(cellOrModel,'Cell')
        
        currentData = allData.cellData(cellNumber);
        
    elseif strcmp(cellOrModel,'Model')
        
        currentData = allData.modelData(cellNumber);
        
    elseif strcmp(cellOrModel,'BEM')
        
        currentData = allData.bemData(cellNumber);
        
    elseif strcmp(cellOrModel,'Compare')
        
        cellData = allData.cellData(cellNumber);
        
        modelData = allData.modelData(cellNumber);
        
    end
    
    switch type
        
        case 'TCSlope'
            lambda = sum(strip_uc(modelData.variance)) / sum(strip_uc(cellData.variance));
            [~,x] = type2_regression(strip_uc(modelData.spikeCount),strip_uc(cellData.spikeCount),lambda);
            
        case 'CorrelatedTCSlope'
            lambda = 1;
            [~,x] = type2_regression(cellData.spikeCount(3,:),modelData.spikeCount(3,:),lambda);
            
            
        case 'AnticorrelatedTCSlope'
            lambda = 1;
            [~,x] = type2_regression(cellData.spikeCount(1,:),modelData.spikeCount(1,:),lambda);
            
        case 'TCR'    
            lambda = 1;
        	x = type2_regression(strip_uc(cellData.spikeCount),strip_uc(modelData.spikeCount),lambda);
            
        case 'CorrelatedTCR'
            lambda = 1;
            x = type2_regression(cellData.spikeCount(3,:),modelData.spikeCount(3,:),lambda);
            
        case 'AnticorrelatedTCR'
            lambda = 1;
            x = type2_regression(cellData.spikeCount(1,:),modelData.spikeCount(1,:),lambda);
                
        case 'AnticorrelatedSlope'
            acResponse = currentData.spikeCount(1,:);
            cResponse = currentData.spikeCount(3,:);
            lambda = 1;
            [~,x] = type2_regression(cResponse,acResponse,lambda); % slope
            
            
        case 'AnticorrelatedR'
            acResponse = currentData.spikeCount(1,:);
            cResponse = currentData.spikeCount(3,:);
            lambda = 1;
            x = type2_regression(cResponse,acResponse,lambda);

            
        case 'LowContrastFanoFactor'

            currentVar = strip_uc(currentData.varianceLowContrast);
            currentSC = strip_uc(currentData.spikeCountLowContrast);
            x = mean(currentVar./currentSC);
            %x = mean(currentVar)./mean(currentSC);

        case 'LowContrastSCFFSlope'

            currentVar = strip_uc(currentData.varianceLowContrast);
            currentSC = strip_uc(currentData.spikeCountLowContrast);
            currentFF = currentVar./currentSC;
            [~,x] = regression2(currentFF,currentSC);

        case 'LowContrastSCFFr'

            currentVar = strip_uc(currentData.varianceLowContrast);
            currentSC = strip_uc(currentData.spikeCountLowContrast);
            currentFF = currentVar./currentSC;
            x = regression2(currentFF,currentSC);

       case 'HighContrastFanoFactor'

            currentVar = strip_uc(currentData.varianceHighContrast);
            currentSC = strip_uc(currentData.spikeCountHighContrast);
            x = mean(currentVar(:))./mean(currentSC(:));

        case 'HighContrastSCFFSlope'
            
            currentVar = strip_uc(currentData.varianceHighContrast);
            currentSC = strip_uc(currentData.spikeCountHighContrast);
            currentFF = currentVar./currentSC;
            [~,x] = regression2(currentFF,currentSC);

        case 'HighContrastSCFFr'

            currentVar = strip_uc(currentData.varianceHighContrast);
            currentSC = strip_uc(currentData.spikeCountHighContrast);
            currentFF = currentVar./currentSC;
            x = regression2(currentFF,currentSC);
            
        case 'DDI'
            variance = strip_uc(currentData.variance);
            spikeCount = strip_uc(currentData.spikeCount);
            rMax = max(spikeCount);
            rMin = min(spikeCount);
            RMSerror = sqrt(mean(variance));
            x = (rMax-rMin)/(rMax-rMin + 2*RMSerror);
            
        case 'LoHiSlope'
            lo = strip_uc(currentData.spikeCountLowContrast);
            hi = strip_uc(currentData.spikeCountHighContrast);
            [~,x] = regression2(lo,hi);
            
        case 'LoHiR'
            lo = strip_uc(currentData.spikeCountLowContrast);
            hi = strip_uc(currentData.spikeCountHighContrast);
            x = regression2(lo,hi);
            
        case 'MeanSpikeCount'
            x = mean(strip_uc(currentData.spikeCount));

        case 'GaussianACSlope'
            acCount = currentData.bgnSpikeCount(1,:);
            cCount =  currentData.bgnSpikeCount(3,:);
            
            [~,x] = regression2(acCount,cCount);
            

            
    end
end

function TC_callback(myFig,evt,dataType)
    % Callback function to plot tuning curves
        
    
    while ~isfigure(myFig)
        myFig = get(myFig,'Parent');
        figData = getappdata(myFig);
        if isfield(figData,'PseudoParent')
            myFig = figData.PseudoParent;
        end
    end
    
    tcFigDeleted = 0;
    
    figData = getappdata(myFig);
    % If this hasn't been called before, assign a new figure handle
    if isfield(figData,'TCHandle')
        tcFigDeleted = ~ishandle(figData.TCHandle);
    end
    
    
    
        
    if ~isfield(figData,'TCHandle') || tcFigDeleted
        newFig = figure(); 
        set(newFig,'color','white');
        figData.TCHandle = newFig;
        setappdata(myFig,'TCHandle',newFig);
        
        setappdata(figData.TCHandle,'PseudoParent',myFig);
        
        setappdata(figData.TCHandle,'Plotting','spikeCount');
        
        tcMenus = generate_tc_menus(figData.TCHandle);
        
        setappdata(figData.TCHandle,'LegendToggled',0);
                
                        
    end
    
    legendToggled = getappdata(figData.TCHandle,'LegendToggled');    
    
    if nargin < 3    
        % if we aren't changing stuff, then this is what we're plotting
        dataType = getappdata(figData.TCHandle,'Plotting');
    else
        setappdata(figData.TCHandle,'Plotting',dataType);
        
    end

    currentAxis = get_axis(myFig);
        
    axisData = getappdata(currentAxis);
    
    currentPoint = get(currentAxis,'currentpoint');    


    % Get data
    
    allData = figData.allData;
    
    XYData = axisData.XYData;
        
    % Find point with closest Euclidean distance
    distance = (XYData.x-currentPoint(1,1)).^2 + (XYData.y - currentPoint(2,2)).^2;
        
    whichCell = find(distance == min(distance)); 
    
    whichCell = whichCell(1); % If equidistant, just choose first one
        
    cellName = get_cell_name(allData.cellData(whichCell).fileName);
    
    dx = allData.cellData(whichCell).dx;
    
    modelKey = {'Model',whichCell,dataType};
    
    cellKey = {'Cell',whichCell,dataType};
    
    yModel = get_tc_data(allData,modelKey);
    
    yCell = get_tc_data(allData,cellKey);
    
    [dx,yModel] = integrity_check(dx,yModel);
    [dx,yCell] = integrity_check(dx,yCell);
    
    ylims = [min([yModel(:);yCell(:)]),max([yModel(:);yCell(:)])];
    step = dx(2)-dx(1);
    xlims = [min(dx)-step,max(dx)+step];
    
    lw = 3;
    figure(figData.TCHandle);
    subplot(1,2,1); cla; hold on;    
    plot(dx,yCell(1,:),'k -','linewidth',lw);
    plot(dx,yCell(2,:),'-','color',[0.6,0.6,0.6],'linewidth',lw);
    plot(dx,yCell(3,:),'r -','linewidth',lw);
    xlabel('Disparity (deg)','fontsize',16)
    ylabel(dataType,'fontsize',16);
    title(cellName,'fontsize',16);
    xlim(xlims); ylim(ylims)
            
    subplot(1,2,2); cla; hold on;
    plot(dx,yModel(1,:),'k -','linewidth',lw);
    plot(dx,yModel(2,:),'-','color',[0.6,0.6,0.6],'linewidth',lw);
    plot(dx,yModel(3,:),'r -','linewidth',lw);
    xlabel('Disparity (deg)','fontsize',16)
    title('Model','fontsize',16); 
    xlim(xlims); ylim(ylims);
        
    if legendToggled
        
        leg=legend('Anticorrelated','Uncorrelated','Correlated');
        
        set(leg,'location','northwest')        
    else
        legend off;
        
    end

        
    figure(myFig);
    
end

function x = get_tc_data(allData,key)
    % Returns the appropriate data for a specified key
    % Usage:
    % x = get_tc_data(allData,key)
    % allData : allData struct
    % key : a cell of the form {cellOrModel,cellNo,type}, e.g.
    % {'Model',4,'LowContrastVariance'}
    % will return the low contrast variance data for the fourth
    % model cell.

    cellOrModel = key{1};
    cellNumber = key{2};
    type = key{3};
    
    if strcmpi(cellOrModel,'Cell')
        currentData = allData.cellData(cellNumber);
    elseif strcmpi(cellOrModel,'Model')
        currentData = allData.modelData(cellNumber);
    end
    
    switch type
        
        case 'LowContrastSpikeCount'
            x = currentData.spikeCountLowContrast;
            
        case 'LowContrastVariance'
            x = currentData.varianceLowContrast;
            
        case 'LowContrastFanoFactor'
            
            x = currentData.varianceLowContrast ./ ...
                currentData.spikeCountLowContrast;
            
        case 'HighContrastSpikeCount'
            x = currentData.spikeCountHighContrast;
            
        case 'HighContrastVariance'
            x = currentData.varianceHighContrast;
            
        case 'HighContrastFanoFactor'
            
            x = currentData.varianceHighContrast ./ ...
                currentData.spikeCountHighContrast;
                    
        case 'spikeCount'
            x = currentData.spikeCount;
            
        case 'InternalVariance'
            x = currentData.internalVariance;
            
        case 'ExternalVariance'
            x = -(currentData.variance - currentData.internalVariance);
            
        case 'variance'
            x = currentData.variance;
            
        case 'InternalFanoFactor'
            x = currentData.internalVariance ./ ...
                currentData.spikeCount;
            
        case 'ExternalFanoFactor'
            externalVariance = currentData.variance- currentData.internalVariance;
            x = externalVariance ./ currentData.spikeCount;
            
        case 'TotalFanoFactor'
            x = currentData.variance./currentData.spikeCount;
                        
        case 'ExternalSD'
            x = sqrt(currentData.variance-currentData.internalVariance);
            

    end
    
end

function set_axis_props(myFig)
    % Get figure data, work out what's plotted and set the limits and labels
    
    figData = getappdata(myFig);
    
    xtype = figData.xdata;
    
    xCellOrModel = figData.xCellOrModel;
        
    ytype = figData.ydata;
    
    yCellOrModel = figData.yCellOrModel;
            
    xlab = get_label(xtype,xCellOrModel);
    
    ylab = get_label(ytype,yCellOrModel);
    
    ax = get_axis(myFig);
    
    assert(length(ax)==1,'Multiple axes returned.. Something funny here');
    
    xlabel(ax,xlab,'fontsize',15)
    
    ylabel(ax,ylab,'fontsize',15);
        
            
end

function ax = get_axis(myFig)
    
    ch = get(myFig,'children');
    
    idx = arrayfun(@isaxis,ch);
    
    ax = ch(idx);

end


function label = get_label(type,cellOrModel)

    expt = {'LowContrast','HighContrast','Twopass','DDI','LoHi','Mean','Proportion','Anticorrelated','Correlated','Gaussian'};
    exptMatch = {'Low contrast','High contrast','Two-pass','DDI','Low-High contrast','Mean','Proportion','Anticorrelated','Correlated','Gaussian'};
    
    prop = {'TCSlope','TCR','FanoFactor','SCFFSlope','SCFFr','Variance','SpikeCount','Slope','R','BrennyFactor','SCBF'};
    propMatch = {'TC slope','TC r','FF','SC-FF slope','SC-FF r','Variance','spike count','slope','r','Brenny Factor','SC-BF'};
    
    % not all fields will match this one... 
    suppProp = {'Internal','External','Total'};
            
    exptIdx = find_string_in_cell(expt,type);
    
    propIdx = find_string_in_cell(prop,type);
    
    suppPropIdx = find_string_in_cell(suppProp,type);
    
    currentExptMatch = exptMatch{exptIdx};
    
    if ~sum(propIdx)
        currentPropMatch = '';
    else        
        currentPropMatch = propMatch{propIdx};
    end
    
    if ~sum(suppPropIdx)
        currentSuppPropMatch = '';
    else
        currentSuppPropMatch = suppProp{suppPropIdx}; %don't need special match for this
    end
    
    
    if strcmp(cellOrModel,'Compare')
        
        label = sprintf('%s %s %s',currentExptMatch,currentSuppPropMatch,currentPropMatch);
        
    else
        
        label = sprintf('%s %s %s (%s)',currentExptMatch,currentSuppPropMatch,currentPropMatch,cellOrModel);
        
    end
        

end

function DDI = compute_DDI_local(allData,key)
    cellOrModel = key{1};
    
    cellNumber = key{2};
        
    if strcmp(cellOrModel,'Cell')
        currentData = allData.cellData(cellNumber);
    elseif strcmp(cellOrModel,'Model')
        currentData = allData.modelData(cellNumber);
    end
        
    variance = strip_uc(currentData.totalSqrtVariance);
    
    spikeCount = strip_uc(currentData.twopassSqrtSpikeCount);
    
    rMax = max(spikeCount);
    
    rMin = min(spikeCount);
    
    RMSerror = sqrt(mean(variance));
    
    DDI = (rMax-rMin)/(rMax-rMin + 2*RMSerror);
    
    
end

function allMenus = generate_menus()

    % Create figure
    myFig=figure();
    
    mh = uimenu(myFig,'Label','Plot');
    
    
    xMain = uimenu(mh,'Label','x-axis');    
    xMenuCell= uimenu(mh,'Label','Cell','UserData','x');    
    xMenuModel = uimenu(mh,'Label','GBEM','UserData','x');
    xMenuBem = uimenu(mh,'Label','BEM','UserData','x');
    xMenuCompare= uimenu(mh,'Label','Cell v. Model','UserData','x');
    
    %seperator = uimenu(mh,'Label',sprintf('\n'));
    
    yMain = uimenu(mh,'Label','y-axis','separator','on');        
    yMenuCell= uimenu(mh,'Label','Cell','UserData','y');
    yMenuModel = uimenu(mh,'Label','GBEM','UserData','y');    
    yMenuBem = uimenu(mh,'Label','BEM','UserData','y');    
    yMenuCompare = uimenu(mh,'Label','Cell v. Model','UserData','y');
    
    %uimenu(mh,'Label','Bruce I (slow)','separator','on','Callback',{@plot_bruce1});
    
    
    menus = {xMenuModel,xMenuCell,xMenuBem,yMenuModel,yMenuCell,yMenuBem,xMenuCompare,yMenuCompare};
    callbackArgs = {'Model','Cell','BEM','Model','Cell','BEM','Compare','Compare'};
    
    
    
    
    for k = 1:length(menus)
        
        
        if any(strcmp(callbackArgs{k},{'Cell','Model','BEM'}))
            
            subMenus(k).MenuAnticorrelatedSlope = uimenu(menus{k},'Label','Anticorrelated slope','checked','off','Callback',{@populate_plot, 'AnticorrelatedSlope',callbackArgs{k}});
            subMenus(k).MenuAnticorrelatedR = uimenu(menus{k},'Label','Anticorrelated r','checked','off','Callback',{@populate_plot, 'AnticorrelatedR',callbackArgs{k}});

            subMenus(k).MenuLowContrastFanoFactor = uimenu(menus{k},'Label','Low contrast Fano Factor','Checked','off','separator','on','Callback',{@populate_plot,'LowContrastFanoFactor',callbackArgs{k}});
            subMenus(k).MenuLowContrastSCFFSlope = uimenu(menus{k},'Label','Low contrast SC-FF slope','Checked','off','Callback',{@populate_plot,'LowContrastSCFFSlope',callbackArgs{k}});
            subMenus(k).MenuLowContrastSCFFr = uimenu(menus{k},'Label','Low contrast SC-FF r','Checked','off','Callback',{@populate_plot,'LowContrastSCFFr',callbackArgs{k}});        

            subMenus(k).MenuHighContrastFanoFactor = uimenu(menus{k},'Label','High contrast Fano Factor','Checked','off','separator','on','Callback',{@populate_plot,'HighContrastFanoFactor',callbackArgs{k}});
            subMenus(k).MenuHighContrastSCFFSlope = uimenu(menus{k},'Label','High contrast SC-FF slope','Checked','off','Callback',{@populate_plot,'HighContrastSCFFSlope',callbackArgs{k}});
            subMenus(k).MenuHighContrastSCFFr = uimenu(menus{k},'Label','High contrast SC-FF r','Checked','off','Callback',{@populate_plot,'HighContrastSCFFr',callbackArgs{k}});

            subMenus(k).MenuLoHiSlope = uimenu(menus{k},'Label','Low-high contrast slope','checked','off','separator','on','callback',{@populate_plot,'LoHiSlope',callbackArgs{k}});
            subMenus(k).MenuLoHir = uimenu(menus{k},'Label','Low-high contrast r','checked','off','callback',{@populate_plot,'LoHiR',callbackArgs{k}});
            
            if strcmp(callbackArgs{k},'Model')
               
                uimenu(menus{k},'Label','Gaussian noise AC slope','checked', 'off','separator','on','Callback',{@populate_plot,'GaussianACSlope',callbackArgs{k}});
                
            end

        else
            subMenus2(k).MenuTCSlope = uimenu(menus{k},'Label','TC slope (all)','Checked','off','separator','off','Callback',{@populate_plot,'TCSlope',callbackArgs{k}});
            subMenus2(k).MenuCorrelatedTCSlope = uimenu(menus{k},'Label','Correlated TC slope','Checked','off','separator','off','Callback',{@populate_plot,'CorrelatedTCSlope',callbackArgs{k}});
            subMenus2(k).MenuAnticorrelatedTCSlope = uimenu(menus{k},'Label','Anticorrelated TC slope','Checked','off','separator','off','Callback',{@populate_plot,'AnticorrelatedTCSlope',callbackArgs{k}});
            
            subMenus2(k).MenuTCR = uimenu(menus{k},'Label','TC r (all)','Checked','off','separator','on','Callback',{@populate_plot,'TCR',callbackArgs{k}});
            subMenus2(k).MenuCorrelatedTCR = uimenu(menus{k},'Label','Correlated TC r','Checked','off','separator','off','Callback',{@populate_plot,'CorrleatedTCR',callbackArgs{k}});
            subMenus2(k).MenuAnticorrelatedTCR = uimenu(menus{k},'Label','Anticorrelated TC r','Checked','off','separator','off','Callback',{@populate_plot,'AnticorrelatedTCR',callbackArgs{k}});
            
        end
    end
    
    %uimenu(mh,'Label',sprintf('\n'));
    
    uimenu(mh,'Label','Toggle equal axes','Checked','off','Callback',{@equalise_axes},'separator','on');
    
    allMenus = packWorkspace();

end

function tcMenus = generate_tc_menus(myFig)
    tcMenu = uimenu(myFig,'Label','Tuning curves');
    
    
    lowContrastSpikeCount = uimenu(tcMenu,'Label','Low contrast spike count','Callback',{@TC_callback,'LowContrastSpikeCount'});
    lowContrastVariance = uimenu(tcMenu,'Label','Low contrast variance','Callback',{@TC_callback,'LowContrastVariance'});
    lowContrastFanoFactor = uimenu(tcMenu,'Label','Low contrast Fano Factor','Callback',{@TC_callback,'LowContrastFanoFactor'});
    
    highContrastSpikeCount = uimenu(tcMenu,'Label','High contrast spike count','Callback',{@TC_callback,'HighContrastSpikeCount'});
    highContrastVariance = uimenu(tcMenu,'Label','High contrast variance','Callback', {@TC_callback,'HighContrastVariance'});
    highContrastFanoFactor = uimenu(tcMenu,'Label','High contrast Fano Factor','Callback',{@TC_callback,'HighContrastFanoFactor'});
    
    spikeCount = uimenu(tcMenu,'Label','Two-pass spike count','Callback',{@TC_callback,'spikeCount'});
    
    toggleLegendMenu = uimenu(myFig,'Label','Toggle legend','Callback',{@toggle_legend});
    
    
    tcMenus = packWorkspace();
end

function toggle_legend(myFig,evt)

    while ~isfigure(myFig)
        
        myFig = get(myFig,'Parent');
                
    end
        
    
    parentFig = getappdata(myFig,'PseudoParent');
    
    parentData = getappdata(parentFig);
    
    legendToggled = getappdata(parentData.TCHandle,'LegendToggled');
        
    setappdata(parentData.TCHandle,'LegendToggled',~legendToggled);
    
    TC_callback(parentFig,[]);

end

function cellName = get_cell_name(fileName)

    matIdx = strfind(fileName,'.mat');
    
    cellName = fileName(1:matIdx-1);

end

function [dx,y] = integrity_check(dx,y)

    nDx = length(dx);
    nY = size(y,2);
    
    if nDx > nY
        warning('Integrity test failed. Stim data shorter than disparities.')
        dx = unique(round(dx,3));
        
        
        while length(dx) > nY
            
            dx = dx(1:end-1);
            
        end
                        
        
    elseif nDx < nY
        warning('Integrity test failed. Disparities shorter than stim data.')
        step = dx(2)-dx(1);
        while length(dx) < nY
           
           dx = [dx,max(dx)+step];
           
       end
    end
    
    

end


function bool = isaxis(x)
    % returns 1 if x is an axis, 0 otherwise
    % usage: isAxis = isaxis(x);
    if ishandle(x)
        
        type = get(x,'type');
        
        bool = strcmp(type,'axes');
        
    else
        
        bool = false;
        
    end
    
end


function bool = isfigure(x)
    % returns 1 if x is a figure, 0 otherwise
    % usage: isFigure = isfigure(x);
    
    if ishandle(x)
        
        type = get(x,'type');
        
        bool = strcmp(type,'figure');
    
    else
        
        bool = false;
        
    end
    
    

end

function equalise_axes(menuAx,evt)
    
    myFig = menuAx;
    
    while ~strcmp(get(myFig,'type'),'figure')
        
        myFig = get(myFig,'Parent');
        
    end
    
    equalAxes = getappdata(myFig,'EqualAxes');
    
    ax = get_axis(myFig);
    
    ch = get(ax,'children');
    
    if ~isempty(evt)
        menuAx = evt.Source;
    end
    
    if ~equalAxes
        xData = arrayfun(@(x) get_field_data(x,'XData'),ch);
        yData = arrayfun(@(y) get_field_data(y,'YData'),ch);

        lims = [min([xData;yData]),max([xData;yData])];
        dx = range(lims)*0.05;
        lims = lims + [-dx,dx];
        
        xlim(ax,lims);
        ylim(ax,lims);
        
        setappdata(myFig,'EqualAxes',1);
        set(menuAx,'checked','on');
        
    else
        set(ax,'XLimMode','auto');
       
        set(ax,'YLimMode','auto');
       
        setappdata(myFig,'EqualAxes',0);
        set(menuAx,'checked','off');
    end
        

end

function x = get_field_data(ch,myField)
    % this just lets us put in a conditional to set lines and the like
    % to 0
    x = get(ch,myField);    
    
    if length(x)>1        
        x = NaN;
    end

end

function setup_path()

    fullPath = mfilename('fullpath');
    currentPath = path;    
    
    
    if isunix
        allSlashes = strfind(fullPath,'/');
    else
        allSlashes = strfind(fullPath,'\');
    end
    basePath = fullPath(1:allSlashes(end)-1);
    
    if isempty(strfind(currentPath,basePath))
        addpath(genpath(basePath));
    end

end

function r = compute_r(x,y)

    x = strip_uc(x);
    y = strip_uc(y);
    
    r = regression2(y,x);
end


function plot_bruce1(myFig,evt)
    
    while ~isfigure(myFig)
        
        myFig = get(myFig,'Parent');
                
    end
      
    data = getappdata(myFig);
    
    modelData = data.allData.modelData;
    cellData = data.allData.cellData;
    
    totalModelVariance = [];
    modelSpikeCount = [];
    
    totalCellVariance = [];
    cellSpikeCount = [];
    
    for k = 1:length(modelData)
        
        totalModelVariance = [totalModelVariance;strip_uc(modelData(k).variance)];
        
        modelSpikeCount = [modelSpikeCount;strip_uc(modelData(k).spikeCount)];
        
        totalCellVariance = [totalCellVariance;strip_uc(cellData(k).variance)];
        
        cellSpikeCount = [cellSpikeCount;strip_uc(cellData(k).spikeCount)];
    end
    
    modelFF = totalModelVariance./modelSpikeCount;
    cellFF = totalCellVariance./cellSpikeCount;
        
    myAlpha = 0.1;
        
    figure(); hold on;
    
    t = linspace(0,2*pi,21);
    r = 0.1;
    
    for k = 1:length(cellSpikeCount)
        
        p1=patch(r*cos(t)+cellSpikeCount(k),r*sin(t)+cellFF(k),'b','edgecolor','none','facealpha',myAlpha);
        
        %alpha(p1,myAlpha);
        
        p2 = patch(r*cos(t)+modelSpikeCount(k),r*sin(t)+modelFF(k),'r','edgecolor','none','facealpha',myAlpha);
        %alpha(p2,myAlpha)
    end
    
    xlim([-0.25,5]);
    ylim([-0.25,5]);
    xlabel('Mean spike count','fontsize',16)

    ylabel('Total Fano Factor','fontsize',16)

    legend('Cell','Model')
    set(gcf,'color','white')
end 
