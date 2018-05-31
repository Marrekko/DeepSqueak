function esportspect_Callback(hObject, eventdata, handles)
% Plotting Defferntial Expression
spectname=['Call_' num2str(handles.currentcall) '.png'];
[FileName,PathName] = uiputfile(spectname,'Save Spectrogram');

I = get(handles.spect,'CData');
Ydata = get(handles.spect,'Ydata');
Ylim = get(handles.axes1,'Ylim');

% Set limits
Ymax = find(Ydata>Ylim(2),1);
Ymin = find(Ydata>Ylim(1),1);
I = flipud(I(Ymin:Ymax,:));

Clim = get(handles.axes1,'Clim');
I = mat2gray(I,Clim);
fullFileName = fullfile(PathName, FileName); % Add Figure Path
cmap = feval(handles.cmapname{1},256);
I2 = gray2ind(I,256);
imwrite(I2,cmap,fullFileName,'png','BitDepth',8); % Re-change it to colored one 

guidata(hObject, handles);