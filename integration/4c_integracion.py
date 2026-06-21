import oracledb
import pymongo
import datetime
import random

# ------------------------------------------------------------
# CONFIGURACIÓN DE CONEXIONES
# ------------------------------------------------------------
ORACLE_DSN  = "localhost:1521/XE"   # Ajustar si el service_name es distinto
ORACLE_USER = "moltbook"
ORACLE_PASS = "moltbook"

MONGO_URI = "mongodb://localhost:27017"
MONGO_DB = "moltbook_analytics"
MONGO_COLL = "eventos"

# ------------------------------------------------------------
# CONEXIÓN A ORACLE
# ------------------------------------------------------------
oracle_conn = oracledb.connect(user=ORACLE_USER, password=ORACLE_PASS, dsn=ORACLE_DSN)
cursor = oracle_conn.cursor()

# ------------------------------------------------------------
# CONEXIÓN A MONGODB
# ------------------------------------------------------------
mongo_client = pymongo.MongoClient(MONGO_URI)
db = mongo_client[MONGO_DB]
eventos = db[MONGO_COLL]

# Eliminar colección si existe (para pruebas) y crear con validador
eventos.drop()
db.create_collection(
    "eventos",
    validator={
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["agente_id", "nombre_agente", "tipo_evento", "criticidad", "fecha", "detalle"],
            "properties": {
                "agente_id": {"bsonType": "int"},
                "nombre_agente": {"bsonType": "string"},
                "tipo_evento": {
                    "enum": [
                        "decision",
                        "interaccion_usuario",
                        "accion",
                        "metrica_ejecucion",
                        "anomalia",
                        "creacion_publicacion",
                        "creacion_comentario",
                        "voto"
                    ]
                },
                "criticidad": {"enum": ["alta", "media", "baja"]},
                "fecha": {"bsonType": "date"},
                "id_comunidad": {"bsonType": ["int", "null"]},
                "detalle": {
                    "bsonType": "object",
                    "additionalProperties": True  # permite estructura variable
                }
            }
        }
    }
)

# ------------------------------------------------------------
# FUNCIONES AUXILIARES PARA GENERAR EVENTOS
# ------------------------------------------------------------
def get_agente_info(agente_id):
    cursor.execute("""
        SELECT a.id, a.nombre, a.tipo, u.mail, u.activo
        FROM AGENTE a JOIN USUARIO u ON a.id_usuario = u.mail
        WHERE a.id = :id
    """, id=agente_id)
    row = cursor.fetchone()
    if row:
        return {
            "id": row[0],
            "nombre": row[1],
            "tipo": row[2],
            "usuario_mail": row[3],
            "usuario_activo": row[4]
        }
    return None

# tipo_evento: "creacion_publicacion"
def generar_evento_publicacion(agente_id, nombre_agente, contenido_id, titulo, comunidad_id, fecha):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "creacion_publicacion",
        "criticidad": "baja",
        "fecha": fecha,
        "id_comunidad": int(comunidad_id) if comunidad_id else None,
        "detalle": {
            "id_publicacion": int(contenido_id),
            "titulo": titulo
        }
    }

# tipo_evento: "creacion_comentario"
def generar_evento_comentario(agente_id, nombre_agente, contenido_id, comunidad_id, fecha):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "creacion_comentario",
        "criticidad": "baja",
        "fecha": fecha,
        "id_comunidad": int(comunidad_id) if comunidad_id else None,
        "detalle": {
            "id_comentario": int(contenido_id)
        }
    }

# tipo_evento: "voto"
def generar_evento_voto(agente_id, nombre_agente, pub_id, fecha, positivo):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "voto",
        "criticidad": "baja",
        "fecha": fecha,
        "id_comunidad": None,
        "detalle": {
            "id_publicacion": int(pub_id),
            "positivo": bool(positivo)
        }
    }

# tipo_evento: "accion" — solo para moderaciones
def generar_evento_accion(agente_id, nombre_agente, tipo_accion, contenido_id, comunidad_id, fecha, criticidad="media"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "accion",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": int(comunidad_id) if comunidad_id else None,
        "detalle": {
            "tipo_accion": tipo_accion,
            "id_contenido": int(contenido_id)
        }
    }

def generar_evento_decision(agente_id, nombre_agente, comunidad_id, fecha, contexto, params, alternativas, elegida, criticidad="baja"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "decision",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": int(comunidad_id) if comunidad_id else None,
        "detalle": {
            "contexto_operacional": contexto,
            "parametros_entrada": params,
            "alternativas_evaluadas": alternativas,
            "alternativa_elegida": elegida
        }
    }

def generar_evento_metrica(agente_id, nombre_agente, fecha, tiempo_ms, tokens, criticidad="baja"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "metrica_ejecucion",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": None,
        "detalle": {
            "tiempo_respuesta_ms": tiempo_ms,
            "tokens_procesados": tokens
        }
    }

def generar_evento_anomalia(agente_id, nombre_agente, fecha, patron, descripcion, criticidad="alta"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "anomalia",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": None,
        "detalle": {
            "patron_detectado": patron,
            "descripcion": descripcion
        }
    }

def generar_evento_interaccion(agente_id, nombre_agente, fecha, usuario_mail, canal, criticidad="media"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "interaccion_usuario",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": None,
        "detalle": {
            "id_usuario": usuario_mail,
            "canal": canal
        }
    }

# ------------------------------------------------------------
# 1. EVENTOS DE ACCIÓN (publicaciones, comentarios, votos, moderaciones)
# ------------------------------------------------------------
print("Generando eventos de acción...")

# Publicaciones
cursor.execute("""
    SELECT c.id, c.id_agente, c.id_comunidad, p.titulo, c.fechaCreacion, c.horaCreacion
    FROM CONTENIDO c JOIN PUBLICACION p ON c.id = p.id
""")
for row in cursor:
    contenido_id, agente_id, comunidad_id, titulo, fecha_creacion, hora_creacion = row
    fecha = datetime.datetime.combine(fecha_creacion, datetime.datetime.strptime(hora_creacion, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        evento = generar_evento_publicacion(
            agente_id, info["nombre"], contenido_id, titulo, comunidad_id, fecha
        )
        eventos.insert_one(evento)

# Comentarios
cursor.execute("""
    SELECT c.id, c.id_agente, c.id_comunidad, co.contenido, c.fechaCreacion, c.horaCreacion
    FROM CONTENIDO c JOIN COMENTARIO co ON c.id = co.id
""")
for row in cursor:
    contenido_id, agente_id, comunidad_id, contenido, fecha_creacion, hora_creacion = row
    fecha = datetime.datetime.combine(fecha_creacion, datetime.datetime.strptime(hora_creacion, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        evento = generar_evento_comentario(
            agente_id, info["nombre"], contenido_id, comunidad_id, fecha
        )
        eventos.insert_one(evento)

# Votos
cursor.execute("""
    SELECT id_agente, id_publicacion, fecha, hora, positivo
    FROM VOTA
""")
for row in cursor:
    agente_id, pub_id, fecha_voto, hora_voto, positivo = row
    fecha = datetime.datetime.combine(fecha_voto, datetime.datetime.strptime(hora_voto, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        evento = generar_evento_voto(
            agente_id, info["nombre"], pub_id, fecha, positivo
        )
        eventos.insert_one(evento)

# Moderaciones (INTERVIENE)
cursor.execute("""
    SELECT id_agente, id_contenido, id_comunidad, tipo, fecha, hora
    FROM INTERVIENE
""")
for row in cursor:
    agente_id, contenido_id, comunidad_id, tipo_mod, fecha_mod, hora_mod = row
    fecha = datetime.datetime.combine(fecha_mod, datetime.datetime.strptime(hora_mod, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        evento = generar_evento_accion(
            agente_id, info["nombre"], "moderacion",
            contenido_id, comunidad_id, fecha, criticidad="alta"
        )
        eventos.insert_one(evento)

# ------------------------------------------------------------
# 2. EVENTOS DE DECISIÓN (para cada publicación y comentario)
#    Simulamos que el agente tomó una decisión previa.
# ------------------------------------------------------------
print("Generando eventos de decisión...")

# Para publicaciones
cursor.execute("""
    SELECT c.id, c.id_agente, c.id_comunidad, p.titulo, c.fechaCreacion, c.horaCreacion
    FROM CONTENIDO c JOIN PUBLICACION p ON c.id = p.id
""")
for row in cursor:
    contenido_id, agente_id, comunidad_id, titulo, fecha_creacion, hora_creacion = row
    fecha = datetime.datetime.combine(fecha_creacion, datetime.datetime.strptime(hora_creacion, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        evento = generar_evento_decision(
            agente_id, info["nombre"], comunidad_id, fecha,
            contexto="seleccion_contenido_publicacion",
            params={"titulo": titulo, "comunidad": int(comunidad_id) if comunidad_id else None},
            alternativas=["publicar", "descartar", "modificar"],
            elegida="publicar",
            criticidad="baja"
        )
        eventos.insert_one(evento)

# Para comentarios
cursor.execute("""
    SELECT c.id, c.id_agente, c.id_comunidad, co.contenido, c.fechaCreacion, c.horaCreacion
    FROM CONTENIDO c JOIN COMENTARIO co ON c.id = co.id
""")
for row in cursor:
    contenido_id, agente_id, comunidad_id, contenido, fecha_creacion, hora_creacion = row
    fecha = datetime.datetime.combine(fecha_creacion, datetime.datetime.strptime(hora_creacion, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        evento = generar_evento_decision(
            agente_id, info["nombre"], comunidad_id, fecha,
            contexto="generacion_respuesta",
            params={"contenido": contenido[:100]},
            alternativas=["responder", "ignorar", "derivar"],
            elegida="responder",
            criticidad="baja"
        )
        eventos.insert_one(evento)

# ------------------------------------------------------------
# 3. EVENTOS DE MÉTRICA DE EJECUCIÓN (simulados)
#    Se genera una métrica por cada acción registrada.
# ------------------------------------------------------------
print("Generando eventos de métrica...")

# Para todas las acciones (usamos los mismos datos de las tablas de contenido + votos + moderaciones)
# Simulamos tiempos y tokens aleatorios.
cursor.execute("""
    SELECT id, id_agente, fechaCreacion, horaCreacion FROM CONTENIDO
""")
for row in cursor:
    contenido_id, agente_id, fecha_creacion, hora_creacion = row
    fecha = datetime.datetime.combine(fecha_creacion, datetime.datetime.strptime(hora_creacion, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        evento = generar_evento_metrica(
            agente_id, info["nombre"], fecha,
            tiempo_ms=random.randint(50, 2000),
            tokens=random.randint(100, 5000),
            criticidad="baja"
        )
        eventos.insert_one(evento)

# También para votos (sin contenido asociado a la tabla CONTENIDO)
cursor.execute("""
    SELECT id_agente, fecha, hora FROM VOTA
""")
for row in cursor:
    agente_id, fecha_voto, hora_voto = row
    fecha = datetime.datetime.combine(fecha_voto, datetime.datetime.strptime(hora_voto, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        evento = generar_evento_metrica(
            agente_id, info["nombre"], fecha,
            tiempo_ms=random.randint(10, 500),
            tokens=random.randint(10, 200),
            criticidad="baja"
        )
        eventos.insert_one(evento)

# ------------------------------------------------------------
# 4. EVENTOS DE ANOMALÍA (detección de patrones)
#    Ejemplo: agentes con muchos votos en poco tiempo
# ------------------------------------------------------------
print("Generando eventos de anomalía...")

# Contamos votos por agente y día
cursor.execute("""
    SELECT id_agente, TRUNC(fecha) as dia, COUNT(*) as cantidad
    FROM VOTA
    GROUP BY id_agente, TRUNC(fecha)
    HAVING COUNT(*) >= 3
""")
for row in cursor:
    agente_id, dia, cantidad = row
    info = get_agente_info(agente_id)
    if info:
        # Convertir DATE de Oracle a datetime para cumplir bsonType: "date"
        fecha = datetime.datetime.combine(dia, datetime.time(0, 0, 0))
        evento = generar_evento_anomalia(
            agente_id, info["nombre"], fecha,
            patron="alta_frecuencia_votos",
            descripcion=f"El agente emitió {cantidad} votos en un solo día",
            criticidad="media"
        )
        eventos.insert_one(evento)

# Otra anomalía: agentes que han sido suspendidos (según USUARIO.activo)
cursor.execute("""
    SELECT a.id, u.activo
    FROM AGENTE a JOIN USUARIO u ON a.id_usuario = u.mail
    WHERE u.activo = 'Suspendido'
""")
for row in cursor:
    agente_id, activo = row
    info = get_agente_info(agente_id)
    if info:
        fecha = datetime.datetime.now()
        evento = generar_evento_anomalia(
            agente_id, info["nombre"], fecha,
            patron="usuario_suspendido",
            descripcion="El usuario administrador del agente está suspendido",
            criticidad="alta"
        )
        eventos.insert_one(evento)

# ------------------------------------------------------------
# 5. EVENTOS DE INTERACCIÓN USUARIO (reclamos de administración)
#    Cada reclamo (RECLAMA) se considera una interacción.
# ------------------------------------------------------------
print("Generando eventos de interacción usuario...")

cursor.execute("""
    SELECT id_usuario, id_agente, fechaReclamo, fechaAceptacion
    FROM RECLAMA
""")
for row in cursor:
    id_usuario, agente_id, fecha_reclamo, fecha_aceptacion = row
    info = get_agente_info(agente_id)
    if info:
        # Evento de solicitud de transferencia
        evento = generar_evento_interaccion(
            agente_id, info["nombre"], fecha_reclamo,
            usuario_mail=id_usuario,
            canal="solicitud_transferencia",
            criticidad="media"
        )
        eventos.insert_one(evento)
        # Si fue aceptada, otro evento
        if fecha_aceptacion:
            evento2 = generar_evento_interaccion(
                agente_id, info["nombre"], fecha_aceptacion,
                usuario_mail=id_usuario,
                canal="transferencia_aceptada",
                criticidad="media"
            )
            eventos.insert_one(evento2)

# ------------------------------------------------------------
# CIERRE DE CONEXIONES
# ------------------------------------------------------------
cursor.close()
oracle_conn.close()
mongo_client.close()

print("¡Integración completada!")