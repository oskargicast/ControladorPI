clear all; close all; clc
%% Programa para calcular el controlador
% -------------------------------------------------------------------------
%% Cargando la DATA
% -------------------------------------------------------------------------
dataLeida = load('../data/data_rc.lvm');
T=1/30; % Tiempo de Muestreo 
y1=dataLeida(:,4);
u1=dataLeida(:,6);

figure
subplot(211)
plot(y1,'b','LineWidth',2); 
xlabel('\bf t(seg)'); ylabel('\bf y(volts)');
subplot(212)
plot(u1,'r','LineWidth',2); 
xlabel('\bf t(seg)'); ylabel('\bf u(volts)');

% -------------------------------------------------------------------------
%% Identificaci�n ARX
% -------------------------------------------------------------------------
data=iddata(y1,u1,T);
th=arx(data,[1 1 1]);
present(th)
thc=d2c(th);
[num,den]=tfdata(thc);
Gp=tf(num,den)
gain = num{1}(2);
tau = 1/num{1}(2);

% -------------------------------------------------------------------------
%% Polos de la planta 
% -------------------------------------------------------------------------
sp=pole(Gp);
ip=abs(imag(sp));
rp=abs(real(sp));

% -------------------------------------------------------------------------
%% Especificaciones de dise�o polos deseados
% -------------------------------------------------------------------------
ts=1;
Mp=0.1;
zeta=-log(Mp)/sqrt((log(Mp))^2+pi^2);
wn=4.6/(zeta*ts);
s1=-zeta*wn+1j*wn*sqrt(1-zeta^2);
% Polo deseado
sd=s1;
id=abs(imag(sd));
rd=abs(real(sd));

% -------------------------------------------------------------------------
%% Dise�o del control PI continuo
% -------------------------------------------------------------------------
theta1=pi-atan(id/rd); 
theta2=atan((id-ip)/(rp-rd)); 
theta3=theta1+theta2+pi;   % condici�n de fase
theta3 = pi_to_pi(theta3); 

if abs(theta3)<pi/2
    zc = rd+id/tan(theta3);
else
    zc = rd-id/tan(theta3);
end
a = zc; % zero del controlador
% polo del controlador
sc = 0;

r1 = sd-sc; %polo
r2 = sd-sp; %polo
r3 = sd-zc; %zero

K = abs(r1)*abs(r2)/(gain*abs(r3));

% -------------------------------------------------------------------------
%% Simulaci�n del Controlador PI continuo
% -------------------------------------------------------------------------
Gc=tf(K*[1 a],[1 0])
% Funcion de transferencia en lazo cerrado H 
L=series(Gc,Gp);
H=L/(L+1)

figure; hold on;
t = 0:0.001:5;

u=ones(size(t));
yp=lsim(H,u,t);

plot(t,u,'r')
plot(t,yp, 'b', 'LineWidth',2)

xlabel('\bf t(seg)'); ylabel('\bf y(volts)');
legend('set point', 'y_{lazo cerrado}');

% -------------------------------------------------------------------------
%% Re-dise�o por tustin del Control en Tiempo Discreto
% -------------------------------------------------------------------------
T=tau/5;
[Nt,Dt] = tfdata(Gc,'v');
Nt = poly2sym(Nt,'s');
Dt = poly2sym(Dt,'s');
syms z
Gdt = Nt/Dt;
Gdt = subs(Gdt,{'s'},(2*(z-1))/(T*(z+1)));
Gdt = simplify(Gdt);
Gdt = vpa(Gdt,4); 
[NDt, DDt] = numden(Gdt);
NDt = sym2poly(NDt);
DDt = sym2poly(DDt);

% -------------------------------------------------------------------------
%% FT del Controlador digital D(z)
% -------------------------------------------------------------------------
GDt = tf(NDt,DDt,T)

% -------------------------------------------------------------------------
%% Coeficientes para lectura de LabVIEW
% -------------------------------------------------------------------------
[Np,Dp]=tfdata(Gp,'v');
planta = [Np Dp]; 
save '../data/coef_planta.lvm' planta -ascii -tabs
save '../data/num_controller.lvm' NDt -ascii -tabs
save '../data/den_controller.lvm' DDt -ascii -tabs