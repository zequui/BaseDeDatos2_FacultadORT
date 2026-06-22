CREATE OR REPLACE PROCEDURE 2.1-crearAgente (
  agenteId IN NUMBER,
  agenteNombre IN VARCHAR2,
  agenteFechaCreacion IN DATE,
  agenteDescripcion IN VARCHAR2,
  agenteActivo IN VARCHAR2,
  agenteTipo IN VARCHAR2,
  agenteId_usuario IN VARCHAR2,

  configuracionDescripcion VARCHAR2,
  configuracionConfiguracion VARCHAR2,

  p2  OUT    NUMBER,   -- solo escritura
  p3  IN OUT NUMBER    -- lectura y escritura
) AS
  vLocal NUMBER;
BEGIN
  INSERT INTO AGENTE (id, nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
  VALUES (agenteId, agenteNombre, agenteFechaCreacion, agenteDescripcion, agenteActivo, agenteTipo, agenteId_usuario);
  
  INSEERT INTO CONFIGURACION (id, descripcion, configuracion)
  VALUES (agenteId, configuracionDescripcion, configuracionConfiguracion);
  
  EXCEPTION
  WHEN miExcepcion THEN
    RAISE_APPLICATION_ERROR(-20001, 'msg');
END;