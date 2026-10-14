% PROYECTO: Sistema Inteligente de Gestión Energética (SIGE)
% RETO 3: Algoritmo de control y cargas
% Curso: Software para Ingeniería 
% Simular durante 24 horas el balance energético de una microred,
% controlar el estado de carga de una batería y desconectar cargas
% estudiante: John Ortega

clear;
clc;
close all;
%% 1. CONFIGURACION INICIAL

% Definir las 24 horas de simulacion.
horas = 1:24;
numero_horas = 24;

% Definir la capacidad total de la bateria en kWh.
capacidad_bateria = 100;

% Establecer el estado de carga inicial de la bateria.
SOC_inicial = 50;
SOC = SOC_inicial;

% Definir los limites de seguridad de la bateria.
SOC_minimo = 0;
SOC_maximo = 100;

% Crear vectores para almacenar los resultados de cada hora.
SOC_historico = zeros(1, numero_horas);
balance_historico = zeros(1, numero_horas);
excedente_historico = zeros(1, numero_horas);
faltante_historico = zeros(1, numero_horas);

% Definir el estado de los servicios.
escuela = true;
bombeo = true;
alumbrado = true;

% Crear vectores para registrar el estado de cada servicio.
estado_escuela = false(1, numero_horas);
estado_bombeo = false(1, numero_horas);
estado_alumbrado = false(1, numero_horas);

%% 2. GENERACION SOLAR
% Se conserva el modelo utilizado en el Reto 2.

P_max_solar = 25;             % Potencia solar maxima en kW.
generacion_solar = zeros(1, 24);
horas_dia = 6:18;

% Modelar el aumento y la disminucion de la generacion solar.
generacion_solar(horas_dia) = P_max_solar * ...
    sin(pi * (horas_dia - 6) / 12);

% Garantizar que no exista generacion solar durante la noche.
generacion_solar([1:5, 19:24]) = 0;

%% 3. GENERACION EOLICA
% Se conserva la semilla y el modelo del Reto 2.

P_max_eolica = 15;             % Potencia eolica maxima en kW.

% Garantizar que la simulacion aleatoria sea reproducible.
rng(7);

% Modelar la tendencia de la generacion eolica.
tendencia_viento = 7 + 4 * ...
    sin(2 * pi * horas / 9 + 1.5);

% Simular las rafagas de viento.
rafagas = 3 * randn(1, 24);

% Calcular la generacion eolica total.
generacion_eolica = tendencia_viento + rafagas;

% Restringir la generacion eolica a sus limites de diseno.
generacion_eolica = max(generacion_eolica, 0);
generacion_eolica = min(generacion_eolica, P_max_eolica);

%% 4. DEMANDA DE LA COMUNIDAD
% Se conservan los rangos y el perfil del Reto 2.

demanda = zeros(1, 24);

% Demanda nocturna de las horas 1 a 5 y 22 a 24.
horas_min = [1:5, 22:24];
demanda(horas_min) = 2 + (4 - 2) * ...
    rand(1, length(horas_min));

% Demanda diurna de las horas 6 a 17.
horas_diurnas = 6:17;
demanda(horas_diurnas) = 6 + (10 - 6) * ...
    rand(1, length(horas_diurnas));

% Demanda elevada de las horas 18 a 21.
horas_pico = 18:21;
perfil_pico = [12, 15, 15, 13];
demanda(horas_pico) = perfil_pico;


%% 5. CALCULO DE LA GENERACION HIBRIDA

% Sumar la generacion solar y la generacion eolica.
generacion_total = generacion_solar + generacion_eolica;

%% 6. SIMULACION DEL CONTROL DURANTE 24 HORAS

% Mostrar el encabezado del reporte.
fprintf('\n============================================================\n');
fprintf('       REPORTE DEL CONTROL ENERGETICO SIGE - RETO 3\n');
fprintf('============================================================\n');
fprintf('Capacidad de bateria: %.2f kWh\n', capacidad_bateria);
fprintf('SOC inicial: %.2f %%\n\n', SOC_inicial);

% Recorrer las 24 horas de la simulacion.
for h = 1:numero_horas

    % Leer la generacion y la demanda de la hora actual.
    Egen = generacion_total(h);
    Edem = demanda(h);

    % Calcular el balance energetico.
    % Cada intervalo representa una hora.
    % Por ello, kW durante una hora equivale numericamente a kWh.
    balance = Egen - Edem;

    % Reiniciar los registros de excedente y faltante.
    excedente = 0;
    faltante = 0;

    % ------------------------------------------------------------
    % 6.1. DECISION SEGUN EL BALANCE ENERGETICO
    % ------------------------------------------------------------

    if balance >= 0

        % CASO 1: SUPERAVIT ENERGETICO.
        % La generacion cubre la demanda y sobra energia.

        excedente = balance;

        % Almacenar el excedente en la bateria.
        SOC = SOC + (excedente / capacidad_bateria) * 100;

        % Impedir que la bateria supere el 100 %.
        SOC = min(SOC, SOC_maximo);

        % Durante el superavit, todos los servicios permanecen activos.
        escuela = true;
        bombeo = true;
        alumbrado = true;

        situacion = 'SUPERAVIT';

    else

        % CASO 2: DEFICIT ENERGETICO.
        % La demanda supera la generacion disponible.

        faltante = abs(balance);

        % Descontar de la bateria la energia faltante.
        SOC = SOC - (faltante / capacidad_bateria) * 100;

        % Impedir que el SOC sea inferior al 0 %.
        SOC = max(SOC, SOC_minimo);

        situacion = 'DEFICIT';

        % --------------------------------------------------------
        % 6.2. CONTROL DE PRIORIDAD DE LAS CARGAS
        % --------------------------------------------------------

        if SOC >= 40

            % RUTA SEGURA:
            % Todos los servicios permanecen activos.
            escuela = true;
            bombeo = true;
            alumbrado = true;

        elseif SOC >= 20

            % RUTA DE ALERTA:
            % Desconectar el alumbrado publico.
            % Mantener la escuela y el bombeo activos.
            escuela = true;
            bombeo = true;
            alumbrado = false;

        else

            % RUTA DE EMERGENCIA:
            % Desconectar alumbrado y bombeo agricola.
            % La escuela conserva prioridad critica.
            escuela = true;
            bombeo = false;
            alumbrado = false;

        end
    end

    % ------------------------------------------------------------
    % 6.3. REGISTRAR LOS RESULTADOS DE LA HORA
    % ------------------------------------------------------------

    SOC_historico(h) = SOC;
    balance_historico(h) = balance;
    excedente_historico(h) = excedente;
    faltante_historico(h) = faltante;

    estado_escuela(h) = escuela;
    estado_bombeo(h) = bombeo;
    estado_alumbrado(h) = alumbrado;

    % ------------------------------------------------------------
    % 6.4. IMPRIMIR EL REPORTE EN LA CONSOLA
    % ------------------------------------------------------------

    fprintf('HORA %02d | %s\n', h, situacion);
    fprintf('Generacion total: %.2f kW\n', Egen);
    fprintf('Demanda total:    %.2f kW\n', Edem);
    fprintf('Balance:          %.2f kW\n', balance);
    fprintf('Excedente:        %.2f kWh\n', excedente);
    fprintf('Faltante:         %.2f kWh\n', faltante);
    fprintf('SOC actualizado:  %.2f %%\n', SOC);

    if escuela
        fprintf('Escuela rural: ACTIVA\n');
    else
        fprintf('Escuela rural: SUSPENDIDA\n');
    end

    if bombeo
        fprintf('Bombeo agricola: ACTIVO\n');
    else
        fprintf('Bombeo agricola: SUSPENDIDO\n');
    end

    if alumbrado
        fprintf('Alumbrado publico: ACTIVO\n');
    else
        fprintf('Alumbrado publico: SUSPENDIDO\n');
    end

    fprintf('------------------------------------------------------------\n');

end

%% 7. RESUMEN FINAL DE LA SIMULACION

fprintf('\n============================================================\n');
fprintf('                 RESUMEN FINAL DEL SIGE\n');
fprintf('============================================================\n');

fprintf('SOC inicial: %.2f %%\n', SOC_inicial);
fprintf('SOC final:   %.2f %%\n', SOC_historico(end));

fprintf('Horas con superavit: %d\n', sum(balance_historico >= 0));
fprintf('Horas con deficit:   %d\n', sum(balance_historico < 0));

fprintf('Horas con alumbrado suspendido: %d\n', ...
    sum(~estado_alumbrado));

fprintf('Horas con bombeo suspendido: %d\n', ...
    sum(~estado_bombeo));

fprintf('Horas con escuela activa: %d\n', ...
    sum(estado_escuela));

%% 8. GRAFICA DEL ESTADO DE CARGA DE LA BATERIA

figure('Name', 'Control de bateria SIGE - Reto 3', ...
    'NumberTitle', 'off');

plot(horas, SOC_historico, '-o', 'LineWidth', 2);

hold on;
yline(40, '--', 'Limite de alerta: 40 %');
yline(20, '--', 'Limite de emergencia: 20 %');
yline(100, ':', 'Carga maxima: 100 %');
yline(0, ':', 'Carga minima: 0 %');
hold off;

title('Estado de carga de la bateria durante 24 horas');
xlabel('Hora del dia');
ylabel('Estado de carga SOC (%)');

xticks(1:24);
xlim([1 24]);
ylim([0 105]);
grid on;

%% 9. GRAFICA DEL BALANCE ENERGETICO

figure('Name', 'Balance energetico SIGE - Reto 3', ...
    'NumberTitle', 'off');

bar(horas, balance_historico);

title('Balance energetico por hora');
xlabel('Hora del dia');
ylabel('Balance (kW)');

xticks(1:24);
xlim([0 25]);
yline(0, '-k');
grid on;

% Fin del programa.
fprintf('\nSimulacion de 24 horas finalizada.\n');
