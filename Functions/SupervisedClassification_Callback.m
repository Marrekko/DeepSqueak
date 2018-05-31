function SupervisedClassification_Callback(hObject, eventdata, handles)

% This function uses a convolutional neural network, trained in
% "TrainSupervisedClassifier_Callback.m", to classify USVs.

[FileName,PathName] = uigetfile([handles.squeakfolder '\Clustering Models\*.mat'],'Select Network');
load([PathName FileName],'ClassifyNet','wind','noverlap','nfft','lowFreq','highFreq','imageSize');

if exist('ClassifyNet') ~= 1
    errordlg('Network not be found. Is this file a trained CNN?')
    return
end



if exist(handles.settings.detectionfolder,'dir')==0
    errordlg('Please Select Detection Folder')
    uiwait
    load_detectionFolder_Callback(hObject, eventdata, handles)
    handles = guidata(hObject);  % Get newest version of handles
end

selections = listdlg('PromptString','Select Files for Classification:','ListSize',[500 300],'ListString',handles.detectionfilesnames);
if isempty(selections)
    return
end



h = waitbar(0,'Initializing');

for j = 1:length(selections) % Do this for each file
    currentfile = selections(j);
    lastwarn(''); % Skip files if variable: 'Calls' doesn't exist
    tmp=load([handles.detectionfiles(currentfile).folder '\' handles.detectionfiles(currentfile).name],'Calls');
    if ~isempty(lastwarn)
        disp([handles.detectionfiles(currentfile).name ' is not a Call file, skipping...'])
        continue
    end
    Calls = tmp.Calls;
    for i = 1:length(Calls)   % For Each Call
        waitbar(((i/length(Calls)) + j - 1) / length(selections), h, ['Classifying file ' num2str(j) ' of ' num2str(length(selections))]);
        
        if Calls(i).Accept == 1;
            
            audio =  Calls(i).Audio;
            if ~isa(audio,'double')
                audio = double(audio) / (double(intmax(class(audio)))+1);
            end
            
            [s, fr, ti] = spectrogram(audio,round(Calls(i).Rate * wind),round(Calls(i).Rate * noverlap),round(Calls(i).Rate * nfft),Calls(i).Rate,'yaxis');
            x1 = axes2pix(length(ti),ti,Calls(i).RelBox(1));
            x2 = axes2pix(length(ti),ti,Calls(i).RelBox(3)) + x1;
%                 y1 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(2));
%                 y2 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(4)) + y1;
            y1 = axes2pix(length(fr),fr./1000,lowFreq);
            y2 = axes2pix(length(fr),fr./1000,highFreq);
            I=abs(s(round(y1:y2),round(x1:x2))); % Get the pixels in the box
            im = mat2gray(flipud(I),[prctile(abs(s(:)),7.5) prctile(abs(s(:)),99.8)]); % Set max brightness to 1/4 of max
            
            X = imresize(im,imageSize);
            [Class,score] = classify(ClassifyNet,X);
            Calls(i).Score = score(1);
            Calls(i).Type = Class;
        end
    end
    save([handles.detectionfiles(currentfile).folder '\' handles.detectionfiles(currentfile).name],'Calls','-v7.3');
end

%% Update display
if isfield(handles,'current_detection_file')
    
    tmp=load([handles.detectionfiles(handles.v_call).folder '\' handles.detectionfiles(handles.v_call).name]);%get currently selected option from menu
    handles.calls=tmp.Calls;
    handles.currentcall=1;
    handles.CallTime=[];
    
    handles.spect = imagesc([],[],handles.background,'Parent', handles.axes1);
    cb=colorbar(handles.axes1);
    cb.Label.String = 'Power';
    cb.Color = [1 1 1];
    cb.FontSize = 12;
    ylabel(handles.axes1,'Frequency (kHZ)','Color','w');
    xlabel(handles.axes1,'Time (s)','Color','w');
    handles.box=rectangle('Position',[1 1 1 1],'Curvature',0.2,'EdgeColor','g',...
        'LineWidth',3,'Parent', handles.axes1);
    
    for i=1:length([handles.calls(:).Rate])
        waitbar(i/length(handles.calls),h,'Loading Calls Please wait...');
        handles.CallTime(i,1)=handles.calls(i).Box(1);
    end
    update_fig(hObject, eventdata, handles);
end

close(h)
guidata(hObject, handles);
end