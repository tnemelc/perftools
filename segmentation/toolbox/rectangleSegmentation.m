function [rectMyo, rectVD, rectVG] = rectangleSegmentation(slcSerie, serieName)

    if ~nargin
        return;
    end

    [H, W, nbImages] = size(slcSerie);
    labelsMask = zeros(H, W);
    slcPos = 20;
    nbRegions = 0;
    
    imgOpt.brightness = 0;
    imgOpt.contrast = 1;
    imgOpt.angle = 0;
    focusedRoi = 'none';
    
    fm = figureMgr.getInstance();
    figHdle = fm.newFig(serieName); subplot(1, 2, 1); colormap gray;
    ha = tight_subplot(1,2,[.05 .03],[.15 .01],[.01 .01]);
    axes(ha(1));
    imgHdle = imagesc(correctImage(slcSerie(:, :, slcPos))); axis off; axis image;
    dispSlicePos();
    set(imgHdle,'ButtonDownFcn', @createRoiCb);
    set(figHdle,'WindowScrollWheelFcn', @OnScrollCb);
    set(figHdle, 'KeyPressFcn', @onKeyPressCb);
    
    %go button
    uicontrol('Style', 'pushbutton',...
        'Units',  'normalized',...
        'Position', [0.1 0.05 0.1 0.1],...
        'String', '+ myo',...
        'Callback', {@addRoi, 'myo'});
    
        uicontrol('Style', 'pushbutton',...
        'Units',  'normalized',...
        'Position', [0.25 0.05 0.1 0.1],...
        'String', '+vg',...
        'Callback', {@addRoi, 'vg'});
    
        uicontrol('Style', 'pushbutton',...
        'Units',  'normalized',...
        'Position', [0.5 0.05 0.1 0.1],...
        'String', '+vd',...
        'Callback', {@addRoi, 'vd'});
    %OK button
    uicontrol('Style', 'pushbutton',...
        'Units',  'normalized',...
        'Position', [0.75 0.05 0.1 0.1],...
        'String', 'OK',...
        'Callback', @closeFig);
    
%     %colormap button
%     cmBnHdle = uicontrol('Style', 'checkbox',...
%         'Units',  'normalized', 'Position', [0.25 0.05 0.2 0.1], ...
%         'String',   'colormap', 'Value',    0, 'Callback', @setColormap);
    
    waitfor(figHdle);
    
    
    %% Callback function
    function rect = addRoi(~,~, roiName)
        axes(ha(1));
             rect = getrect();
        switch roiName
            case 'myo'
                rectMyo = rect;
                focusedRoi = 'myo';
            case 'vd'
                rectVD = rect;
                focusedRoi = 'vd';
            case 'vg'
                rectVG = rect;
                focusedRoi = 'vg';
        end
        dispFocusedROI();
        %axes(ha(1));
%         imagesc(correctImage(slcSerie(:, :, slcPos))); axis off image;
    end

    function dispRectangles()
        axes(ha(2));
        imagesc(correctImage(slcSerie(:, :, slcPos)));axis off image;
        try
            rectangle('Position', rectMyo, 'EdgeColor', 'b');
        catch
            cprintf('orange', 'no rectangle for myo yet\n');
        end
        try
            rectangle('Position', rectVD, 'EdgeColor', 'g');
        catch
            cprintf('orange', 'no rectangle for VD yet\n');
        end
        try
            rectangle('Position', rectVG,'EdgeColor', 'r');
        catch
            cprintf('orange', 'no rectangle for VG yet\n');
        end
    end%dispRectangles

    function dispFocusedROI()
        axes(ha(1));
        imagesc(correctImage(slcSerie(:, :, slcPos)));axis off image;
        switch focusedRoi
            case 'myo'
                rectangle('Position', rectMyo, 'EdgeColor', 'b');
            case 'vd'
                rectangle('Position', rectVD, 'EdgeColor', 'g');
            case 'vg'
                rectangle('Position', rectVG, 'EdgeColor', 'r');
        end
    end%dispOneRectangle

    function OnScrollCb(~, arg)
        slcPos = floor(slcPos + arg.VerticalScrollCount);
        if slcPos < 1
            slcPos = 1;
        end
        if slcPos > size(slcSerie, 3)
            slcPos = size(slcSerie, 3);
        end
        xlim = get(ha(1), 'XLim');
        ylim = get(ha(1), 'YLim');
        axes(ha(1));
        imagesc(correctImage(slcSerie(:, :, slcPos))); axis off; axis image;
        dispSlicePos();
        set(ha(1), 'XLim', xlim);
        set(ha(1), 'YLim', ylim);
        %title (get(editInputDcm, 'String'));
    end

     function onKeyPressCb(~, arg)
         switch arg.Key
             case 'uparrow'
                 imgOpt.brightness = imgOpt.brightness + 1;
             case 'downarrow'
                 imgOpt.brightness = imgOpt.brightness - 1;
             case 'leftarrow'
                 imgOpt.contrast = imgOpt.contrast - 0.2;
             case 'rightarrow'
                 imgOpt.contrast = imgOpt.contrast + 0.2;
             case 'pageup'
                 imgOpt.angle = imgOpt.angle + 1;
             case 'pagedown'
                 imgOpt.angle = imgOpt.angle - 1;
             case 'return'
                 dispRectangles();
         end%switch
         axes(ha(1));
         imagesc(correctImage(slcSerie(:, :, slcPos))); axis off; axis image;
         dispSlicePos();
     end%onKeyPressCb
 
    function corrIm = correctImage(image)
        maxValue = max(image(:));
        lut(1, :) = (0 : maxValue);
        tmp = imgOpt.contrast .*  lut(1, :) + imgOpt.brightness;
        tmp(tmp < 0) = 0; tmp(tmp > maxValue) = maxValue;
        lut(2, :) = tmp;
        
        for k = 1 : numel(image)
            corrIm(k) = lut(2, lut(1,:) == floor(image(k)));
        end
        corrIm = reshape(corrIm, size(image));
        corrIm = imrotate(corrIm, imgOpt.angle);
    end%correctImage

    function closeFig(~, ~)
        close(figHdle);
    end%closeFig

     function dispSlicePos()
         txtPos = [0.85, 0.05];
         text('units','normalized','position', txtPos,'fontsize', 10, 'color', 'white', 'string', sprintf('%d/%d', slcPos, size(slcSerie, 3)))
     end%dispSlicePos
 
    function matrix = rotz(angle)
        rotMat = []
    end

end%manualSegmentation