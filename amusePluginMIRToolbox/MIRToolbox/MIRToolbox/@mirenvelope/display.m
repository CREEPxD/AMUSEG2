function display(d,axis,tracks)
% MIRDATA/DISPLAY display of a MIRenvelope

ST = dbstack;
if strcmp(ST(end).file,'arrayviewfunc.m')
    disp('To display its content in a figure, evaluate this variable directly in the Command Window.');
    return
end


if nargin<2
    axis = [];
end

if nargin<3
    tracks = [];
end


if d.hwr
    d = set(d,'Title',[get(d,'Title'),' (half-wave rectified)']);
end
mirdisplay(mirtemporal(d),inputname(1),axis,tracks);